<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="max-w-6xl mx-auto p-4 space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div>
          <h1 class="text-xl font-semibold text-gray-800">{{ t('taxReportProfile.title') }}</h1>
          <p class="mt-1 text-sm text-gray-500">{{ t('taxReportProfile.subtitle') }}</p>
          <p class="mt-2 text-xs text-gray-500">{{ t('taxReportProfile.description') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span
            class="inline-flex items-center rounded-full px-3 py-1 text-xs font-medium"
            :class="canEdit ? 'bg-emerald-50 text-emerald-700' : 'bg-gray-100 text-gray-600'"
          >
            {{ canEdit ? t('taxReportProfile.mode.editable') : t('taxReportProfile.mode.readonly') }}
          </span>
          <button
            type="button"
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="loadPage"
          >
            {{ t('common.refresh') }}
          </button>
          <button
            v-if="canEdit"
            type="button"
            class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
            :disabled="loading || saving"
            @click="saveProfile"
          >
            {{ saving ? t('common.saving') : t('common.save') }}
          </button>
        </div>
      </header>

      <div
        v-if="pageError"
        class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
      >
        {{ pageError }}
      </div>

      <div
        v-if="!loading && !canEdit"
        class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800"
      >
        {{ t('taxReportProfile.readonlyNotice') }}
      </div>

      <div v-if="loading" class="rounded-lg border border-gray-200 bg-white px-4 py-6 text-sm text-gray-500">
        {{ t('common.loading') }}
      </div>

      <template v-else>
        <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.tenant') }}</h2>
          <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tenantName') }}</label>
              <input :value="tenantName" type="text" class="w-full h-[40px] border rounded px-3 bg-gray-50 text-gray-600" readonly />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tenantId') }}</label>
              <input :value="tenantId ?? ''" type="text" class="w-full h-[40px] border rounded px-3 bg-gray-50 text-gray-600 font-mono text-xs" readonly />
            </div>
          </div>
        </section>

        <fieldset :disabled="!canEdit || saving" class="space-y-4">
          <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.taxOffice') }}</h2>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.taxOfficeCode') }}</label>
                <input v-model.trim="form.ZEIMUSHO.zeimusho_CD" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.taxOfficeName') }}</label>
                <input v-model.trim="form.ZEIMUSHO.zeimusho_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.taxpayer') }}</h2>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.userId') }}</label>
                <input v-model.trim="form.NOZEISHA_ID" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.corporateNumber') }}</label>
                <input v-model.trim="form.NOZEISHA_BANGO.hojinbango" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.nameKana') }}</label>
                <input v-model.trim="form.NOZEISHA_NM_KN" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.name') }}</label>
                <input v-model.trim="form.NOZEISHA_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.zip1') }}</label>
                <input v-model.trim="form.NOZEISHA_ZIP.zip1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.zip2') }}</label>
                <input v-model.trim="form.NOZEISHA_ZIP.zip2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.addressKana') }}</label>
                <input v-model.trim="form.NOZEISHA_ADR_KN" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.address') }}</label>
                <input v-model.trim="form.NOZEISHA_ADR" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel1') }}</label>
                <input v-model.trim="form.NOZEISHA_TEL.tel1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel2') }}</label>
                <input v-model.trim="form.NOZEISHA_TEL.tel2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel3') }}</label>
                <input v-model.trim="form.NOZEISHA_TEL.tel3" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <div class="flex flex-col gap-1 md:flex-row md:items-center md:justify-between">
              <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.refundAccount') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportProfile.hints.refundAccountCodes') }}</p>
            </div>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.financialInstitutionName') }}</label>
                <input v-model.trim="form.KANPU_KINYUKIKAN.kinyukikan_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.financialInstitutionType') }}</label>
                <input v-model.trim="form.KANPU_KINYUKIKAN.kinyukikan_KB" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.branchName') }}</label>
                <input v-model.trim="form.KANPU_KINYUKIKAN.shiten_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.branchType') }}</label>
                <input v-model.trim="form.KANPU_KINYUKIKAN.shiten_KB" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.accountType') }}</label>
                <input v-model.trim="form.KANPU_KINYUKIKAN.yokin" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.accountNumber') }}</label>
                <input v-model.trim="form.KANPU_KINYUKIKAN.koza" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.representative') }}</h2>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.nameKana') }}</label>
                <input v-model.trim="form.DAIHYO_NM_KN" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.name') }}</label>
                <input v-model.trim="form.DAIHYO_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.zip1') }}</label>
                <input v-model.trim="form.DAIHYO_ZIP.zip1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.zip2') }}</label>
                <input v-model.trim="form.DAIHYO_ZIP.zip2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.address') }}</label>
                <input v-model.trim="form.DAIHYO_ADR" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel1') }}</label>
                <input v-model.trim="form.DAIHYO_TEL.tel1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel2') }}</label>
                <input v-model.trim="form.DAIHYO_TEL.tel2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel3') }}</label>
                <input v-model.trim="form.DAIHYO_TEL.tel3" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.brewery') }}</h2>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.nameKana') }}</label>
                <input v-model.trim="form.SEIZOJO_NM_KN" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.name') }}</label>
                <input v-model.trim="form.SEIZOJO_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.zip1') }}</label>
                <input v-model.trim="form.SEIZOJO_ZIP.zip1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.zip2') }}</label>
                <input v-model.trim="form.SEIZOJO_ZIP.zip2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.address') }}</label>
                <input v-model.trim="form.SEIZOJO_ADR" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel1') }}</label>
                <input v-model.trim="form.SEIZOJO_TEL.tel1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel2') }}</label>
                <input v-model.trim="form.SEIZOJO_TEL.tel2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel3') }}</label>
                <input v-model.trim="form.SEIZOJO_TEL.tel3" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
            <div class="flex flex-col gap-1 md:flex-row md:items-center md:justify-between">
              <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportProfile.sections.taxAccountant') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportProfile.hints.taxAccountantOptional') }}</p>
            </div>
            <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.taxAccountantName') }}</label>
                <input v-model.trim="form.DAIRI_NM" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel1') }}</label>
                <input v-model.trim="form.DAIRI_TEL.tel1" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel2') }}</label>
                <input v-model.trim="form.DAIRI_TEL.tel2" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReportProfile.fields.tel3') }}</label>
                <input v-model.trim="form.DAIRI_TEL.tel3" type="text" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              </div>
            </div>
          </section>
        </fieldset>
      </template>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import {
  createEmptyTaxReportProfile,
  normalizeTaxReportProfile,
  withTaxReportProfileMeta,
  type JsonRecord,
  type TaxReportProfile,
} from '@/lib/taxReportProfile'
import { getCurrentTenantContext, isCurrentUserTenantAdmin } from '@/modules/tenant/services/tenantContext'

