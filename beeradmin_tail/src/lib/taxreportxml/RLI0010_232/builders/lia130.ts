import type { RLI0010_232_Input, RLI0010_232_ReductionTotals } from '../types'
import { LIA130_ID, SOFTWARE_NAME } from '../constants'
import { element, emptyElement, joinXml, optionalElement } from '../../core/xml'

export function buildLia130Xml(input: RLI0010_232_Input) {
  const reduction = input.totals.reduction
  if (!reduction?.included) return ''

  return element(
    'LIA130',
    joinXml([
      element('EQA00000', element('EQA00010', buildYymmBody(input.report.taxYear, input.report.taxMonth))),
      input.profile.SEIZOJO_NM ? element('EQB00000', emptyElement('EQB00020', { IDREF: 'SEIZOJO_NM' })) : '',
      buildDetailsXml(reduction),
      optionalElement('EQD00000', reduction.category),
      element('EQE00000', optionalElement('EQE00040', amount(reduction.netReducedTaxAmount))),
    ]),
    {
      VR: '1.0',
      id: LIA130_ID,
      page: 1,
      softNM: SOFTWARE_NAME,
      sakuseiNM: input.profile.NOZEISHA_NM || input.tenant.tenantName || SOFTWARE_NAME,
      sakuseiDay: input.report.generatedAt.slice(0, 10),
    },
  )
}

function buildDetailsXml(reduction: RLI0010_232_ReductionTotals) {
  return element('EQC00000', joinXml([
    optionalElement('EQC00010', amount(reduction.priorFiscalYearStandardTaxAmount)),
    element('EQC00020', element('EQC00030', joinXml([
      element('EQC00040', joinXml([
        optionalElement('EQC00050', amount(reduction.currentMonthStandardTaxAmount)),
        element('EQC00060', joinXml([
          optionalElement('EQC00070', amount(reduction.currentMonthStandardTaxAmount)),
          optionalElement('EQC00080', amount(reduction.currentMonthReducedTaxAmount)),
        ])),
      ])),
      element('EQC00090', joinXml([
        optionalElement('EQC00100', amount(reduction.currentMonthStandardTaxAmount)),
        element('EQC00110', joinXml([
          optionalElement('EQC00120', amount(reduction.currentMonthStandardTaxAmount)),
          optionalElement('EQC00130', amount(reduction.currentMonthReducedTaxAmount)),
        ])),
      ])),
    ]))),
    optionalElement('EQC00290', amount(reduction.cumulativeBeforeReturnStandardTaxAmount)),
    element('EQC00300', joinXml([
      optionalElement('EQC00310', amount(reduction.returnStandardTaxAmount)),
      element('EQC00320', joinXml([
        optionalElement('EQC00330', amount(reduction.returnStandardTaxAmount)),
        optionalElement('EQC00340', amount(reduction.returnReducedTaxAmount)),
      ])),
    ])),
    element('EQC00350', joinXml([
      optionalElement('EQC00360', amount(reduction.netStandardTaxAmount)),
      element('EQC00370', joinXml([
        optionalElement('EQC00380', amount(reduction.netStandardTaxAmount)),
        optionalElement('EQC00390', amount(reduction.netReducedTaxAmount)),
      ])),
    ])),
    optionalElement('EQC00400', amount(reduction.cumulativeAfterReturnStandardTaxAmount)),
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

function amount(value: number) {
  return Math.max(0, Math.round(Number.isFinite(value) ? value : 0))
}
