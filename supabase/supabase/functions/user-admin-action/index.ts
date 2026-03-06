import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type ActionType = "delete_user" | "reset_password" | "resend_invitation";

type UserAdminActionPayload = {
  action?: string;
  tenant_id?: string;
  target_user_id?: string;
  invitation_id?: string;
};

type MembershipRole = "owner" | "admin" | "editor" | "viewer";

type InvitationRow = {
  id: string;
  tenant_id: string;
  email: string;
  role: MembershipRole;
  status: "invited" | "accepted" | "revoked" | "expired";
  invited_user_id: string | null;
};

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const inviteRedirectTo = Deno.env.get("INVITE_REDIRECT_URL") ?? "http://localhost:5173/accept-invite";
const resetRedirectTo = Deno.env.get("RESET_PASSWORD_REDIRECT_URL") ??
  "http://localhost:5173/accept-invite";

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

function parsePayload(input: UserAdminActionPayload) {
  const action = String(input.action ?? "").trim() as ActionType;
  const tenantId = String(input.tenant_id ?? "").trim();
  const targetUserId = String(input.target_user_id ?? "").trim();
  const invitationId = String(input.invitation_id ?? "").trim();

  if (!["delete_user", "reset_password", "resend_invitation"].includes(action)) {
    return { ok: false as const, error: "action must be one of: delete_user, reset_password, resend_invitation." };
  }
  if (!tenantId || !uuidRegex.test(tenantId)) {
    return { ok: false as const, error: "tenant_id must be a valid UUID." };
  }

  if (action === "reset_password" && (!targetUserId || !uuidRegex.test(targetUserId))) {
    return { ok: false as const, error: "target_user_id is required and must be a valid UUID for reset_password." };
  }

  if (action === "resend_invitation" && (!invitationId || !uuidRegex.test(invitationId))) {
    return { ok: false as const, error: "invitation_id is required and must be a valid UUID for resend_invitation." };
  }

  if (action === "delete_user" && !targetUserId && !invitationId) {
    return { ok: false as const, error: "delete_user requires target_user_id or invitation_id." };
  }

  if (targetUserId && !uuidRegex.test(targetUserId)) {
    return { ok: false as const, error: "target_user_id must be a valid UUID." };
  }

  if (invitationId && !uuidRegex.test(invitationId)) {
    return { ok: false as const, error: "invitation_id must be a valid UUID." };
  }

  return {
    ok: true as const,
    action,
    tenantId,
    targetUserId: targetUserId || null,
    invitationId: invitationId || null,
  };
}

async function assertCallerIsAdmin(
  admin: ReturnType<typeof createClient>,
  tenantId: string,
  callerUserId: string,
) {
  const { data: membership, error } = await admin
    .from("tenant_members")
    .select("role")
    .eq("tenant_id", tenantId)
    .eq("user_id", callerUserId)
    .maybeSingle();

  if (error) return { ok: false as const, status: 400, error: error.message };
  if (!membership || !["owner", "admin"].includes(membership.role)) {
    return { ok: false as const, status: 403, error: "Only tenant owner/admin can perform this action." };
  }
  return { ok: true as const };
}

async function deleteByInvitation(
  admin: ReturnType<typeof createClient>,
  tenantId: string,
  invitationId: string,
) {
  const { data: invitation, error: inviteErr } = await admin
    .from("tenant_invitations")
    .select("id, tenant_id, status")
    .eq("tenant_id", tenantId)
    .eq("id", invitationId)
    .maybeSingle();
  if (inviteErr) return { ok: false as const, status: 400, error: inviteErr.message };
  if (!invitation) return { ok: false as const, status: 404, error: "Invitation not found." };
  if (invitation.status !== "invited") {
    return { ok: false as const, status: 409, error: "Only pending invitations can be revoked." };
  }

  const { error: revokeErr } = await admin
    .from("tenant_invitations")
    .update({ status: "revoked" })
    .eq("tenant_id", tenantId)
    .eq("id", invitationId)
    .eq("status", "invited");
  if (revokeErr) return { ok: false as const, status: 400, error: revokeErr.message };

  return {
    ok: true as const,
    result: {
      ok: true,
      action: "delete_user",
      tenant_id: tenantId,
      revoked_invitation_id: invitationId,
      membership_deleted: false,
      auth_user_deleted: false,
    },
  };
}

