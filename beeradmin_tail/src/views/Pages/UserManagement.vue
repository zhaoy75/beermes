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
          @click="openAdd"
          class="flex w-full items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 sm:w-auto"
        >
          {{ t('users.actions.add') }}
        </button>
      </div>

      <div
        class="mt-6 rounded-xl border border-gray-200 bg-gray-50 p-4 dark:border-gray-800 dark:bg-gray-900"
      >
        <div class="grid gap-4 md:grid-cols-3">
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
              <option v-for="option in roleOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </div>
        </div>
      </div>

      <div class="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
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
                {{ user.email }}
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

          <div class="mt-4 grid grid-cols-1 gap-2 sm:grid-cols-3">
            <button
              type="button"
              @click="openEdit(user)"
              class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-white/[0.03]"
            >
              {{ t('users.actions.edit') }}
            </button>
            <button
              type="button"
              @click="openReset(user)"
              class="w-full rounded-lg border border-brand-200 bg-brand-50 px-3 py-2 text-sm font-medium text-brand-600 hover:bg-brand-100 dark:border-brand-800/40 dark:bg-brand-900/20 dark:text-brand-300 dark:hover:bg-brand-900/30"
            >
              {{ t('users.actions.resetPassword') }}
            </button>
            <button
              type="button"
              @click="openDelete(user)"
              class="w-full rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-100 dark:border-red-900/40 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30"
            >
              {{ t('users.actions.delete') }}
            </button>
          </div>
        </div>
      </div>

      <div
        v-if="filteredUsers.length === 0"
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
              {{ t('users.fields.name') }}<span class="text-error-500">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              :placeholder="t('users.placeholders.name')"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
            <p v-if="formErrors.name" class="mt-1 text-xs text-error-500">
              {{ formErrors.name }}
            </p>
          </div>
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.fields.email') }}<span class="text-error-500">*</span>
            </label>
            <input
              v-model="form.email"
              type="email"
              :placeholder="t('users.placeholders.email')"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
            <p v-if="formErrors.email" class="mt-1 text-xs text-error-500">
              {{ formErrors.email }}
            </p>
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <div>
              <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
                {{ t('users.fields.role') }}
              </label>
              <select
                v-model="form.role"
                class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-3 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
              >
                <option v-for="option in roleOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div>
              <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
                {{ t('users.fields.status') }}
              </label>
              <select
                v-model="form.status"
                class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-3 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
              >
                <option v-for="option in statusOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
          </div>
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
              class="flex w-full justify-center rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 sm:w-auto"
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
            @click="confirmDelete"
            class="flex w-full justify-center rounded-lg bg-red-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-red-700 sm:w-auto"
          >
            {{ t('users.actions.confirmDelete') }}
          </button>
        </div>
      </div>
    </template>
  </Modal>

  <Modal v-if="isResetOpen" :fullScreenBackdrop="true" @close="closeReset">
    <template #body>
      <div
        class="relative w-full max-w-[480px] rounded-3xl bg-white p-6 shadow-theme-lg dark:bg-gray-900"
      >
        <h4 class="text-lg font-semibold text-gray-800 dark:text-white/90">
          {{ t('users.dialogs.resetTitle') }}
        </h4>
        <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
          {{ resetSubtitle }}
        </p>

        <form class="mt-5 space-y-4" @submit.prevent="confirmReset">
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.fields.newPassword') }}<span class="text-error-500">*</span>
            </label>
            <input
              v-model="resetPasswordForm.password"
              type="password"
              :placeholder="t('users.placeholders.newPassword')"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
            <p v-if="resetErrors.password" class="mt-1 text-xs text-error-500">
              {{ resetErrors.password }}
            </p>
          </div>
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              {{ t('users.fields.confirmPassword') }}<span class="text-error-500">*</span>
            </label>
            <input
              v-model="resetPasswordForm.confirm"
              type="password"
              :placeholder="t('users.placeholders.confirmPassword')"
              class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
            <p v-if="resetErrors.confirm" class="mt-1 text-xs text-error-500">
              {{ resetErrors.confirm }}
            </p>
          </div>
          <div class="flex flex-col gap-3 pt-2 sm:flex-row sm:justify-end">
            <button
              type="button"
              @click="closeReset"
              class="flex w-full justify-center rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-white/[0.03] sm:w-auto"
            >
              {{ t('users.actions.cancel') }}
            </button>
            <button
              type="submit"
              class="flex w-full justify-center rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 sm:w-auto"
            >
              {{ t('users.actions.resetConfirm') }}
            </button>
          </div>
        </form>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import Modal from '@/components/ui/Modal.vue'

type UserRole = 'viewer' | 'editor' | 'admin'
type UserStatus = 'valid' | 'invalid'

type UserRecord = {
  id: string
  name: string
  email: string
  role: UserRole
  status: UserStatus
}

const { t } = useI18n()
const pageTitle = computed(() => t('users.title'))

const users = ref<UserRecord[]>([
  { id: 'u1', name: 'Akira Mori', email: 'akira.mori@example.com', role: 'admin', status: 'valid' },
  { id: 'u2', name: 'Mika Sato', email: 'mika.sato@example.com', role: 'editor', status: 'valid' },
  { id: 'u3', name: 'Ken Ito', email: 'ken.ito@example.com', role: 'viewer', status: 'invalid' },
  { id: 'u4', name: 'Naoko Abe', email: 'naoko.abe@example.com', role: 'editor', status: 'valid' },
  { id: 'u5', name: 'Yuta Kato', email: 'yuta.kato@example.com', role: 'viewer', status: 'valid' },
])

