const ENABLED_VALUES = new Set(['1', 'true', 'yes', 'on'])

export function parseEnabledFlag(value: unknown): boolean {
  if (typeof value === 'boolean') return value
  if (typeof value === 'number') return value === 1
  if (typeof value !== 'string') return false

  return ENABLED_VALUES.has(value.trim().toLowerCase())
}

export const DEVELOPMENT_MODE_ENABLED = parseEnabledFlag(import.meta.env.VITE_DEVELOPMENT_MODE)