async function handleDeleteUser(
  admin: ReturnType<typeof createClient>,
  tenantId: string,
  callerUserId: string,
  targetUserId: string | null,
  invitationId: string | null,
) {
  if (!targetUserId && invitationId) {
    return await deleteByInvitation(admin, tenantId, invitationId);
  }
  if (!targetUserId) {
    return { ok: false as const, status: 400, error: "target_user_id is required." };
  }
  if (targetUserId === callerUserId) {
    return { ok: false as const, status: 409, error: "Self-delete is blocked." };
  }

  const { data: targetMembership, error: targetMemErr } = await admin
    .from("tenant_members")
    .select("role")
    .eq("tenant_id", tenantId)
    .eq("user_id", targetUserId)
    .maybeSingle();
  if (targetMemErr) return { ok: false as const, status: 400, error: targetMemErr.message };
  if (!targetMembership) return { ok: false as const, status: 404, error: "Target user is not a member of this tenant." };

  if (targetMembership.role === "owner") {
    const { count: ownerCount, error: countErr } = await admin
      .from("tenant_members")
      .select("user_id", { count: "exact", head: true })
      .eq("tenant_id", tenantId)
      .eq("role", "owner");
    if (countErr) return { ok: false as const, status: 400, error: countErr.message };
    if ((ownerCount ?? 0) <= 1) {
      return { ok: false as const, status: 409, error: "Cannot delete the last owner in this tenant." };
    }
  }

  const { data: targetUserData, error: targetUserErr } = await admin.auth.admin.getUserById(targetUserId);
  if (targetUserErr) return { ok: false as const, status: 400, error: targetUserErr.message };
  const targetEmail = (targetUserData.user?.email ?? "").trim().toLowerCase();

  const { error: deleteMemberErr } = await admin
    .from("tenant_members")
    .delete()
    .eq("tenant_id", tenantId)
    .eq("user_id", targetUserId);
  if (deleteMemberErr) return { ok: false as const, status: 400, error: deleteMemberErr.message };

  const revokedIds = new Set<string>();

  const { data: revokedByUser, error: revokeByUserErr } = await admin
    .from("tenant_invitations")
    .update({ status: "revoked" })
    .eq("tenant_id", tenantId)
    .eq("status", "invited")
    .eq("invited_user_id", targetUserId)
    .select("id");
  if (revokeByUserErr) return { ok: false as const, status: 400, error: revokeByUserErr.message };
  for (const row of revokedByUser ?? []) revokedIds.add(row.id as string);

  if (targetEmail) {
    const { data: revokedByEmail, error: revokeByEmailErr } = await admin
      .from("tenant_invitations")
      .update({ status: "revoked" })
      .eq("tenant_id", tenantId)
      .eq("status", "invited")
      .ilike("email", targetEmail)
      .select("id");
    if (revokeByEmailErr) return { ok: false as const, status: 400, error: revokeByEmailErr.message };
    for (const row of revokedByEmail ?? []) revokedIds.add(row.id as string);
  }

  const { count: remainingMemberships, error: remainErr } = await admin
    .from("tenant_members")
    .select("tenant_id", { count: "exact", head: true })
    .eq("user_id", targetUserId);
  if (remainErr) return { ok: false as const, status: 400, error: remainErr.message };

  let authUserDeleted = false;
  if ((remainingMemberships ?? 0) === 0) {
    const { error: delUserErr } = await admin.auth.admin.deleteUser(targetUserId);
    if (delUserErr) return { ok: false as const, status: 400, error: delUserErr.message };
    authUserDeleted = true;
  }

  return {
    ok: true as const,
    result: {
      ok: true,
      action: "delete_user",
      tenant_id: tenantId,
      target_user_id: targetUserId,
      membership_deleted: true,
      revoked_invitation_count: revokedIds.size,
      auth_user_deleted: authUserDeleted,
    },
  };
}

async function handleResetPassword(
  admin: ReturnType<typeof createClient>,
  tenantId: string,
  targetUserId: string,
) {
  const { data: targetMembership, error: targetMemErr } = await admin
    .from("tenant_members")
    .select("user_id")
    .eq("tenant_id", tenantId)
    .eq("user_id", targetUserId)
    .maybeSingle();
  if (targetMemErr) return { ok: false as const, status: 400, error: targetMemErr.message };
  if (!targetMembership) return { ok: false as const, status: 404, error: "Target user is not a member of this tenant." };

  const { data: userData, error: userErr } = await admin.auth.admin.getUserById(targetUserId);
  if (userErr) return { ok: false as const, status: 400, error: userErr.message };
  const email = (userData.user?.email ?? "").trim().toLowerCase();
  if (!email) return { ok: false as const, status: 404, error: "Target user email not found." };

  const { data, error: resetErr } = await admin.auth.resetPasswordForEmail(email, {
    redirectTo: resetRedirectTo,
  });
  if (resetErr) {
    const status = typeof resetErr.status === "number" && resetErr.status >= 400 ? resetErr.status : 400;
    return { ok: false as const, status, error: resetErr.message };
  }

  return {
    ok: true as const,
    result: {
      ok: true,
      action: "reset_password",
      tenant_id: tenantId,
      target_user_id: targetUserId,
      email,
      email_sent: !!data,
      redirect_to: resetRedirectTo,
    },
  };
}

