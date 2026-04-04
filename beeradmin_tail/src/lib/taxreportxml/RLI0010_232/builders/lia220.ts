import type { TaxVolumeItem } from '@/lib/taxReport'
import type { RLI0010_232_Input } from '../types'
import { paginate } from '../../core/pagination'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'
import { buildLia220Id, SOFTWARE_NAME } from '../constants'
import { schemaMap } from '../schemaMap'

export function buildLia220Xml(input: RLI0010_232_Input) {
  const pages = paginate(input.breakdown.returns, schemaMap.forms.LIA220.rowsPerPage)
  return pages
    .filter((items) => items.length > 0)
    .map((items, pageIndex) =>
      element(
        'LIA220',
        joinXml([
          element('EKA00000', element('EKA00010', buildYymmBody(input.report.taxYear, input.report.taxMonth))),
          element('EKB00000', joinXml([
            optionalElement('EKB00010', pageIndex + 1, { AutoCalc: 1 }),
            optionalElement('EKB00020', pages.length, { AutoCalc: 1 }),
          ])),
          input.profile.SEIZOJO_NM ? element('EKC00000', emptyElement('EKC00010', { IDREF: 'SEIZOJO_NM' })) : '',
          items.map((item) => buildLia220Row(item)).join(''),
        ]),
        {
          VR: '2.0',
          id: buildLia220Id(pageIndex + 1),
          page: pageIndex + 1,
          softNM: SOFTWARE_NAME,
          sakuseiNM: input.profile.NOZEISHA_NM || input.tenant.tenantName || SOFTWARE_NAME,
          sakuseiDay: input.report.generatedAt.slice(0, 10),
        },
      ),
    )
}

function buildLia220Row(item: TaxVolumeItem) {
  const volume = formatXmlVolume(item.volume_l)
  const taxRate = Math.max(0, Math.round(item.tax_rate || 0))
  const taxAmount = Math.max(0, Math.round(((item.volume_l || 0) / 1000) * (item.tax_rate || 0)))
  return element('EKD00000', joinXml([
    element('EKD00010', optionalElement('kubun_CD', 1)),
    optionalElement('EKD00020', resolveCategoryCode(item)),
    optionalElement('EKD00030', item.categoryName),
    optionalElement('EKD00040', item.abv != null ? item.abv.toFixed(1) : null, { AutoCalc: 1 }),
    optionalElement('EKD00080', volume, { AutoCalc: 1 }),
    optionalElement('EKD00090', taxRate, { AutoCalc: 1 }),
    optionalElement('EKD00100', taxAmount, { AutoCalc: 1 }),
    optionalElement('EKD00120', moveTypeSummary(item.tax_event)),
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

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode.slice(0, 3)
  return '000'
}

function moveTypeSummary(taxEvent?: string | null) {
  if (taxEvent === 'EXPORT_EXEMPT') return '輸出のため戻入'
  if (taxEvent === 'RETURN_TO_FACTORY') return '戻入'
  return '品質劣化のため戻入'
}