type TenantRow = {
  id: string
  name: string
  meta: JsonRecord | null
}

const { t } = useI18n()

const pageTitle = computed(() => t('taxReportProfile.title'))
const loading = ref(false)
const saving = ref(false)
const canEdit = ref(false)
const tenantId = ref<string | null>(null)
const tenantName = ref('')
const pageError = ref('')
const existingMeta = ref<JsonRecord>({})
const form = reactive<TaxReportProfile>(createEmptyTaxReportProfile())

onMounted(() => {
  void loadPage()
})

async function loadPage() {
  try {
    loading.value = true
    pageError.value = ''

    const ctx = await getCurrentTenantContext()
    if (!ctx.tenantId) {
      throw new Error(t('taxReportProfile.errors.tenantMissing'))
    }

    tenantId.value = ctx.tenantId
    canEdit.value = ctx.isSystemAdmin || await isCurrentUserTenantAdmin()

    const { data, error } = await supabase
      .from('tenants')
      .select('id, name, meta')
      .eq('id', ctx.tenantId)
      .maybeSingle()

    if (error) throw error
    if (!data) {
      throw new Error(t('taxReportProfile.errors.loadFailed'))
    }

    const row = data as TenantRow
    tenantName.value = row.name
    existingMeta.value = row.meta && typeof row.meta === 'object' && !Array.isArray(row.meta) ? row.meta : {}
    applyProfile(normalizeTaxReportProfile(existingMeta.value))
  } catch (error) {
    console.error(error)
    pageError.value = error instanceof Error ? error.message : t('taxReportProfile.errors.loadFailed')
  } finally {
    loading.value = false
  }
}

