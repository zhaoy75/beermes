export type BatchAttrValidationMessages = {
  required: (field: string) => string
  mustBeNumber: (field: string) => string
  minValue: (field: string, min: number) => string
  maxValue: (field: string, max: number) => string
  pattern: (field: string) => string
  allowedValues: (field: string) => string
  invalidJson: (field: string) => string
  invalidReference: (field: string) => string
}

export type BatchAttrValidationField = {
  code: string
  name: string
  data_type: string
  required: boolean
  num_min?: number | null
  num_max?: number | null
  text_regex?: string | null
  allowed_values?: unknown | null
  ref_kind?: string | null
  value: unknown
}

export function normalizeBatchAttrDataType(value: string | null | undefined) {
  if (value === 'string') return 'text'
  if (value === 'boolean') return 'bool'
  return value ?? ''
}

export function isBatchAttrValueEmpty(value: unknown, dataType: string) {
  const normalized = normalizeBatchAttrDataType(dataType)
  if (normalized === 'bool') return false
  if (value === null || value === undefined) return true
  if (typeof value === 'string') return value.trim() === ''
  return false
}

export function validateBatchAttrField(
  field: BatchAttrValidationField,
  messages: BatchAttrValidationMessages,
) {
  const label = field.name || field.code
  const dataType = normalizeBatchAttrDataType(field.data_type)
  const empty = isBatchAttrValueEmpty(field.value, dataType)

  if (field.required && empty) {
    return messages.required(label)
  }

  if (empty) return ''

  if (dataType === 'number') {
    const numberValue = typeof field.value === 'number' ? field.value : Number(field.value)
    if (!Number.isFinite(numberValue)) {
      return messages.mustBeNumber(label)
    }
    if (typeof field.num_min === 'number' && numberValue < field.num_min) {
      return messages.minValue(label, field.num_min)
    }
    if (typeof field.num_max === 'number' && numberValue > field.num_max) {
      return messages.maxValue(label, field.num_max)
    }
  }

  if (dataType === 'text' || dataType === 'enum') {
    const textValue = String(field.value).trim()
    if (field.text_regex?.trim()) {
      try {
        const pattern = new RegExp(field.text_regex)
        if (!pattern.test(textValue)) {
          return messages.pattern(label)
        }
      } catch {
        return messages.pattern(label)
      }
    }
    const allowed = resolveAllowedValues(field.allowed_values)
    if (allowed.size > 0 && !allowed.has(textValue)) {
      return messages.allowedValues(label)
    }
  }

  if (dataType === 'json') {
    try {
      JSON.parse(String(field.value))
    } catch {
      return messages.invalidJson(label)
    }
  }

  if (dataType === 'ref') {
    if (field.ref_kind === 'type_def') {
      if (typeof field.value !== 'string' || !field.value.trim()) {
        return messages.invalidReference(label)
      }
    } else if (typeof field.value !== 'string' || !field.value.trim()) {
      return messages.invalidReference(label)
    }
  }

  return ''
}

function resolveAllowedValues(value: unknown) {
  const set = new Set<string>()
  if (Array.isArray(value)) {
    value.forEach((entry) => {
      const normalized = String(entry ?? '').trim()
      if (normalized) set.add(normalized)
    })
    return set
  }
  if (!value || typeof value !== 'object') return set

  Object.entries(value as Record<string, unknown>).forEach(([key, entry]) => {
    const normalizedKey = key.trim()
    if (normalizedKey) set.add(normalizedKey)
    if (typeof entry === 'string' || typeof entry === 'number' || typeof entry === 'boolean') {
      const normalizedValue = String(entry).trim()
      if (normalizedValue) set.add(normalizedValue)
    }
  })
  return set
}
