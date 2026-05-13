import { volumeMillilitersForItem, type TaxVolumeItem } from '@/lib/taxReport'
import type { RLI0010_232_Input } from '../types'
import { paginate } from '../../core/pagination'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'
import { buildLia250Id, SOFTWARE_NAME } from '../constants'
import { schemaMap } from '../schemaMap'

export function buildLia250Xml(input: RLI0010_232_Input) {
  const pages = paginate(input.breakdown.nonTaxableRemovals, schemaMap.forms.LIA250.rowsPerPage)
  return pages
    .filter((items) => items.length > 0)
    .map((items, pageIndex) =>
      element(
        'LIA250',
        joinXml([
          element('ENA00000', element('ENA00010', buildYymmBody(input.report.taxYear, input.report.taxMonth))),
          element('ENB00000', joinXml([
            optionalElement('ENB00010', pageIndex + 1, { AutoCalc: 1 }),
            optionalElement('ENB00020', pages.length, { AutoCalc: 1 }),
          ])),
          input.profile.SEIZOJO_NM ? element('ENC00000', emptyElement('ENC00010', { IDREF: 'SEIZOJO_NM' })) : '',
          items.map((item) => buildLia250Row(item, input.report.taxYear, input.report.taxMonth)).join(''),
          buildNotes(items),
        ]),
        {
          VR: schemaMap.forms.LIA250.version,
          id: buildLia250Id(pageIndex + 1),
          page: pageIndex + 1,
          softNM: SOFTWARE_NAME,
          sakuseiNM: input.profile.NOZEISHA_NM || input.tenant.tenantName || SOFTWARE_NAME,
          sakuseiDay: input.report.generatedAt.slice(0, 10),
        },
      ),
    )
}

function buildLia250Row(item: TaxVolumeItem, fallbackYear: number, fallbackMonth: number) {
  const receiptVolumeMl = receiptVolumeMilliliters(item)
  return element('END00000', joinXml([
    element('END00010', optionalElement('kubun_CD', detailKubunCode(item))),
    optionalElement('END00020', resolveCategoryCode(item)),
    optionalElement('END00030', limitText(item.categoryName, 20)),
    element('END00060', buildDateBody(item.removal_date ?? item.movement_at, fallbackYear, fallbackMonth)),
    optionalElement('END00070', decimal1(item.removal_temperature), { AutoCalc: 1 }),
    optionalElement('END00080', decimal1(item.abv), { AutoCalc: 1 }),
    optionalElement('END00100', volumeMillilitersForItem(item), { AutoCalc: 1 }),
    item.receipt_date ? element('END00110', buildDateBody(item.receipt_date, fallbackYear, fallbackMonth)) : '',
    optionalElement('END00120', decimal1(item.receipt_temperature), { AutoCalc: 1 }),
    optionalElement('END00130', decimal1(item.receipt_abv), { AutoCalc: 1 }),
    optionalElement('END00150', receiptVolumeMl, { AutoCalc: 1 }),
    optionalElement('END00160', volumeDeltaAbv(item), { AutoCalc: 1 }),
    optionalElement('END00170', item.volume_delta_ml, { AutoCalc: 1 }),
    optionalElement('END00180', item.importer_address),
    optionalElement('END00190', item.importer_name),
    optionalElement('END00200', item.receipt_place_address),
    optionalElement('END00210', item.receipt_place_name),
    optionalElement('END00220', limitText(item.receipt_purpose ?? item.remarks, 28)),
  ]))
}

function buildNotes(items: TaxVolumeItem[]) {
  const notes = items
    .map((item) => item.remarks)
    .filter((value): value is string => Boolean(value))
    .join(' / ')
  return optionalElement('ENE00000', limitText(notes, 230))
}

function buildYymmBody(year: number, month: number) {
  const { era, yy } = toWarekiYear(year)
  return joinXml([
    optionalElement('gen:era', era),
    optionalElement('gen:yy', yy),
    optionalElement('gen:mm', month),
  ])
}

function buildDateBody(value: string | null | undefined, fallbackYear: number, fallbackMonth: number) {
  const parts = parseDateParts(value) ?? { year: fallbackYear, month: fallbackMonth, day: 1 }
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

function detailKubunCode(item: TaxVolumeItem) {
  const code = Number(item.kubun_code)
  return Number.isFinite(code) && code >= 0 && code <= 3 ? code : 1
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode.slice(0, 3)
  return '000'
}

function decimal1(value: number | null | undefined) {
  if (!Number.isFinite(value)) return null
  return Number(value).toFixed(1)
}

function receiptVolumeMilliliters(item: TaxVolumeItem) {
  if (Number.isFinite(item.receipt_volume_ml)) return Math.max(0, Math.round(Number(item.receipt_volume_ml)))
  if (Number.isFinite(item.receipt_volume_l)) return Math.max(0, Math.round(Number(item.receipt_volume_l) * 1000))
  return null
}

function volumeDeltaAbv(item: TaxVolumeItem) {
  if (!Number.isFinite(item.receipt_abv) || !Number.isFinite(item.abv)) return null
  return (Number(item.receipt_abv) - Number(item.abv)).toFixed(1)
}

function limitText(value: string | null | undefined, maxLength: number) {
  if (!value) return null
  return value.length > maxLength ? value.slice(0, maxLength) : value
}