const filters = reactive({
  name: '',
  email: '',
  role: '',
})

const roleOptions = computed(() => [
  { value: 'viewer', label: t('users.roles.viewer') },
  { value: 'editor', label: t('users.roles.editor') },
  { value: 'admin', label: t('users.roles.admin') },
])

const statusOptions = computed(() => [
  { value: 'valid', label: t('users.status.valid') },
  { value: 'invalid', label: t('users.status.invalid') },
])

const filteredUsers = computed(() => {
  const name = filters.name.trim().toLowerCase()
  const email = filters.email.trim().toLowerCase()
  const role = filters.role
  return users.value.filter((user) => {
    const matchName = !name || user.name.toLowerCase().includes(name)
    const matchEmail = !email || user.email.toLowerCase().includes(email)
    const matchRole = !role || user.role === role
    return matchName && matchEmail && matchRole
  })
})

const roleLabel = (role: UserRole) => t(`users.roles.${role}`)
const statusLabel = (status: UserStatus) => t(`users.status.${status}`)
const statusClass = (status: UserStatus) =>
  status === 'valid'
    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
    : 'bg-gray-200 text-gray-700 dark:bg-gray-800 dark:text-gray-300'

const isFormOpen = ref(false)
const isDeleteOpen = ref(false)
const formMode = ref<'add' | 'edit'>('add')
const form = reactive<UserRecord>({
  id: '',
  name: '',
  email: '',
  role: 'viewer',
  status: 'valid',
})
const formErrors = reactive({
  name: '',
  email: '',
})

const deleteTarget = ref<UserRecord | null>(null)
const resetTarget = ref<UserRecord | null>(null)
const isResetOpen = ref(false)
const resetPasswordForm = reactive({
  password: '',
  confirm: '',
})
const resetErrors = reactive({
  password: '',
  confirm: '',
})

const formTitle = computed(() =>
  formMode.value === 'add' ? t('users.dialogs.addTitle') : t('users.dialogs.editTitle')
)
const deleteMessage = computed(() =>
  t('users.dialogs.deleteMessage', { name: deleteTarget.value?.name ?? '' })
)
const resetSubtitle = computed(() =>
  t('users.dialogs.resetSubtitle', { name: resetTarget.value?.name ?? '' })
)

const resetFormErrors = () => {
  formErrors.name = ''
  formErrors.email = ''
}

const resetResetErrors = () => {
  resetErrors.password = ''
  resetErrors.confirm = ''
}

const resetUserForm = () => {
  form.id = ''
  form.name = ''
  form.email = ''
  form.role = 'viewer'
  form.status = 'valid'
  resetFormErrors()
}

const openAdd = () => {
  formMode.value = 'add'
  resetUserForm()
  isFormOpen.value = true
}

const openEdit = (user: UserRecord) => {
  formMode.value = 'edit'
  form.id = user.id
  form.name = user.name
  form.email = user.email
  form.role = user.role
  form.status = user.status
  resetFormErrors()
  isFormOpen.value = true
}

const closeForm = () => {
  isFormOpen.value = false
}

const validateForm = () => {
  resetFormErrors()
  let valid = true
  if (!form.name.trim()) {
    formErrors.name = t('users.errors.nameRequired')
    valid = false
  }
  if (!form.email.trim()) {
    formErrors.email = t('users.errors.emailRequired')
    valid = false
  }
  return valid
}

const saveUser = () => {
  if (!validateForm()) return

  if (formMode.value === 'add') {
    users.value = [
      ...users.value,
      {
        id: `u${Date.now()}`,
        name: form.name.trim(),
        email: form.email.trim(),
        role: form.role,
        status: form.status,
      },
    ]
  } else {
    users.value = users.value.map((user) =>
      user.id === form.id
        ? {
            ...user,
            name: form.name.trim(),
            email: form.email.trim(),
            role: form.role,
            status: form.status,
          }
        : user
    )
  }

  closeForm()
}

const openDelete = (user: UserRecord) => {
  deleteTarget.value = user
  isDeleteOpen.value = true
}

const closeDelete = () => {
  deleteTarget.value = null
  isDeleteOpen.value = false
}

const openReset = (user: UserRecord) => {
  resetTarget.value = user
  resetPasswordForm.password = ''
  resetPasswordForm.confirm = ''
  resetResetErrors()
  isResetOpen.value = true
}

const closeReset = () => {
  resetTarget.value = null
  isResetOpen.value = false
}

const validateReset = () => {
  resetResetErrors()
  let valid = true
  if (!resetPasswordForm.password.trim()) {
    resetErrors.password = t('users.errors.passwordRequired')
    valid = false
  }
  if (!resetPasswordForm.confirm.trim()) {
    resetErrors.confirm = t('users.errors.confirmRequired')
    valid = false
  } else if (resetPasswordForm.password !== resetPasswordForm.confirm) {
    resetErrors.confirm = t('users.errors.passwordMismatch')
    valid = false
  }
  return valid
}

const confirmReset = () => {
  if (!validateReset()) return
  closeReset()
}

const confirmDelete = () => {
  if (!deleteTarget.value) return
  users.value = users.value.filter((user) => user.id !== deleteTarget.value?.id)
  closeDelete()
}
</script>
