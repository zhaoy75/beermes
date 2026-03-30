export type JsonMap = Record<string, unknown>

export interface TaxVolumeItem {
  key: string
  move_type: string
  categoryId: string
  categoryCode: string
  categoryName: string
  abv: number | null
  volume_l: number
  tax_rate: number | null
}

export interface TaxReportRow {
  id: string
  tax_type: string
  tax_year: number
  tax_month: number
  status: string
  total_tax_amount: number
  volume_breakdown: TaxVolumeItem[]
  report_files: string[]
  attachment_files: string[]
  created_at: string | null
}

const SUMMARY_DOC_TYPES = ['sale', 'tax_transfer', 'return', 'transfer'] as const
const DISPOSE_DOC_TYPES = ['waste'] as const

export function summaryItemsFromBreakdown(items: TaxVolumeItem[]) {
  return items.filter((item) => isSummaryDocType(item.move_type))
}

export function disposeItemsFromBreakdown(items: TaxVolumeItem[]) {
  return items.filter((item) => isDisposeDocType(item.move_type))
}

export function isSummaryDocType(value: string): value is (typeof SUMMARY_DOC_TYPES)[number] {
  return (SUMMARY_DOC_TYPES as readonly string[]).includes(value)
}

export function isDisposeDocType(value: string): value is (typeof DISPOSE_DOC_TYPES)[number] {
  return (DISPOSE_DOC_TYPES as readonly string[]).includes(value)
}

export function parseFileList(text: string) {
  return text
    .split(/[\n,]/)
    .map((entry) => entry.trim())
    .filter(Boolean)
}

export function buildXmlFilename(taxType: string, taxYear: number, taxMonth: number) {
  const reiwa = taxYear >= 2019 ? `R${taxYear - 2018}年` : `${taxYear}年`
  if (taxType === 'yearly') {
    return `${reiwa}_納税申告.xtx`
  }
  return `${reiwa}${taxMonth}月_納税申告.xtx`
}

export function buildDisposeXmlFilename(taxType: string, taxYear: number, taxMonth: number) {
  return buildXmlFilename(taxType, taxYear, taxMonth).replace('.xtx', '_廃棄.xtx')
}

export function isDisposeFilename(filename: string, row: Pick<TaxReportRow, 'tax_type' | 'tax_year' | 'tax_month'>) {
  const expectedDisposeName = buildDisposeXmlFilename(row.tax_type, row.tax_year, row.tax_month)
  return filename === expectedDisposeName || filename.includes('廃棄')
}

export function normalizeReport(row: JsonMap): TaxReportRow {
  const files = Array.isArray(row.report_files) ? row.report_files : []
  const attachments = Array.isArray(row.attachment_files) ? row.attachment_files : []
  const breakdown = Array.isArray(row.volume_breakdown) ? row.volume_breakdown : []

  const normalizedBreakdown: TaxVolumeItem[] = breakdown
    .map((item: unknown, index: number) => {
      const record = item && typeof item === 'object' ? (item as JsonMap) : {}
      return {
        key: String(record.key ?? `${String(row.id ?? '')}-${index}`),
        move_type: String(record.move_type ?? record.moveType ?? record.doc_type ?? 'unknown'),
        categoryId: String(record.categoryId ?? record.category_id ?? ''),
        categoryCode: String(record.categoryCode ?? record.category_code ?? ''),
        categoryName: String(record.categoryName ?? record.category_name ?? '—'),
        abv: typeof record.abv === 'number' ? record.abv : record.abv ? Number(record.abv) : null,
        volume_l: typeof record.volume_l === 'number' ? record.volume_l : Number(record.volume_l || 0),
        tax_rate:
          typeof record.tax_rate === 'number'
            ? record.tax_rate
            : record.tax_rate
              ? Number(record.tax_rate)
              : record.taxRate
                ? Number(record.taxRate)
                : null,
      }
    })
    .filter((item) => item.categoryId || item.categoryName)

  if (normalizedBreakdown.length > 0 && normalizedBreakdown.every((item) => item.tax_rate == null)) {
    const totalVolume = normalizedBreakdown.reduce((sum, item) => sum + (item.volume_l || 0), 0)
    const fallbackRate = totalVolume > 0 ? Number(row.total_tax_amount ?? 0) / totalVolume : 0
    normalizedBreakdown.forEach((item) => {
      item.tax_rate = fallbackRate
    })
  }

  return {
    id: String(row.id ?? ''),
    tax_type: toNullableString(row.tax_type) ?? 'monthly',
    tax_year: Number(row.tax_year),
    tax_month: row.tax_month ? Number(row.tax_month) : 0,
    status: toNullableString(row.status) ?? 'draft',
    total_tax_amount: Number(row.total_tax_amount ?? 0),
    volume_breakdown: normalizedBreakdown,
    report_files: files.map((file: unknown) => String(file)),
    attachment_files: attachments.map((file: unknown) => String(file)),
    created_at: toNullableString(row.created_at),
  }
}

