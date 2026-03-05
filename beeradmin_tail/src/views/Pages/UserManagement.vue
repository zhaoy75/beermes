<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div
      class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] lg:p-6"
    >
      <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-800 dark:text-white/90">
            {{ t('users.title') }}
          </h3>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('users.subtitle') }}
          </p>
        </div>
        <button
          type="button"
          :disabled="!canManageUsers || loading || saving"
          @click="openAdd"
          class="flex w-full items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"
        >
          {{ t('users.actions.add') }}
        </button>
      </div>

      <div
        v-if="pageError"
        class="mt-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-300"
      >
        {{ pageError }}
      </div>

      <div
        class="mt-6 rounded-xl border border-gray-200 bg-gray-50 p-4 dark:border-gray-800 dark:bg-gray-900"
      >
        <div class="grid gap-4 md:grid-cols-4">
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.search.nameLabel') }}
            </label>
            <input
              v-model="filters.name"
              type="text"
              :placeholder="t('users.search.namePlaceholder')"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
          </div>
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.search.emailLabel') }}
            </label>
            <input
              v-model="filters.email"
              type="text"
              :placeholder="t('users.search.emailPlaceholder')"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
          </div>
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.search.roleLabel') }}
            </label>
            <select
              v-model="filters.role"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-3 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
            >
              <option :value="''">{{ t('users.search.roleAll') }}</option>
              <option v-for="option in roleFilterOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.search.statusLabel') }}
            </label>
            <select
              v-model="filters.status"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-3 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
            >
              <option :value="''">{{ t('users.search.statusAll') }}</option>
              <option v-for="option in statusOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </div>
        </div>
      </div>

      <div v-if="loading" class="mt-6 text-sm text-gray-500 dark:text-gray-400">
        {{ t('common.loading') }}
      </div>

      <div v-else class="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <div
          v-for="user in filteredUsers"
          :key="user.id"
          class="rounded-2xl border border-gray-200 bg-white p-4 shadow-theme-xs dark:border-gray-800 dark:bg-gray-900"
        >
          <div class="flex items-start justify-between gap-4">
            <div>
              <h4 class="text-base font-semibold text-gray-800 dark:text-white/90">
                {{ user.name }}
              </h4>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {{ user.email || '-' }}
              </p>
            </div>
            <span
              class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium"
              :class="statusClass(user.status)"
            >
              {{ statusLabel(user.status) }}
            </span>
          </div>

          <div class="mt-4 text-sm text-gray-600 dark:text-gray-400">
            {{ t('users.fields.role') }}:
            <span class="font-medium text-gray-800 dark:text-white/90">
              {{ roleLabel(user.role) }}
            </span>
          </div>

          <div class="mt-4 grid grid-cols-1 gap-2 sm:grid-cols-2">
            <button
              type="button"
              :disabled="!canManageUsers || saving"
              @click="openEdit(user)"
              class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-white/[0.03]"
            >
              {{ t('users.actions.edit') }}
            </button>
            <button
              type="button"
              :disabled="!canManageUsers || saving"
              @click="openDelete(user)"
              class="w-full rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-60 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30"
            >
              {{ t('users.actions.delete') }}
            </button>
          </div>
        </div>
      </div>

      <div
        v-if="!loading && filteredUsers.length === 0"
        class="mt-8 rounded-xl border border-dashed border-gray-300 p-6 text-center text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400"
      >
        {{ t('users.cards.empty') }}
      </div>
    </div>
  </AdminLayout>

  <Modal v-if="isFormOpen" :fullScreenBackdrop="true" @close="closeForm">
    <template #body>
      <div
        class="relative w-full max-w-[520px] rounded-3xl bg-white p-6 shadow-theme-lg dark:bg-gray-900"
      >
        <h4 class="text-xl font-semibold text-gray-800 dark:text-white/90">
          {{ formTitle }}
        </h4>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('users.dialogs.formSubtitle') }}
        </p>

        <form class="mt-6 space-y-4" @submit.prevent="saveUser">
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.fields.email') }}<span class="text-error-500">*</span>
            </label>
            <input
              v-model="form.email"
              type="email"
              :placeholder="t('users.placeholders.email')"
              :disabled="formMode === 'edit'"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 disabled:cursor-not-allowed disabled:bg-gray-100 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:disabled:bg-gray-800 dark:focus:border-brand-800"
            />
            <p v-if="formErrors.email" class="mt-1 text-xs text-error-500">
              {{ formErrors.email }}
            </p>
          </div>
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.fields.role') }}
            </label>
            <select
              v-model="form.role"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-3 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
            >
              <option v-for="option in editableRoleOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </div>
          <p v-if="formErrors.general" class="text-xs text-error-500">
            {{ formErrors.general }}
          </p>
          <div class="flex flex-col gap-3 pt-2 sm:flex-row sm:justify-end">
            <button
              type="button"
              @click="closeForm"
              class="flex w-full justify-center rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-white/[0.03] sm:w-auto"
            >
              {{ t('users.actions.cancel') }}
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="flex w-full justify-center rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"
            >
              {{ t('users.actions.save') }}
            </button>
          </div>
        </form>
      </div>
    </template>
  </Modal>

  <Modal v-if="isDeleteOpen" :fullScreenBackdrop="true" @close="closeDelete">
    <template #body>
      <div
        class="relative w-full max-w-[420px] rounded-3xl bg-white p-6 text-center shadow-theme-lg dark:bg-gray-900"
      >
        <h4 class="text-lg font-semibold text-gray-800 dark:text-white/90">
          {{ t('users.dialogs.deleteTitle') }}
        </h4>
        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
          {{ deleteMessage }}
        </p>
        <div class="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <button
            type="button"
            @click="closeDelete"
            class="flex w-full justify-center rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-white/[0.03] sm:w-auto"
          >
            {{ t('users.actions.cancel') }}
          </button>
          <button
            type="button"
            :disabled="saving"
            @click="confirmDelete"
            class="flex w-full justify-center rounded-lg bg-red-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"
          >
            {{ t('users.actions.confirmDelete') }}
          </button>
        </div>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import Modal from '@/components/ui/Modal.vue'

