import { lia110KubunCodeForItem, type TaxVolumeItem } from '@/lib/taxReport'
import type { RLI0010_232_Input } from '../types'
import { paginate } from '../../core/pagination'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'
import { buildLia110Id, SOFTWARE_NAME } from '../constants'
import { schemaMap } from '../schemaMap'

export function buildLia110Xml(input: RLI0010_232_Input) {
  const pages = paginate(input.breakdown.summary, schemaMap.forms.LIA110.rowsPerPage)
  return pages.map((items, pageIndex) =>
    element(
      'LIA110',
      joinXml([
        element('EHA00000', element('EHA00010', buildYymmBody(input.report.taxYear, input.report.taxMonth))),
        element('EHB00000', joinXml([
          optionalElement('EHB00010', pageIndex + 1, { AutoCalc: 1 }),
          optionalElement('EHB00020', pages.length, { AutoCalc: 1 }),
        ])),
        input.profile.SEIZOJO_NM ? element('EHC00000', emptyElement('EHC00010', { IDREF: 'SEIZOJO_NM' })) : '',
        items.map((item) => buildLia110Row(item)).join(''),
      ]),
      {
        VR: '3.0',
        id: buildLia110Id(pageIndex + 1),
        page: pageIndex + 1,
        softNM: SOFTWARE_NAME,
        sakuseiNM: input.profile.NOZEISHA_NM || input.tenant.tenantName || SOFTWARE_NAME,
        sakuseiDay: input.report.generatedAt.slice(0, 10),
      },
    ),
  )
}

function buildLia110Row(item: TaxVolumeItem) {
  const volume = formatXmlVolume(item.volume_l)
  const taxRate = Math.max(0, Math.round(item.tax_rate || 0))
  const rowRole = item.row_role ?? 'detail'
  const kubunCode = lia110KubunCodeForItem(item)
  const taxAmount = taxAmountForRow(item)
  const taxEvent = item.tax_event || ''
  const nonTaxableRemovalVolume = formatOptionalXmlVolume(
    item.non_taxable_volume_l ?? (taxEvent === 'NON_TAXABLE_REMOVAL' ? item.volume_l : 0),
  )
  const exportExemptVolume = formatOptionalXmlVolume(
    item.export_exempt_volume_l ?? (taxEvent === 'EXPORT_EXEMPT' ? item.volume_l : 0),
  )
  const taxableStandardVolume = formatXmlVolume(
    item.taxable_volume_l ?? (taxEvent === 'TAXABLE_REMOVAL' ? item.volume_l : 0),
  )
  const includeTaxRate = rowRole === 'kubun_summary'
  const includeSummaryText = rowRole === 'detail'
  return element('EHD00000', joinXml([
    element('EHD00010', optionalElement('kubun_CD', kubunCode)),
    optionalElement('EHD00020', resolveCategoryCode(item)),
    optionalElement('EHD00030', item.categoryName),
    optionalElement('EHD00040', rowRole === 'detail' && item.abv != null ? item.abv.toFixed(1) : null, { AutoCalc: 1 }),
    optionalElement('EHD00050', volume, { AutoCalc: 1 }),
    optionalElement('EHD00060', nonTaxableRemovalVolume),
    optionalElement('EHD00070', exportExemptVolume),
    optionalElement('EHD00080', taxableStandardVolume, { AutoCalc: 1 }),
    optionalElement('EHD00090', includeTaxRate ? taxRate : null, { AutoCalc: 1 }),
    optionalElement('EHD00100', taxAmount, { AutoCalc: 1 }),
    optionalElement('EHD00140', taxAmount, { AutoCalc: 1 }),
    optionalElement('EHD00150', includeSummaryText ? moveTypeSummary(item.move_type, item.tax_event) : null),
  ]))
}

function buildYymmBody(year: number, month: number) {
  const { era, yy } = toWarekiYear(year)
  return joinXml([
    optionalElement('gen:era', era),
    optionalElement('gen:yy', yy),
    optionalElement('gen:mm', month),
  ])
}

function toWarekiYear(year: number) {
  if (year >= 2019) return { era: 5, yy: year - 2018 }
  if (year >= 1989) return { era: 4, yy: year - 1988 }
  return { era: 3, yy: year }
}

function formatXmlVolume(value: number) {
  if (!Number.isFinite(value)) return 0
  return Math.max(0, Math.round(value * 1000))
}

function formatOptionalXmlVolume(value: number | null | undefined) {
  if (!Number.isFinite(value) || Number(value) <= 0) return null
  return formatXmlVolume(Number(value))
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode.slice(0, 3)
  return '000'
}

function taxAmountForRow(item: TaxVolumeItem) {
  if (Number.isFinite(item.tax_amount)) return Math.max(0, Math.round(Number(item.tax_amount)))
  if ((item.row_role ?? 'detail') === 'detail') return 0
  const taxableVolume = item.taxable_volume_l ?? item.volume_l ?? 0
  return Math.max(0, Math.round((taxableVolume / 1000) * (item.tax_rate || 0)))
}

function moveTypeSummary(moveType: string, taxEvent?: string | null) {
  switch (taxEvent) {
    case 'TAXABLE_REMOVAL':
      return '課税移出'
    case 'EXPORT_EXEMPT':
      return '輸出免税'
    case 'NON_TAXABLE_REMOVAL':
      return '未納税移出'
    case 'RETURN_TO_FACTORY':
      return '戻入'
    case 'NONE':
      return '摘要'
    default:
      break
  }

  switch (moveType) {
    case 'sale':
      return '課税移出'
    case 'tax_transfer':
      return '輸出免税'
    case 'transfer':
      return '未納税移出'
    case 'waste':
      return '廃棄'
    default:
      return '摘要'
  }
}
