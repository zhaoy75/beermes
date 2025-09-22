// deno-lint-ignore-file no-explicit-any
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Environment variables (auto-injected by Supabase CLI/platform)
const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const token = getBearer(req);
  if (!token) return json({ error: "Missing Authorization header" }, 401);

  // A client bound to the caller (respects RLS)
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: me, error: meErr } = await userClient.auth.getUser();
  if (meErr || !me?.user) return json({ error: "Invalid or expired token" }, 401);

  const userId = me.user.id;

  // Admin client to bypass RLS
  const admin = createClient(url, serviceKey);

  // 1. Look up tenant memberships
  const { data: memberships, error: memErr } = await admin
    .from("tenant_members")
    .select("tenant_id")
    .eq("user_id", userId);

  if (memErr) return json({ error: memErr.message }, 400);
  if (!memberships || memberships.length === 0) {
    return json({ error: "User does not belong to any tenant" }, 404);
  }

  // For simplicity: choose the first tenant (or you can add logic to pick one)
  const tenantId = memberships[0].tenant_id;

  // 2. Update app_metadata.tenant_id
  const { error: updErr } = await admin.auth.admin.updateUserById(userId, {
    app_metadata: { ...(me.user.app_metadata ?? {}), tenant_id: tenantId },
  });
  if (updErr) return json({ error: updErr.message }, 400);

  return json({
    ok: true,
    user_id: userId,
    tenant_id: tenantId,
    note: "Call supabase.auth.refreshSession() or sign in again to refresh JWT with tenant_id.",
  });
});
