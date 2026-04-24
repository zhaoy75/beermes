export const reportName = 'RLI0010_232' as const
export const SOFTWARE_NAME = 'beeradmin_tail'
export const PROCEDURE_NAME = '酒税納税申告(月分申告用)'
export const IT_VERSION = '1.5'
export const IT_ID = 'IT'
export const LIA010_ID = 'LIA010-1'
export const LIA130_ID = 'LIA130-1'

export function buildLia110Id(page: number) {
  return `LIA110-${page}`
}

export function buildLia220Id(page: number) {
  return `LIA220-${page}`
}