type UserRole = 'owner' | 'admin' | 'editor' | 'viewer'
type UserStatus = 'active' | 'invited'
type UserSource = 'member' | 'invitation'
type InvitationStatus = 'invited' | 'accepted' | 'revoked' | 'expired'

type UserRecord = {
  id: string
  source: UserSource
  memberUserId: string | null
  invitationId: string | null
  name: string
  email: string
  role: UserRole
  status: UserStatus
}

type TenantMemberRow = {
  tenant_id: string
  user_id: string
  role: UserRole
  created_at: string | null
}

type TenantInvitationRow = {
  id: string
  tenant_id: string
  email: string
  role: UserRole
  status: InvitationStatus
  invited_user_id: string | null
  invited_at: string | null
  accepted_at: string | null
}

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const { t } = useI18n()
const pageTitle = computed(() => t('users.title'))

const users = ref<UserRecord[]>([])
const tenantId = ref<string | null>(null)
const currentUserId = ref<string | null>(null)
const canManageUsers = ref(false)
const loading = ref(false)
const saving = ref(false)
const pageError = ref('')

const filters = reactive({
  name: '',
  email: '',
  role: '',
  status: '',
})

const roleFilterOptions = computed(() => [
  { value: 'viewer', label: t('users.roles.viewer') },
  { value: 'editor', label: t('users.roles.editor') },
  { value: 'admin', label: t('users.roles.admin') },
  { value: 'owner', label: t('users.roles.owner') },
])

const editableRoleOptions = computed(() => [
  { value: 'viewer', label: t('users.roles.viewer') },
  { value: 'editor', label: t('users.roles.editor') },
  { value: 'admin', label: t('users.roles.admin') },
])

const statusOptions = computed(() => [
  { value: 'active', label: t('users.status.active') },
  { value: 'invited', label: t('users.status.invited') },
])

const filteredUsers = computed(() => {
  const name = filters.name.trim().toLowerCase()
  const email = filters.email.trim().toLowerCase()
  const role = filters.role
  const status = filters.status
  return users.value.filter((user) => {
    const matchName = !name || user.name.toLowerCase().includes(name)
    const matchEmail = !email || user.email.toLowerCase().includes(email)
    const matchRole = !role || user.role === role
    const matchStatus = !status || user.status === status
    return matchName && matchEmail && matchRole && matchStatus
  })
})

const roleLabel = (role: UserRole) => t(`users.roles.${role}`)
const statusLabel = (status: UserStatus) => t(`users.status.${status}`)
const statusClass = (status: UserStatus) =>
  status === 'active'
    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
    : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'

const isFormOpen = ref(false)
const isDeleteOpen = ref(false)
const formMode = ref<'add' | 'edit'>('add')
const editTarget = ref<UserRecord | null>(null)
const deleteTarget = ref<UserRecord | null>(null)
const form = reactive({
  email: '',
  role: 'viewer' as UserRole,
})
const formErrors = reactive({
  email: '',
  general: '',
})

const formTitle = computed(() =>
  formMode.value === 'add' ? t('users.dialogs.addTitle') : t('users.dialogs.editTitle')
)

const deleteMessage = computed(() =>
  t('users.dialogs.deleteMessage', { name: deleteTarget.value?.name ?? deleteTarget.value?.email ?? '' })
)

