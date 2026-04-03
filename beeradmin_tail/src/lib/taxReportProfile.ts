export type JsonRecord = Record<string, unknown>

export const TAX_REPORT_PROFILE_META_KEY = 'tax_report_profile'

export type ZipParts = {
  zip1: string
  zip2: string
}

export type TelParts = {
  tel1: string
  tel2: string
  tel3: string
}

export type ZeimushoParts = {
  zeimusho_CD: string
  zeimusho_NM: string
}

export type NozeishaBangoParts = {
  kojinbango: string
  hojinbango: string
}

export type KanpuKinyukikanParts = {
  kinyukikan_NM: string
  kinyukikan_KB: string
  shiten_NM: string
  shiten_KB: string
  yokin: string
  koza: string
}

export interface TaxReportProfile {
  ZEIMUSHO: ZeimushoParts
  NOZEISHA_ID: string
  NOZEISHA_BANGO: NozeishaBangoParts
  NOZEISHA_NM_KN: string
  NOZEISHA_NM: string
  NOZEISHA_ZIP: ZipParts
  NOZEISHA_ADR_KN: string
  NOZEISHA_ADR: string
  NOZEISHA_TEL: TelParts
  KANPU_KINYUKIKAN: KanpuKinyukikanParts
  DAIHYO_NM_KN: string
  DAIHYO_NM: string
  DAIHYO_ZIP: ZipParts
  DAIHYO_ADR: string
  DAIHYO_TEL: TelParts
  SEIZOJO_NM_KN: string
  SEIZOJO_NM: string
  SEIZOJO_ZIP: ZipParts
  SEIZOJO_ADR: string
  SEIZOJO_TEL: TelParts
  DAIRI_NM: string
  DAIRI_TEL: TelParts
}

export function createEmptyTaxReportProfile(): TaxReportProfile {
  return {
    ZEIMUSHO: {
      zeimusho_CD: '',
      zeimusho_NM: '',
    },
    NOZEISHA_ID: '',
    NOZEISHA_BANGO: {
      kojinbango: '',
      hojinbango: '',
    },
    NOZEISHA_NM_KN: '',
    NOZEISHA_NM: '',
    NOZEISHA_ZIP: emptyZip(),
    NOZEISHA_ADR_KN: '',
    NOZEISHA_ADR: '',
    NOZEISHA_TEL: emptyTel(),
    KANPU_KINYUKIKAN: {
      kinyukikan_NM: '',
      kinyukikan_KB: '',
      shiten_NM: '',
      shiten_KB: '',
      yokin: '',
      koza: '',
    },
    DAIHYO_NM_KN: '',
    DAIHYO_NM: '',
    DAIHYO_ZIP: emptyZip(),
    DAIHYO_ADR: '',
    DAIHYO_TEL: emptyTel(),
    SEIZOJO_NM_KN: '',
    SEIZOJO_NM: '',
    SEIZOJO_ZIP: emptyZip(),
    SEIZOJO_ADR: '',
    SEIZOJO_TEL: emptyTel(),
    DAIRI_NM: '',
    DAIRI_TEL: emptyTel(),
  }
}

