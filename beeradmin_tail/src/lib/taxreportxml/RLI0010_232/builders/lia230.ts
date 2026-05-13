import { volumeMillilitersForItem, type TaxVolumeItem } from '@/lib/taxReport'
import { nonNegativeYen, taxAmountFromLiters } from '@/lib/moneyFormat'
import type { RLI0010_232_Input } from '../types'
import { paginate } from '../../core/pagination'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'
import { buildLia230Id, SOFTWARE_NAME } from '../constants'
import { schemaMap } from '../schemaMap'

type Lia230Row = TaxVolumeItem & {
  row_role?: TaxVolumeItem['row_role'] | 'kubun_summary'
}

export function buildLia230Xml(input: RLI0010_232_Input) {
  const rows = buildLia230OutputRows(input.breakdown.reimportDeductions)
  const pages = paginate(rows, schemaMap.forms.LIA230.rowsPerPage)
  return pages
    .filter((items) => items.length > 0)
    .map((items, pageIndex) =>
      element(
        'LIA230',
        joinXml([
          element('ELA00000', element('ELA00010', buildYymmBody(input.report.taxYear, input.report.taxMonth))),
          element('ELB00000', joinXml([
            optionalElement('ELB00010', pageIndex + 1, { AutoCalc: 1 }),
            optionalElement('ELB00020', pages.length, { AutoCalc: 1 }),
          ])),
          input.profile.SEIZOJO_NM ? element('ELC00000', emptyElement('ELC00010', { IDREF: 'SEIZOJO_NM' })) : '',
          items.map((item) => buildLia230Row(item)).join(''),
        ]),
        {
          VR: schemaMap.forms.LIA230.version,
          id: buildLia230Id(pageIndex + 1),
          page: pageIndex + 1,
          softNM: SOFTWARE_NAME,
          sakuseiNM: input.profile.NOZEISHA_NM || input.tenant.tenantName || SOFTWARE_NAME,
          sakuseiDay: input.report.generatedAt.slice(0, 10),
        },
      ),
    )
}

export function buildLia230OutputRows(items: TaxVolumeItem[]) {
  const groups = new Map<string, TaxVolumeItem[]>()
  items.forEach((item) => {
    const key = [
      resolveCategoryCode(item),
      item.categoryName || '',
      numberKey(item.abv),
      numberKey(item.tax_rate),
    ].join('|')
    if (!groups.has(key)) groups.set(key, [])
    groups.get(key)?.push(item)
  })

  return Array.from(groups.values())
    .sort((left, right) => compareRows(left[0], right[0]))
    .flatMap((group) => [
      ...group.sort(compareRows),
      buildSubtotalRow(group),
    ])
}

function buildLia230Row(item: Lia230Row) {
  const isSubtotal = item.row_role === 'kubun_summary'
  return element('ELD00000', joinXml([
    element('ELD00010', optionalElement('kubun_CD', isSubtotal ? 7 : detailKubunCode(item))),
    optionalElement('ELD00020', resolveCategoryCode(item)),
    optionalElement('ELD00030', limitText(item.categoryName, 20)),
    optionalElement('ELD00040', !isSubtotal && item.abv != null ? item.abv.toFixed(1) : null, { AutoCalc: 1 }),
    optionalElement('ELD00080', volumeMillilitersForItem(item), { AutoCalc: 1 }),
    optionalElement('ELD00090', taxRate(item)),
    optionalElement('ELD00100', taxAmount(item)),
    optionalElement('ELD00110', reducedTaxAmount(item)),
    optionalElement('ELD00120', isSubtotal ? null : limitText(item.remarks ?? item.receipt_purpose, 64)),
  ]))
}

function buildSubtotalRow(rows: TaxVolumeItem[]): Lia230Row {
  const first = rows[0]
  const volumeMl = rows.reduce((sum, item) => sum + volumeMillilitersForItem(item), 0)
  const taxAmountTotal = rows.reduce((sum, item) => sum + taxAmount(item), 0)
  const reducedValues = rows.map((item) => reducedTaxAmount(item)).filter((value) => value != null)
  const reducedTaxTotal = reducedValues.length > 0
    ? reducedValues.reduce((sum, value) => sum + Number(value), 0)
    : null

  return {
    ...first,
    key: `lia230-subtotal-${first?.key ?? 'row'}`,
    row_role: 'kubun_summary',
    volume_l: volumeMl / 1000,
    volume_ml: volumeMl,
    tax_amount: nonNegativeYen(taxAmountTotal),
    reduced_tax_amount: reducedTaxTotal == null ? null : nonNegativeYen(reducedTaxTotal),
  }
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

function detailKubunCode(item: TaxVolumeItem) {
  const code = Number(item.kubun_code)
  return Number.isFinite(code) && code >= 0 && code <= 3 ? code : 1
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode.slice(0, 3)
  return '000'
}

function taxRate(item: TaxVolumeItem) {
  return Math.max(0, Math.round(item.tax_rate || 0))
}

function taxAmount(item: TaxVolumeItem) {
  if (Number.isFinite(item.tax_amount)) return nonNegativeYen(Math.abs(Number(item.tax_amount)))
  return taxAmountFromLiters(item.volume_l || 0, item.tax_rate || 0)
}

function reducedTaxAmount(item: TaxVolumeItem) {
  if (!Number.isFinite(item.reduced_tax_amount)) return null
  return nonNegativeYen(Math.abs(Number(item.reduced_tax_amount)))
}

function compareRows(left: TaxVolumeItem | undefined, right: TaxVolumeItem | undefined) {
  const codeResult = resolveCategoryCode(left ?? emptyItem()).localeCompare(resolveCategoryCode(right ?? emptyItem()))
  if (codeResult !== 0) return codeResult
  const nameResult = String(left?.categoryName ?? '').localeCompare(String(right?.categoryName ?? ''))
  if (nameResult !== 0) return nameResult
  const abvResult = (right?.abv ?? -1) - (left?.abv ?? -1)
  if (abvResult !== 0) return abvResult
  return (left?.tax_rate ?? 0) - (right?.tax_rate ?? 0)
}

function emptyItem(): TaxVolumeItem {
  return {
    key: '',
    move_type: '',
    tax_event: null,
    categoryId: '',
    categoryCode: '',
    categoryName: '',
    abv: null,
    volume_l: 0,
    tax_rate: null,
  }
}

function numberKey(value: number | null | undefined) {
  return Number.isFinite(value) ? String(value) : 'none'
}

function limitText(value: string | null | undefined, maxLength: number) {
  if (!value) return null
  return value.length > maxLength ? value.slice(0, maxLength) : value
}
