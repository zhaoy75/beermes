import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type DbRole = "owner" | "admin" | "editor" | "viewer";
type ApiRole = "member" | "admin" | "editor" | "viewer";

type InviteMemberPayload = {
  tenant_id?: string;
  email?: string;
  role?: string;
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

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const apiToDbRole: Record<ApiRole, DbRole> = {
  member: "viewer",
  viewer: "viewer",
  editor: "editor",
  admin: "admin",
};

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

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function parsePayload(input: InviteMemberPayload) {
  const tenantId = String(input.tenant_id ?? "").trim();
  const email = normalizeEmail(String(input.email ?? ""));
  const roleRaw = String(input.role ?? "").trim().toLowerCase() as ApiRole;

  if (!tenantId || !uuidRegex.test(tenantId)) {
    return { ok: false as const, error: "tenant_id must be a valid UUID." };
  }
  if (!email || !emailRegex.test(email)) {
    return { ok: false as const, error: "email must be a valid email address." };
  }
  if (!(roleRaw in apiToDbRole)) {
    return { ok: false as const, error: "role must be one of: member, viewer, editor, admin." };
  }

  return {
    ok: true as const,
    tenantId,
    email,
    apiRole: roleRaw,
    dbRole: apiToDbRole[roleRaw],
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const token = getBearer(req);
  if (!token) return json({ error: "Missing Authorization header" }, 401);

  let body: InviteMemberPayload;
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
  const callerUserId = me.user.id;

  const { data: tenantRow, error: tenantErr } = await admin
    .from("tenants")
    .select("id")
    .eq("id", parsed.tenantId)
    .maybeSingle();
  if (tenantErr) return json({ error: tenantErr.message }, 400);
  if (!tenantRow) return json({ error: "Tenant not found." }, 404);

  const { data: membership, error: memberErr } = await admin
    .from("tenant_members")
    .select("role")
    .eq("tenant_id", parsed.tenantId)
    .eq("user_id", callerUserId)
    .maybeSingle();
  if (memberErr) return json({ error: memberErr.message }, 400);
  if (!membership || !["owner", "admin"].includes(membership.role)) {
    return json({ error: "Only tenant owner/admin can invite members." }, 403);
  }

  const { data: existingInvite, error: existingInviteErr } = await admin
    .from("tenant_invitations")
    .select("id, status")
    .eq("tenant_id", parsed.tenantId)
    .eq("status", "invited")
    .ilike("email", parsed.email)
    .maybeSingle();
  if (existingInviteErr) return json({ error: existingInviteErr.message }, 400);
  if (existingInvite) {
    return json(
      {
        error: "Pending invitation already exists.",
        invitation_id: existingInvite.id,
      },
      409,
    );
  }

  const { data: inviteData, error: inviteErr } = await admin.auth.admin.inviteUserByEmail(
    parsed.email,
    {
      data: {
        tenant_id: parsed.tenantId,
        invited_role: parsed.dbRole,
        invited_by: callerUserId,
      },
    },
  );
  if (inviteErr) {
    const status = typeof inviteErr.status === "number" && inviteErr.status >= 400
      ? inviteErr.status
      : 500;
    return json({ error: inviteErr.message }, status);
  }

  const invitedUserId = inviteData.user?.id ?? null;

  if (invitedUserId) {
    const { data: alreadyMember, error: alreadyMemberErr } = await admin
      .from("tenant_members")
      .select("user_id")
      .eq("tenant_id", parsed.tenantId)
      .eq("user_id", invitedUserId)
      .maybeSingle();
    if (alreadyMemberErr) return json({ error: alreadyMemberErr.message }, 400);
    if (alreadyMember) {
      return json({ error: "User is already a tenant member." }, 409);
    }
  }

  const { data: invitation, error: insertErr } = await admin
    .from("tenant_invitations")
    .insert({
      tenant_id: parsed.tenantId,
      email: parsed.email,
      role: parsed.dbRole,
      status: "invited",
      invited_by: callerUserId,
      invited_user_id: invitedUserId,
      meta: {
        requested_role: parsed.apiRole,
        source: "invite-member",
      },
    })
    .select("id, status")
    .single();
  if (insertErr) {
    if (insertErr.code === "23505") {
      return json({ error: "Pending invitation already exists." }, 409);
    }
    return json({ error: insertErr.message }, 400);
  }

  return json({
    ok: true,
    tenant_id: parsed.tenantId,
    email: parsed.email,
    role: parsed.apiRole,
    role_db: parsed.dbRole,
    invitation_id: invitation.id,
    invitation_status: invitation.status,
    invited_user_id: invitedUserId,
  });
});
