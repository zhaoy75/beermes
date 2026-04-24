import { lia110KubunCodeForItem, volumeMillilitersForItem, type TaxVolumeItem } from '@/lib/taxReport'
import type { RLI0010_232_Input } from '../types'
import { paginate } from '../../core/pagination'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'
import { buildLia260Id, SOFTWARE_NAME } from '../constants'
import { schemaMap } from '../schemaMap'

export function buildLia260Xml(input: RLI0010_232_Input) {
  const pages = paginate(input.breakdown.exportExempt, schemaMap.forms.LIA260.rowsPerPage)
  return pages
    .filter((items) => items.length > 0)
    .map((items, pageIndex) =>
      element(
        'LIA260',
        joinXml([
          element('EOA00000', element('EOA00010', buildYymmBody(input.report.taxYear, input.report.taxMonth))),
          element('EOB00000', joinXml([
            optionalElement('EOB00010', pageIndex + 1, { AutoCalc: 1 }),
            optionalElement('EOB00020', pages.length, { AutoCalc: 1 }),
          ])),
          input.profile.SEIZOJO_NM ? element('EOC00000', emptyElement('EOC00010', { IDREF: 'SEIZOJO_NM' })) : '',
          items.map((item) => buildLia260Row(item, input)).join(''),
        ]),
        {
          VR: schemaMap.forms.LIA260.version,
          id: buildLia260Id(pageIndex + 1),
          page: pageIndex + 1,
          softNM: SOFTWARE_NAME,
          sakuseiNM: input.profile.NOZEISHA_NM || input.tenant.tenantName || SOFTWARE_NAME,
          sakuseiDay: input.report.generatedAt.slice(0, 10),
        },
      ),
    )
}

function buildLia260Row(item: TaxVolumeItem, input: RLI0010_232_Input) {
  const exportDate = buildExportDateBody(item.export_date, input.report.taxYear, input.report.taxMonth)
  const exporterAddress = item.exporter_address || input.profile.NOZEISHA_ADR || input.profile.SEIZOJO_ADR
  const exporterName = item.exporter_name || input.profile.NOZEISHA_NM || input.tenant.tenantName
  return element('EOD00000', joinXml([
    element('EOD00010', optionalElement('kubun_CD', lia260KubunCodeForItem(item))),
    optionalElement('EOD00020', resolveCategoryCode(item)),
    optionalElement('EOD00030', limitText(item.categoryName, 20)),
    optionalElement('EOD00040', item.abv != null ? item.abv.toFixed(1) : null, { AutoCalc: 1 }),
    optionalElement('EOD00080', volumeMillilitersForItem(item), { AutoCalc: 1 }),
    exportDate ? element('EOD00090', exportDate) : '',
    optionalElement('EOD00100', limitText(item.export_destination, 14)),
    optionalElement('EOD00110', limitText(item.export_customs_office, 14)),
    optionalElement('EOD00120', exporterAddress),
    optionalElement('EOD00130', exporterName),
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

function buildExportDateBody(value: string | null | undefined, fallbackYear: number, fallbackMonth: number) {
  const parsed = parseDateParts(value)
  const parts = parsed ?? { year: fallbackYear, month: fallbackMonth, day: 1 }
  const { era, yy } = toWarekiYear(parts.year)
  return joinXml([
    optionalElement('gen:era', era),
    optionalElement('gen:yy', yy),
    optionalElement('gen:mm', parts.month),
    optionalElement('gen:dd', parts.day),
  ])
}

function parseDateParts(value: string | null | undefined) {
  if (!value) return null
  const match = value.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/)
  if (!match) return null
  const year = Number(match[1])
  const month = Number(match[2])
  const day = Number(match[3])
  if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) return null
  if (month < 1 || month > 12 || day < 1 || day > 31) return null
  return { year, month, day }
}

function toWarekiYear(year: number) {
  if (year >= 2019) return { era: 5, yy: year - 2018 }
  if (year >= 1989) return { era: 4, yy: year - 1988 }
  return { era: 3, yy: year }
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode.slice(0, 3)
  return '000'
}

function lia260KubunCodeForItem(item: TaxVolumeItem) {
  const code = lia110KubunCodeForItem(item)
  return code >= 0 && code <= 3 ? code : 0
}

function limitText(value: string | null | undefined, maxLength: number) {
  if (!value) return null
  return value.length > maxLength ? value.slice(0, maxLength) : value
}