export function normalizeTaxReportProfile(meta: unknown): TaxReportProfile {
  const profile = createEmptyTaxReportProfile()
  const root = getRecord(meta)
  const source = getRecord(root[TAX_REPORT_PROFILE_META_KEY])

  profile.ZEIMUSHO = normalizeZeimusho(source)
  profile.NOZEISHA_ID = readStringOrFallback(source.NOZEISHA_ID, getRecord(source.nozeisha).userId)
  profile.NOZEISHA_BANGO = normalizeNozeishaBango(source)
  profile.NOZEISHA_NM_KN = readStringOrFallback(source.NOZEISHA_NM_KN, getRecord(source.nozeisha).nameKana)
  profile.NOZEISHA_NM = readStringOrFallback(source.NOZEISHA_NM, getRecord(source.nozeisha).name)
  profile.NOZEISHA_ZIP = normalizeZipWithFallback(source.NOZEISHA_ZIP, getRecord(source.nozeisha).zip)
  profile.NOZEISHA_ADR_KN = readStringOrFallback(source.NOZEISHA_ADR_KN, getRecord(source.nozeisha).addressKana)
  profile.NOZEISHA_ADR = readStringOrFallback(source.NOZEISHA_ADR, getRecord(source.nozeisha).address)
  profile.NOZEISHA_TEL = normalizeTelWithFallback(source.NOZEISHA_TEL, getRecord(source.nozeisha).tel)
  profile.KANPU_KINYUKIKAN = normalizeKanpuKinyukikan(source)
  profile.DAIHYO_NM_KN = readStringOrFallback(source.DAIHYO_NM_KN, getRecord(source.representative).nameKana)
  profile.DAIHYO_NM = readStringOrFallback(source.DAIHYO_NM, getRecord(source.representative).name)
  profile.DAIHYO_ZIP = normalizeZipWithFallback(source.DAIHYO_ZIP, getRecord(source.representative).zip)
  profile.DAIHYO_ADR = readStringOrFallback(source.DAIHYO_ADR, getRecord(source.representative).address)
  profile.DAIHYO_TEL = normalizeTelWithFallback(source.DAIHYO_TEL, getRecord(source.representative).tel)
  profile.SEIZOJO_NM_KN = readStringOrFallback(source.SEIZOJO_NM_KN, getRecord(source.brewery).nameKana)
  profile.SEIZOJO_NM = readStringOrFallback(source.SEIZOJO_NM, getRecord(source.brewery).name)
  profile.SEIZOJO_ZIP = normalizeZipWithFallback(source.SEIZOJO_ZIP, getRecord(source.brewery).zip)
  profile.SEIZOJO_ADR = readStringOrFallback(source.SEIZOJO_ADR, getRecord(source.brewery).address)
  profile.SEIZOJO_TEL = normalizeTelWithFallback(source.SEIZOJO_TEL, getRecord(source.brewery).tel)
  profile.DAIRI_NM = readStringOrFallback(source.DAIRI_NM, getRecord(source.taxAccountant).name)
  profile.DAIRI_TEL = normalizeTelWithFallback(source.DAIRI_TEL, getRecord(source.taxAccountant).tel)

  return profile
}

export function withTaxReportProfileMeta(existingMeta: unknown, profile: TaxReportProfile): JsonRecord {
  const base = getRecord(existingMeta)
  return {
    ...base,
    [TAX_REPORT_PROFILE_META_KEY]: serializeTaxReportProfile(profile),
  }
}

export function serializeTaxReportProfile(profile: TaxReportProfile): JsonRecord {
  return {
    ZEIMUSHO: {
      zeimusho_CD: clean(profile.ZEIMUSHO.zeimusho_CD),
      zeimusho_NM: clean(profile.ZEIMUSHO.zeimusho_NM),
    },
    NOZEISHA_ID: clean(profile.NOZEISHA_ID),
    NOZEISHA_BANGO: {
      kojinbango: clean(profile.NOZEISHA_BANGO.kojinbango),
      hojinbango: clean(profile.NOZEISHA_BANGO.hojinbango),
    },
    NOZEISHA_NM_KN: clean(profile.NOZEISHA_NM_KN),
    NOZEISHA_NM: clean(profile.NOZEISHA_NM),
    NOZEISHA_ZIP: serializeZip(profile.NOZEISHA_ZIP),
    NOZEISHA_ADR_KN: clean(profile.NOZEISHA_ADR_KN),
    NOZEISHA_ADR: clean(profile.NOZEISHA_ADR),
    NOZEISHA_TEL: serializeTel(profile.NOZEISHA_TEL),
    KANPU_KINYUKIKAN: {
      kinyukikan_NM: clean(profile.KANPU_KINYUKIKAN.kinyukikan_NM),
      kinyukikan_KB: clean(profile.KANPU_KINYUKIKAN.kinyukikan_KB),
      shiten_NM: clean(profile.KANPU_KINYUKIKAN.shiten_NM),
      shiten_KB: clean(profile.KANPU_KINYUKIKAN.shiten_KB),
      yokin: clean(profile.KANPU_KINYUKIKAN.yokin),
      koza: clean(profile.KANPU_KINYUKIKAN.koza),
    },
    DAIHYO_NM_KN: clean(profile.DAIHYO_NM_KN),
    DAIHYO_NM: clean(profile.DAIHYO_NM),
    DAIHYO_ZIP: serializeZip(profile.DAIHYO_ZIP),
    DAIHYO_ADR: clean(profile.DAIHYO_ADR),
    DAIHYO_TEL: serializeTel(profile.DAIHYO_TEL),
    SEIZOJO_NM_KN: clean(profile.SEIZOJO_NM_KN),
    SEIZOJO_NM: clean(profile.SEIZOJO_NM),
    SEIZOJO_ZIP: serializeZip(profile.SEIZOJO_ZIP),
    SEIZOJO_ADR: clean(profile.SEIZOJO_ADR),
    SEIZOJO_TEL: serializeTel(profile.SEIZOJO_TEL),
    DAIRI_NM: clean(profile.DAIRI_NM),
    DAIRI_TEL: serializeTel(profile.DAIRI_TEL),
  }
}

