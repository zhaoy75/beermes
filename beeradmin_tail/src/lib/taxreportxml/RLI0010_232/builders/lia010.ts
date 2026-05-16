import type { RLI0010_232_Input } from '../types'
import { LIA010_ID, SOFTWARE_NAME } from '../constants'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'
import { nonNegativeYen } from '@/lib/moneyFormat'

export function buildLia010Xml(input: RLI0010_232_Input) {
  const { totals, report, profile, tenant } = input
  const declarationType = normalizeDeclarationType(report.declarationType)
  const isAmended = declarationType === 'amended'
  const hasRefundAccount = Boolean(
    profile.KANPU_KINYUKIKAN.kinyukikan_NM || profile.KANPU_KINYUKIKAN.shiten_NM || profile.KANPU_KINYUKIKAN.koza,
  )
  const hasTaxAccountant = Boolean(profile.DAIRI_NM || profile.DAIRI_TEL.tel1 || profile.DAIRI_TEL.tel2 || profile.DAIRI_TEL.tel3)

  return element(
    'LIA010',
    joinXml([
      element('EFA00000', element('EFA00010', buildYymmBody(report.taxYear, report.taxMonth))),
      element('EFB00000', joinXml([
        emptyElement('EFB00010', { IDREF: 'TEISYUTSU_DAY' }),
        emptyElement('EFB00020', { IDREF: 'ZEIMUSHO' }),
        profile.SEIZOJO_ZIP.zip1 || profile.SEIZOJO_ZIP.zip2 ? emptyElement('EFB00030', { IDREF: 'SEIZOJO_ZIP' }) : '',
        profile.SEIZOJO_ADR ? emptyElement('EFB00040', { IDREF: 'SEIZOJO_ADR' }) : '',
        profile.SEIZOJO_NM ? emptyElement('EFB00050', { IDREF: 'SEIZOJO_NM' }) : '',
        profile.SEIZOJO_TEL.tel1 || profile.SEIZOJO_TEL.tel2 || profile.SEIZOJO_TEL.tel3 ? emptyElement('EFB00060', { IDREF: 'SEIZOJO_TEL' }) : '',
        profile.NOZEISHA_ZIP.zip1 || profile.NOZEISHA_ZIP.zip2 ? emptyElement('EFB00070', { IDREF: 'NOZEISHA_ZIP' }) : '',
        profile.NOZEISHA_ADR ? emptyElement('EFB00080', { IDREF: 'NOZEISHA_ADR' }) : '',
        profile.NOZEISHA_TEL.tel1 || profile.NOZEISHA_TEL.tel2 || profile.NOZEISHA_TEL.tel3 ? emptyElement('EFB00090', { IDREF: 'NOZEISHA_TEL' }) : '',
        profile.NOZEISHA_NM ? emptyElement('EFB00100', { IDREF: 'NOZEISHA_NM' }) : '',
        profile.DAIHYO_NM ? emptyElement('EFB00110', { IDREF: 'DAIHYO_NM' }) : '',
      ])),
      element('EFC00000', joinXml([
        optionalElement('kubun_CD', declarationKubunCode(declarationType)),
      ])),
      element('EFD00000', joinXml([
        element('EFD00010', joinXml([
          optionalElement('EFD00020', nonNegativeYen(totals.totalTaxAmount), { AutoCalc: 1 }),
          optionalElement('EFD00030', nonNegativeYen(totals.roundedDownAmount || 0), { AutoCalc: 1 }),
          optionalElement('EFD00040', nonNegativeYen(totals.refundableTaxAmount || 0), { AutoCalc: 1 }),
          optionalElement('EFD00050', nonNegativeYen(totals.payableTaxAmount || 0), { AutoCalc: 1 }),
        ])),
        isAmended || totals.amendedRefundableTaxAmount || totals.amendedPayableTaxAmount
          ? element('EFD00060', joinXml([
              optionalElement('EFD00090', nonNegativeYen(totals.amendedRefundableTaxAmount || 0), { AutoCalc: 1 }),
              optionalElement('EFD00100', nonNegativeYen(totals.amendedPayableTaxAmount || 0), { AutoCalc: 1 }),
            ]))
          : '',
        optionalElement('EFD00110', nonNegativeYen(totals.netPayableTaxAmount ?? totals.payableTaxAmount ?? 0), { AutoCalc: 1 }),
      ])),
      hasTaxAccountant
        ? element('EFE00000', joinXml([
            profile.DAIRI_NM ? emptyElement('EFE00010', { IDREF: 'DAIRI_NM' }) : '',
            profile.DAIRI_TEL.tel1 || profile.DAIRI_TEL.tel2 || profile.DAIRI_TEL.tel3 ? emptyElement('EFE00020', { IDREF: 'DAIRI_TEL' }) : '',
          ]))
        : '',
      hasRefundAccount ? emptyElement('EFG00000', { IDREF: 'KANPU_KINYUKIKAN' }) : '',
      optionalElement('EFH00000', report.declarationReason),
      element('EFI00000', tenant.tenantName),
    ]),
    {
      VR: '4.1',
      id: LIA010_ID,
      page: 1,
      softNM: SOFTWARE_NAME,
      sakuseiNM: profile.NOZEISHA_NM || tenant.tenantName || SOFTWARE_NAME,
      sakuseiDay: report.generatedAt.slice(0, 10),
    },
  )
}

function normalizeDeclarationType(value: unknown) {
  return value === 'late' || value === 'amended' ? value : 'on_time'
}

function declarationKubunCode(value: unknown) {
  const declarationType = normalizeDeclarationType(value)
  if (declarationType === 'late') return 2
  if (declarationType === 'amended') return 3
  return 1
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