const resetFormErrors = () => {
  formErrors.email = ''
  formErrors.general = ''
}

const toErrorMessage = (err: unknown, fallback: string) => {
  if (err && typeof err === 'object' && 'message' in err) {
    return String((err as { message: unknown }).message ?? fallback)
  }
  return fallback
}

const isPermissionError = (err: { code?: string | null; status?: number | null } | null) => {
  return err?.code === '42501' || err?.status === 401 || err?.status === 403
}

const getDisplayName = (email: string, userId: string | null) => {
  const cleanEmail = email.trim()
  if (cleanEmail) {
    const idx = cleanEmail.indexOf('@')
    return idx > 0 ? cleanEmail.slice(0, idx) : cleanEmail
  }
  if (userId) return `user-${userId.slice(0, 8)}`
  return '-'
}

const resolveTenantContext = async () => {
  if (tenantId.value && currentUserId.value) {
    return { tenantId: tenantId.value, userId: currentUserId.value }
  }

  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user?.id) throw error ?? new Error(t('users.errors.generic'))

  const resolvedTenant = data.user.app_metadata?.tenant_id as string | undefined
  if (!resolvedTenant) throw new Error(t('users.errors.tenantUnknown'))

  tenantId.value = resolvedTenant
  currentUserId.value = data.user.id
  return { tenantId: resolvedTenant, userId: data.user.id }
}

const mergeUserRows = (memberRows: TenantMemberRow[], invitationRows: TenantInvitationRow[]) => {
  const latestInvitationByUser = new Map<string, TenantInvitationRow>()
  for (const invite of invitationRows) {
    if (!invite.invited_user_id) continue
    const prev = latestInvitationByUser.get(invite.invited_user_id)
    if (!prev) {
      latestInvitationByUser.set(invite.invited_user_id, invite)
      continue
    }
    const prevTs = new Date(prev.accepted_at ?? prev.invited_at ?? 0).getTime()
    const curTs = new Date(invite.accepted_at ?? invite.invited_at ?? 0).getTime()
    if (curTs >= prevTs) {
      latestInvitationByUser.set(invite.invited_user_id, invite)
    }
  }

  const activeRows: UserRecord[] = memberRows.map((member) => {
    const linkedInvite = latestInvitationByUser.get(member.user_id)
    const email = linkedInvite?.email ?? ''
    return {
      id: `member:${member.user_id}`,
      source: 'member',
      memberUserId: member.user_id,
      invitationId: linkedInvite?.id ?? null,
      name: getDisplayName(email, member.user_id),
      email,
      role: member.role,
      status: 'active',
    }
  })

  const invitedRows: UserRecord[] = invitationRows
    .filter((invite) => invite.status === 'invited')
    .map((invite) => ({
      id: `invite:${invite.id}`,
      source: 'invitation',
      memberUserId: invite.invited_user_id,
      invitationId: invite.id,
      name: getDisplayName(invite.email, invite.invited_user_id),
      email: invite.email,
      role: invite.role,
      status: 'invited',
    }))

  return [...activeRows, ...invitedRows].sort((a, b) => {
    if (a.status !== b.status) return a.status === 'active' ? -1 : 1
    return a.email.localeCompare(b.email)
  })
}

const fetchUsers = async () => {
  try {
    loading.value = true
    pageError.value = ''
    const ctx = await resolveTenantContext()

    const { data: memberData, error: memberError } = await supabase
      .from('tenant_members')
      .select('tenant_id, user_id, role, created_at')
      .eq('tenant_id', ctx.tenantId)
    if (memberError) throw memberError

    const memberRows = ((memberData ?? []) as TenantMemberRow[])
    const myMembership = memberRows.find((row) => row.user_id === ctx.userId)
    canManageUsers.value = Boolean(myMembership && (myMembership.role === 'owner' || myMembership.role === 'admin'))

    const { data: invitationData, error: invitationError } = await supabase
      .from('tenant_invitations')
      .select('id, tenant_id, email, role, status, invited_user_id, invited_at, accepted_at')
      .eq('tenant_id', ctx.tenantId)
      .in('status', ['invited', 'accepted'])

    if (invitationError && !isPermissionError(invitationError)) throw invitationError

    const invitationRows = invitationError
      ? []
      : ((invitationData ?? []) as TenantInvitationRow[])

    users.value = mergeUserRows(memberRows, invitationRows)
  } catch (err) {
    console.error(err)
    users.value = []
    pageError.value = toErrorMessage(err, t('users.errors.loadFailed'))
  } finally {
    loading.value = false
  }
}