function emptyZip(): ZipParts {
  return { zip1: '', zip2: '' }
}

function emptyTel(): TelParts {
  return { tel1: '', tel2: '', tel3: '' }
}

function normalizeZeimusho(source: JsonRecord): ZeimushoParts {
  const current = getRecord(source.ZEIMUSHO)
  const legacy = getRecord(source.zeimusho)
  return {
    zeimusho_CD: readStringOrFallback(current.zeimusho_CD, legacy.code),
    zeimusho_NM: readStringOrFallback(current.zeimusho_NM, legacy.name),
  }
}

function normalizeNozeishaBango(source: JsonRecord): NozeishaBangoParts {
  const current = getRecord(source.NOZEISHA_BANGO)
  const legacy = getRecord(source.nozeisha)
  return {
    kojinbango: readString(current.kojinbango),
    hojinbango: readStringOrFallback(current.hojinbango, legacy.corporateNumber),
  }
}

function normalizeKanpuKinyukikan(source: JsonRecord): KanpuKinyukikanParts {
  const current = getRecord(source.KANPU_KINYUKIKAN)
  const legacy = getRecord(source.refundAccount)
  return {
    kinyukikan_NM: readStringOrFallback(current.kinyukikan_NM, legacy.financialInstitutionName),
    kinyukikan_KB: readStringOrFallback(current.kinyukikan_KB, legacy.financialInstitutionType),
    shiten_NM: readStringOrFallback(current.shiten_NM, legacy.branchName),
    shiten_KB: readStringOrFallback(current.shiten_KB, legacy.branchType),
    yokin: readStringOrFallback(current.yokin, legacy.accountType),
    koza: readStringOrFallback(current.koza, legacy.accountNumber),
  }
}

function normalizeZipWithFallback(currentValue: unknown, legacyValue: unknown): ZipParts {
  const current = normalizeZip(currentValue)
  if (current.zip1 || current.zip2) {
    return current
  }
  return normalizeZip(legacyValue)
}

function normalizeTelWithFallback(currentValue: unknown, legacyValue: unknown): TelParts {
  const current = normalizeTel(currentValue)
  if (current.tel1 || current.tel2 || current.tel3) {
    return current
  }
  return normalizeTel(legacyValue)
}

function normalizeZip(value: unknown): ZipParts {
  const source = getRecord(value)
  return {
    zip1: readString(source.zip1),
    zip2: readString(source.zip2),
  }
}

function normalizeTel(value: unknown): TelParts {
  const source = getRecord(value)
  return {
    tel1: readString(source.tel1),
    tel2: readString(source.tel2),
    tel3: readString(source.tel3),
  }
}

function serializeZip(value: ZipParts): JsonRecord {
  return {
    zip1: clean(value.zip1),
    zip2: clean(value.zip2),
  }
}

function serializeTel(value: TelParts): JsonRecord {
  return {
    tel1: clean(value.tel1),
    tel2: clean(value.tel2),
    tel3: clean(value.tel3),
  }
}

function getRecord(value: unknown): JsonRecord {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {}
  return value as JsonRecord
}

function readString(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

function readStringOrFallback(value: unknown, fallback: unknown): string {
  const current = readString(value)
  return current || readString(fallback)
}

function clean(value: string): string {
  return value.trim()
}