async function handleResendInvitation(
  admin: ReturnType<typeof createClient>,
  tenantId: string,
  callerUserId: string,
  invitationId: string,
) {
  const { data: invitationRaw, error: invitationErr } = await admin
    .from("tenant_invitations")
    .select("id, tenant_id, email, role, status, invited_user_id")
    .eq("tenant_id", tenantId)
    .eq("id", invitationId)
    .maybeSingle();

  if (invitationErr) return { ok: false as const, status: 400, error: invitationErr.message };
  if (!invitationRaw) return { ok: false as const, status: 404, error: "Invitation not found." };

  const invitation = invitationRaw as InvitationRow;
  if (invitation.status === "accepted") {
    return { ok: false as const, status: 409, error: "Cannot resend an accepted invitation." };
  }

  if (invitation.invited_user_id) {
    const { data: alreadyMember, error: memErr } = await admin
      .from("tenant_members")
      .select("user_id")
      .eq("tenant_id", tenantId)
      .eq("user_id", invitation.invited_user_id)
      .maybeSingle();
    if (memErr) return { ok: false as const, status: 400, error: memErr.message };
    if (alreadyMember) {
      return { ok: false as const, status: 409, error: "User is already an active tenant member." };
    }
  }

  if (invitation.status === "invited") {
    const { error: revokeErr } = await admin
      .from("tenant_invitations")
      .update({ status: "revoked" })
      .eq("tenant_id", tenantId)
      .eq("id", invitation.id)
      .eq("status", "invited");
    if (revokeErr) return { ok: false as const, status: 400, error: revokeErr.message };
  }

  const normalizedEmail = invitation.email.trim().toLowerCase();

  const { data: inviteData, error: inviteErr } = await admin.auth.admin.inviteUserByEmail(
    normalizedEmail,
    {
      redirectTo: inviteRedirectTo,
      data: {
        tenant_id: tenantId,
        invited_role: invitation.role,
        invited_by: callerUserId,
      },
    },
  );
  if (inviteErr) {
    const status = typeof inviteErr.status === "number" && inviteErr.status >= 400 ? inviteErr.status : 500;
    return { ok: false as const, status, error: inviteErr.message };
  }

  const invitedUserId = inviteData.user?.id ?? invitation.invited_user_id ?? null;

  if (invitedUserId) {
    const { data: alreadyMember, error: memberErr } = await admin
      .from("tenant_members")
      .select("user_id")
      .eq("tenant_id", tenantId)
      .eq("user_id", invitedUserId)
      .maybeSingle();
    if (memberErr) return { ok: false as const, status: 400, error: memberErr.message };
    if (alreadyMember) return { ok: false as const, status: 409, error: "User is already an active tenant member." };
  }

  const { data: newInvitation, error: insertErr } = await admin
    .from("tenant_invitations")
    .insert({
      tenant_id: tenantId,
      email: normalizedEmail,
      role: invitation.role,
      status: "invited",
      invited_by: callerUserId,
      invited_user_id: invitedUserId,
      meta: {
        source: "user-admin-action",
        resent_from_invitation_id: invitation.id,
      },
    })
    .select("id, status")
    .single();
  if (insertErr) {
    if (insertErr.code === "23505") {
      return { ok: false as const, status: 409, error: "Pending invitation already exists." };
    }
    return { ok: false as const, status: 400, error: insertErr.message };
  }

  return {
    ok: true as const,
    result: {
      ok: true,
      action: "resend_invitation",
      tenant_id: tenantId,
      previous_invitation_id: invitation.id,
      invitation_id: newInvitation.id,
      invitation_status: newInvitation.status,
      invited_user_id: invitedUserId,
      email: normalizedEmail,
    },
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const token = getBearer(req);
  if (!token) return json({ error: "Missing Authorization header" }, 401);

  let body: UserAdminActionPayload;
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

  const adminCheck = await assertCallerIsAdmin(admin, parsed.tenantId, callerUserId);
  if (!adminCheck.ok) return json({ error: adminCheck.error }, adminCheck.status);

  if (parsed.action === "delete_user") {
    const result = await handleDeleteUser(
      admin,
      parsed.tenantId,
      callerUserId,
      parsed.targetUserId,
      parsed.invitationId,
    );
    if (!result.ok) return json({ error: result.error }, result.status);
    return json(result.result);
  }

  if (parsed.action === "reset_password") {
    const result = await handleResetPassword(admin, parsed.tenantId, parsed.targetUserId!);
    if (!result.ok) return json({ error: result.error }, result.status);
    return json(result.result);
  }

  const result = await handleResendInvitation(
    admin,
    parsed.tenantId,
    callerUserId,
    parsed.invitationId!,
  );
  if (!result.ok) return json({ error: result.error }, result.status);
  return json(result.result);
});