const openAdd = () => {
  pageError.value = ''
  if (!canManageUsers.value) {
    pageError.value = t('users.errors.permissionDenied')
    return
  }
  formMode.value = 'add'
  editTarget.value = null
  form.email = ''
  form.role = 'viewer'
  resetFormErrors()
  isFormOpen.value = true
}

const openEdit = (user: UserRecord) => {
  pageError.value = ''
  if (!canManageUsers.value) {
    pageError.value = t('users.errors.permissionDenied')
    return
  }
  if (user.role === 'owner') {
    pageError.value = t('users.errors.ownerProtected')
    return
  }
  formMode.value = 'edit'
  editTarget.value = user
  form.email = user.email
  form.role = user.role
  resetFormErrors()
  isFormOpen.value = true
}

const closeForm = () => {
  isFormOpen.value = false
}

const validateForm = () => {
  resetFormErrors()
  let valid = true

  if (formMode.value === 'add') {
    const email = form.email.trim().toLowerCase()
    if (!email) {
      formErrors.email = t('users.errors.emailRequired')
      valid = false
    } else if (!emailRegex.test(email)) {
      formErrors.email = t('users.errors.invalidEmail')
      valid = false
    }
  }

  if (form.role === 'owner') {
    formErrors.general = t('users.errors.ownerProtected')
    valid = false
  }

  return valid
}

const saveUser = async () => {
  if (!validateForm()) return
  if (!canManageUsers.value) {
    formErrors.general = t('users.errors.permissionDenied')
    return
  }

  try {
    saving.value = true
    const ctx = await resolveTenantContext()

    if (formMode.value === 'add') {
      const inviteRole = form.role === 'viewer' ? 'member' : form.role
      const { data, error } = await supabase.functions.invoke('invite-member', {
        body: {
          tenant_id: ctx.tenantId,
          email: form.email.trim().toLowerCase(),
          role: inviteRole,
        },
      })
      if (error) throw error
      if (data && typeof data === 'object' && 'error' in data) {
        throw new Error(String((data as { error?: unknown }).error ?? t('users.errors.inviteFailed')))
      }
    } else {
      const target = editTarget.value
      if (!target) throw new Error(t('users.errors.updateFailed'))

      if (target.source === 'member') {
        if (!target.memberUserId) throw new Error(t('users.errors.updateFailed'))
        const { error } = await supabase
          .from('tenant_members')
          .update({ role: form.role })
          .eq('tenant_id', ctx.tenantId)
          .eq('user_id', target.memberUserId)
        if (error) throw error
      } else {
        if (!target.invitationId) throw new Error(t('users.errors.updateFailed'))
        const { error } = await supabase
          .from('tenant_invitations')
          .update({ role: form.role })
          .eq('tenant_id', ctx.tenantId)
          .eq('id', target.invitationId)
          .eq('status', 'invited')
        if (error) throw error
      }
    }

    closeForm()
    await fetchUsers()
  } catch (err) {
    console.error(err)
    formErrors.general = toErrorMessage(
      err,
      formMode.value === 'add' ? t('users.errors.inviteFailed') : t('users.errors.updateFailed'),
    )
  } finally {
    saving.value = false
  }
}

const openDelete = (user: UserRecord) => {
  pageError.value = ''
  if (!canManageUsers.value) {
    pageError.value = t('users.errors.permissionDenied')
    return
  }
  deleteTarget.value = user
  isDeleteOpen.value = true
}

const closeDelete = () => {
  deleteTarget.value = null
  isDeleteOpen.value = false
}

const confirmDelete = async () => {
  if (!deleteTarget.value) return
  if (!canManageUsers.value) {
    pageError.value = t('users.errors.permissionDenied')
    return
  }
  if (deleteTarget.value.role === 'owner') {
    pageError.value = t('users.errors.ownerProtected')
    closeDelete()
    return
  }

  try {
    saving.value = true
    const ctx = await resolveTenantContext()
    const target = deleteTarget.value

    if (target.source === 'member') {
      if (!target.memberUserId) throw new Error(t('users.errors.deleteFailed'))
      const { error } = await supabase
        .from('tenant_members')
        .delete()
        .eq('tenant_id', ctx.tenantId)
        .eq('user_id', target.memberUserId)
      if (error) throw error
    } else {
      if (!target.invitationId) throw new Error(t('users.errors.deleteFailed'))
      const { error } = await supabase
        .from('tenant_invitations')
        .update({ status: 'revoked' })
        .eq('tenant_id', ctx.tenantId)
        .eq('id', target.invitationId)
        .eq('status', 'invited')
      if (error) throw error
    }

    closeDelete()
    await fetchUsers()
  } catch (err) {
    console.error(err)
    pageError.value = toErrorMessage(err, t('users.errors.deleteFailed'))
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await fetchUsers()
})
</script>