async function saveProfile() {
  if (!tenantId.value) {
    toast.error(t('taxReportProfile.errors.tenantMissing'))
    return
  }
  if (!canEdit.value) {
    toast.error(t('taxReportProfile.errors.readOnly'))
    return
  }

  try {
    saving.value = true
    const nextMeta = withTaxReportProfileMeta(existingMeta.value, form)
    const { error } = await supabase
      .from('tenants')
      .update({ meta: nextMeta })
      .eq('id', tenantId.value)
    if (error) throw error

    existingMeta.value = nextMeta
    toast.success(t('common.saved'))
  } catch (error) {
    console.error(error)
    toast.error(error instanceof Error ? error.message : t('taxReportProfile.errors.saveFailed'))
  } finally {
    saving.value = false
  }
}

function applyProfile(profile: TaxReportProfile) {
  form.ZEIMUSHO.zeimusho_CD = profile.ZEIMUSHO.zeimusho_CD
  form.ZEIMUSHO.zeimusho_NM = profile.ZEIMUSHO.zeimusho_NM

  form.NOZEISHA_ID = profile.NOZEISHA_ID
  form.NOZEISHA_BANGO.kojinbango = profile.NOZEISHA_BANGO.kojinbango
  form.NOZEISHA_BANGO.hojinbango = profile.NOZEISHA_BANGO.hojinbango
  form.NOZEISHA_NM_KN = profile.NOZEISHA_NM_KN
  form.NOZEISHA_NM = profile.NOZEISHA_NM
  form.NOZEISHA_ZIP.zip1 = profile.NOZEISHA_ZIP.zip1
  form.NOZEISHA_ZIP.zip2 = profile.NOZEISHA_ZIP.zip2
  form.NOZEISHA_ADR_KN = profile.NOZEISHA_ADR_KN
  form.NOZEISHA_ADR = profile.NOZEISHA_ADR
  form.NOZEISHA_TEL.tel1 = profile.NOZEISHA_TEL.tel1
  form.NOZEISHA_TEL.tel2 = profile.NOZEISHA_TEL.tel2
  form.NOZEISHA_TEL.tel3 = profile.NOZEISHA_TEL.tel3

  form.KANPU_KINYUKIKAN.kinyukikan_NM = profile.KANPU_KINYUKIKAN.kinyukikan_NM
  form.KANPU_KINYUKIKAN.kinyukikan_KB = profile.KANPU_KINYUKIKAN.kinyukikan_KB
  form.KANPU_KINYUKIKAN.shiten_NM = profile.KANPU_KINYUKIKAN.shiten_NM
  form.KANPU_KINYUKIKAN.shiten_KB = profile.KANPU_KINYUKIKAN.shiten_KB
  form.KANPU_KINYUKIKAN.yokin = profile.KANPU_KINYUKIKAN.yokin
  form.KANPU_KINYUKIKAN.koza = profile.KANPU_KINYUKIKAN.koza

  form.DAIHYO_NM_KN = profile.DAIHYO_NM_KN
  form.DAIHYO_NM = profile.DAIHYO_NM
  form.DAIHYO_ZIP.zip1 = profile.DAIHYO_ZIP.zip1
  form.DAIHYO_ZIP.zip2 = profile.DAIHYO_ZIP.zip2
  form.DAIHYO_ADR = profile.DAIHYO_ADR
  form.DAIHYO_TEL.tel1 = profile.DAIHYO_TEL.tel1
  form.DAIHYO_TEL.tel2 = profile.DAIHYO_TEL.tel2
  form.DAIHYO_TEL.tel3 = profile.DAIHYO_TEL.tel3

  form.SEIZOJO_NM_KN = profile.SEIZOJO_NM_KN
  form.SEIZOJO_NM = profile.SEIZOJO_NM
  form.SEIZOJO_ZIP.zip1 = profile.SEIZOJO_ZIP.zip1
  form.SEIZOJO_ZIP.zip2 = profile.SEIZOJO_ZIP.zip2
  form.SEIZOJO_ADR = profile.SEIZOJO_ADR
  form.SEIZOJO_TEL.tel1 = profile.SEIZOJO_TEL.tel1
  form.SEIZOJO_TEL.tel2 = profile.SEIZOJO_TEL.tel2
  form.SEIZOJO_TEL.tel3 = profile.SEIZOJO_TEL.tel3

  form.DAIRI_NM = profile.DAIRI_NM
  form.DAIRI_TEL.tel1 = profile.DAIRI_TEL.tel1
  form.DAIRI_TEL.tel2 = profile.DAIRI_TEL.tel2
  form.DAIRI_TEL.tel3 = profile.DAIRI_TEL.tel3
}
</script>
