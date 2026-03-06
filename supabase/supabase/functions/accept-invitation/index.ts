import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type AcceptInvitationPayload = {
  password?: string;
  tenant_id?: string;
};

type InvitationRow = {
  id: string;
  tenant_id: string;
  role: string;
  invited_by: string | null;
  status: string;
  invited_at: string | null;
  expires_at: string | null;
  invited_user_id: string | null;
};

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const uuidRegex =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json",
    },
  });
}

function getBearer(req: Request): string | null {
  const h = req.headers.get("authorization") || "";
  const m = /^Bearer\s+(.+)$/.exec(h);
  return m ? m[1] : null;
}

function parsePayload(input: AcceptInvitationPayload) {
  const password = typeof input.password === "string" ? input.password : "";
  const tenantIdRaw = typeof input.tenant_id === "string" ? input.tenant_id.trim() : "";

  if (!password) {
    return { ok: false as const, error: "password is required." };
  }
  if (tenantIdRaw && !uuidRegex.test(tenantIdRaw)) {
    return { ok: false as const, error: "tenant_id must be a valid UUID." };
  }

  return {
    ok: true as const,
    password,
    tenantId: tenantIdRaw || null,
  };
}

function isExpired(expiresAt: string | null, nowMs: number): boolean {
  if (!expiresAt) return false;
  const ts = Date.parse(expiresAt);
  if (Number.isNaN(ts)) return false;
  return ts <= nowMs;
}

function pickCurrentTenant(invites: InvitationRow[], explicitTenantId: string | null): string {
  if (explicitTenantId && invites.some((inv) => inv.tenant_id === explicitTenantId)) {
    return explicitTenantId;
  }
  const sorted = [...invites].sort((a, b) => {
    const aTs = a.invited_at ? Date.parse(a.invited_at) : 0;
    const bTs = b.invited_at ? Date.parse(b.invited_at) : 0;
    return bTs - aTs;
  });
  return sorted[0].tenant_id;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const token = getBearer(req);
  if (!token) return json({ error: "Missing Authorization header" }, 401);

  let body: AcceptInvitationPayload;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }

  const parsed = parsePayload(body);
  if (!parsed.ok) return json({ error: parsed.error }, 400);

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const admin = createClient(url, serviceKey);

  const { data: me, error: meErr } = await userClient.auth.getUser();
  if (meErr || !me?.user) return json({ error: "Invalid or expired token" }, 401);

  const callerUser = me.user;
  const callerUserId = callerUser.id;
  const callerEmail = (callerUser.email ?? "").trim().toLowerCase();
  if (!callerEmail) return json({ error: "Authenticated user email is required." }, 400);

  let inviteQuery = admin
    .from("tenant_invitations")
    .select("id, tenant_id, role, invited_by, status, invited_at, expires_at, invited_user_id")
    .ilike("email", callerEmail)
    .order("invited_at", { ascending: false });

  if (parsed.tenantId) {
    inviteQuery = inviteQuery.eq("tenant_id", parsed.tenantId);
  }

  const { data: inviteRowsRaw, error: inviteErr } = await inviteQuery;
  if (inviteErr) return json({ error: inviteErr.message }, 400);

  const inviteRows = (inviteRowsRaw ?? []) as InvitationRow[];
  const nowMs = Date.now();

  const expiredPendingIds = inviteRows
    .filter((row) => row.status === "invited" && isExpired(row.expires_at, nowMs))
    .map((row) => row.id);

  if (expiredPendingIds.length > 0) {
    const { error: expireErr } = await admin
      .from("tenant_invitations")
      .update({ status: "expired" })
      .in("id", expiredPendingIds)
      .eq("status", "invited");
    if (expireErr) return json({ error: expireErr.message }, 400);
  }

  const pendingInvites = inviteRows.filter((row) =>
    row.status === "invited" && !isExpired(row.expires_at, nowMs)
  );

  if (pendingInvites.length === 0) {
    const hasAcceptedInvite = inviteRows.some((row) => row.status === "accepted");
    const acceptedForRequestedTenant = parsed.tenantId
      ? inviteRows.some((row) => row.status === "accepted" && row.tenant_id === parsed.tenantId)
      : false;

    if (hasAcceptedInvite) {
      if (parsed.tenantId && !acceptedForRequestedTenant) {
        return json({ error: "Requested tenant does not match an accepted invitation." }, 409);
      }

      const currentTenantId = acceptedForRequestedTenant
        ? parsed.tenantId
        : inviteRows.find((row) => row.status === "accepted")?.tenant_id ?? null;
      return json({
        ok: true,
        user_id: callerUserId,
        email: callerEmail,
        accepted_count: 0,
        accepted_tenant_ids: [],
        current_tenant_id: currentTenantId,
        note: "Invitation already accepted. Call supabase.auth.refreshSession() if needed.",
      });
    }

    const hasRevokedOrExpiredInvite = inviteRows.some((row) =>
      row.status === "revoked" || row.status === "expired" || isExpired(row.expires_at, nowMs)
    );
    if (hasRevokedOrExpiredInvite) {
      return json({ error: "No active invitation found. Invite was revoked or expired." }, 409);
    }
    return json({ error: "No pending invitation found for this user." }, 404);
  }

  const { error: pwdErr } = await admin.auth.admin.updateUserById(callerUserId, {
    password: parsed.password,
  });
  if (pwdErr) {
    const status = typeof pwdErr.status === "number" && pwdErr.status >= 400 ? pwdErr.status : 400;
    return json({ error: pwdErr.message }, status);
  }

  const membershipRows = pendingInvites.map((row) => ({
    tenant_id: row.tenant_id,
    user_id: callerUserId,
    role: row.role,
    invited_by: row.invited_by ?? callerUserId,
  }));

  const { error: upsertErr } = await admin
    .from("tenant_members")
    .upsert(membershipRows, { onConflict: "tenant_id,user_id", ignoreDuplicates: true });
  if (upsertErr) return json({ error: upsertErr.message }, 400);

  const pendingIds = pendingInvites.map((row) => row.id);
  const acceptedAt = new Date().toISOString();
  const { error: acceptErr } = await admin
    .from("tenant_invitations")
    .update({
      status: "accepted",
      accepted_at: acceptedAt,
      invited_user_id: callerUserId,
    })
    .in("id", pendingIds)
    .eq("status", "invited");
  if (acceptErr) return json({ error: acceptErr.message }, 400);

  const currentTenantId = pickCurrentTenant(pendingInvites, parsed.tenantId);
  const { error: metaErr } = await admin.auth.admin.updateUserById(callerUserId, {
    app_metadata: { ...(callerUser.app_metadata ?? {}), tenant_id: currentTenantId },
  });
  if (metaErr) return json({ error: metaErr.message }, 400);

  const acceptedTenantIds = [...new Set(pendingInvites.map((row) => row.tenant_id))];

  return json({
    ok: true,
    user_id: callerUserId,
    email: callerEmail,
    accepted_count: pendingInvites.length,
    accepted_tenant_ids: acceptedTenantIds,
    current_tenant_id: currentTenantId,
    note: "Call supabase.auth.refreshSession() to refresh JWT tenant_id.",
  });
});