export function buildXmlPayload(options: {
  templateXml: string
  movementTypeLabel: (value: string) => string
  taxType: string
  taxYear: number
  taxMonth: number
  breakdown: TaxVolumeItem[]
}) {
  const { templateXml, movementTypeLabel, taxType, taxYear, taxMonth, breakdown } = options
  if (!templateXml) {
    throw new Error('TEMPLATE_NOT_LOADED')
  }

  const { era, yy } = reiwaYear(taxYear)
  const mm = taxType === 'monthly' ? taxMonth : 12
  const dateStr = new Date().toISOString().slice(0, 10)

  const taxableItems = breakdown.filter((item) => item.move_type !== 'return')
  const returnItems = breakdown.filter((item) => item.move_type === 'return')

  const ehdBlocks = taxableItems
    .map((item) => {
      const categoryCode = resolveCategoryCode(item)
      const abvTag = item.abv != null ? `\n                    <EHD00040>${item.abv}</EHD00040>` : ''
      const volume = formatXmlVolume(item.volume_l)
      return `                <EHD00000>
                    <EHD00010>
                        <kubun_CD>${kubunCodeForMoveType(item.move_type)}</kubun_CD>
                    </EHD00010>
                    <EHD00020>${categoryCode}</EHD00020>
                    <EHD00030>${xmlEscape(item.categoryName)}</EHD00030>${abvTag}
                    <EHD00050>${volume}</EHD00050>
                    <EHD00080 AutoCalc="1">${volume}</EHD00080>
                    <EHD00100 AutoCalc="1">0</EHD00100>
                </EHD00000>`
    })
    .join('\n')

  const ekdBlocks = returnItems
    .map((item) => {
      const categoryCode = resolveCategoryCode(item)
      const abvTag = item.abv != null ? `\n                    <EKD00040>${item.abv}</EKD00040>` : ''
      const volume = formatXmlVolume(item.volume_l)
      return `                <EKD00000>
                    <EKD00010>
                        <kubun_CD>1</kubun_CD>
                    </EKD00010>
                    <EKD00020>${categoryCode}</EKD00020>
                    <EKD00030>${xmlEscape(item.categoryName)}</EKD00030>${abvTag}
                    <EKD00080>${volume}</EKD00080>
                    <EKD00100 AutoCalc="1">0</EKD00100>
                    <EKD00120>${xmlEscape(movementTypeLabel(item.move_type))}</EKD00120>
                </EKD00000>`
    })
    .join('\n')

  let xml = templateXml

  xml = xml.replace(/sakuseiDay="\d{4}-\d{2}-\d{2}"/g, `sakuseiDay="${dateStr}"`)
  xml = xml.replace(/<gen:era>\d+<\/gen:era>/g, `<gen:era>${era}</gen:era>`)
  xml = xml.replace(/<gen:yy>\d+<\/gen:yy>/g, `<gen:yy>${yy}</gen:yy>`)
  xml = xml.replace(/<gen:mm>\d+<\/gen:mm>/g, `<gen:mm>${mm}</gen:mm>`)

  xml = xml.replace(/<LIA110[\s\S]*?<\/LIA110>/, (section) => {
    let updated = section.replace(/<EHD00000>[\s\S]*?<\/EHD00000>/g, '')
    updated = updated.replace(/(<EHC00000>[\s\S]*?<\/EHC00000>)/, `$1\n${ehdBlocks}`)
    return updated
  })

  xml = xml.replace(/<LIA220[\s\S]*?<\/LIA220>/, (section) => {
    let updated = section.replace(/<EKD00000>[\s\S]*?<\/EKD00000>/g, '')
    updated = updated.replace(/(<EKC00000>[\s\S]*?<\/EKC00000>)/, `$1\n${ekdBlocks}`)
    return updated
  })

  return xml
}

function toNullableString(value: unknown) {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed ? trimmed : null
}

function reiwaYear(year: number) {
  if (year >= 2019) return { era: 5, yy: year - 2018 }
  if (year >= 1989) return { era: 4, yy: year - 1988 }
  return { era: 3, yy: year }
}

function formatXmlVolume(value: number) {
  if (!Number.isFinite(value)) return '0'
  return String(Math.round(value * 1000))
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode
  return '000'
}

function kubunCodeForMoveType(moveType: string, fallback = '1') {
  switch (moveType) {
    case 'sale':
      return '1'
    case 'tax_transfer':
      return '2'
    case 'transfer':
      return '3'
    case 'waste':
      return '4'
    default:
      return fallback
  }
}

function xmlEscape(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}
