import type { TaxReportProfile } from '@/lib/taxReportProfile'
import { element, joinXml, optionalElement } from '../../core/xml'
import { IT_ID, IT_VERSION, PROCEDURE_NAME } from '../constants'

export function buildItXml(profile: TaxReportProfile, generatedAt: string) {
  return element(
    'IT',
    joinXml([
      element('ZEIMUSHO', joinXml([
        optionalElement('gen:zeimusho_CD', profile.ZEIMUSHO.zeimusho_CD),
        optionalElement('gen:zeimusho_NM', profile.ZEIMUSHO.zeimusho_NM),
      ]), { ID: 'ZEIMUSHO' }),
      element('TEISYUTSU_DAY', buildYymmddBody(generatedAt), { ID: 'TEISYUTSU_DAY' }),
      optionalElementWithId('NOZEISHA_ID', profile.NOZEISHA_ID, 'NOZEISHA_ID'),
      buildNozeishaBango(profile),
      optionalElementWithId('NOZEISHA_NM_KN', profile.NOZEISHA_NM_KN, 'NOZEISHA_NM_KN'),
      optionalElementWithId('NOZEISHA_NM', profile.NOZEISHA_NM, 'NOZEISHA_NM'),
      buildZipElement('NOZEISHA_ZIP', profile.NOZEISHA_ZIP.zip1, profile.NOZEISHA_ZIP.zip2),
      optionalElementWithId('NOZEISHA_ADR_KN', profile.NOZEISHA_ADR_KN, 'NOZEISHA_ADR_KN'),
      optionalElementWithId('NOZEISHA_ADR', profile.NOZEISHA_ADR, 'NOZEISHA_ADR'),
      buildTelElement('NOZEISHA_TEL', profile.NOZEISHA_TEL.tel1, profile.NOZEISHA_TEL.tel2, profile.NOZEISHA_TEL.tel3),
      buildAccountElement(profile),
      optionalElementWithId('DAIHYO_NM_KN', profile.DAIHYO_NM_KN, 'DAIHYO_NM_KN'),
      optionalElementWithId('DAIHYO_NM', profile.DAIHYO_NM, 'DAIHYO_NM'),
      buildZipElement('DAIHYO_ZIP', profile.DAIHYO_ZIP.zip1, profile.DAIHYO_ZIP.zip2),
      optionalElementWithId('DAIHYO_ADR', profile.DAIHYO_ADR, 'DAIHYO_ADR'),
      buildTelElement('DAIHYO_TEL', profile.DAIHYO_TEL.tel1, profile.DAIHYO_TEL.tel2, profile.DAIHYO_TEL.tel3),
      optionalElementWithId('SEIZOJO_NM_KN', profile.SEIZOJO_NM_KN, 'SEIZOJO_NM_KN'),
      optionalElementWithId('SEIZOJO_NM', profile.SEIZOJO_NM, 'SEIZOJO_NM'),
      buildZipElement('SEIZOJO_ZIP', profile.SEIZOJO_ZIP.zip1, profile.SEIZOJO_ZIP.zip2),
      optionalElementWithId('SEIZOJO_ADR', profile.SEIZOJO_ADR, 'SEIZOJO_ADR'),
      buildTelElement('SEIZOJO_TEL', profile.SEIZOJO_TEL.tel1, profile.SEIZOJO_TEL.tel2, profile.SEIZOJO_TEL.tel3),
      optionalElementWithId('DAIRI_NM', profile.DAIRI_NM, 'DAIRI_NM'),
      buildTelElement('DAIRI_TEL', profile.DAIRI_TEL.tel1, profile.DAIRI_TEL.tel2, profile.DAIRI_TEL.tel3),
      element('TETSUZUKI', joinXml([
        element('procedure_CD', 'RLI0010'),
        optionalElement('procedure_NM', PROCEDURE_NAME),
      ]), { ID: 'TETSUZUKI' }),
    ]),
    { id: IT_ID, VR: IT_VERSION },
  )
}

function optionalElementWithId(name: string, value: string, id: string) {
  if (!value) return ''
  return element(name, value, { ID: id })
}

function buildNozeishaBango(profile: TaxReportProfile) {
  if (!profile.NOZEISHA_BANGO.kojinbango && !profile.NOZEISHA_BANGO.hojinbango) return ''
  return element(
    'NOZEISHA_BANGO',
    joinXml([
      optionalElement('gen:kojinbango', profile.NOZEISHA_BANGO.kojinbango),
      optionalElement('gen:hojinbango', profile.NOZEISHA_BANGO.hojinbango),
    ]),
    { ID: 'NOZEISHA_BANGO' },
  )
}

function buildZipElement(name: string, zip1: string, zip2: string) {
  if (!zip1 && !zip2) return ''
  return element(
    name,
    joinXml([
      optionalElement('gen:zip1', zip1),
      optionalElement('gen:zip2', zip2),
    ]),
    { ID: name },
  )
}

function buildTelElement(name: string, tel1: string, tel2: string, tel3: string) {
  if (!tel1 && !tel2 && !tel3) return ''
  return element(
    name,
    joinXml([
      optionalElement('gen:tel1', tel1),
      optionalElement('gen:tel2', tel2),
      optionalElement('gen:tel3', tel3 || '0'),
    ]),
    { ID: name },
  )
}

function buildAccountElement(profile: TaxReportProfile) {
  const account = profile.KANPU_KINYUKIKAN
  if (!account.kinyukikan_NM && !account.shiten_NM && !account.koza) return ''
  return element(
    'KANPU_KINYUKIKAN',
    joinXml([
      account.kinyukikan_NM
        ? element('gen:kinyukikan_NM', account.kinyukikan_NM, { kinyukikan_KB: account.kinyukikan_KB || undefined })
        : '',
      account.shiten_NM
        ? element('gen:shiten_NM', account.shiten_NM, { shiten_KB: account.shiten_KB || undefined })
        : '',
      optionalElement('gen:yokin', account.yokin),
      optionalElement('gen:koza', account.koza),
    ]),
    { ID: 'KANPU_KINYUKIKAN' },
  )
}

function buildYymmddBody(value: string) {
  const date = new Date(value)
  const { era, yy } = toWarekiYear(date.getUTCFullYear())
  return joinXml([
    optionalElement('gen:era', era),
    optionalElement('gen:yy', yy),
    optionalElement('gen:mm', date.getUTCMonth() + 1),
    optionalElement('gen:dd', date.getUTCDate()),
  ])
}

function toWarekiYear(year: number) {
  if (year >= 2019) return { era: 5, yy: year - 2018 }
  if (year >= 1989) return { era: 4, yy: year - 1988 }
  return { era: 3, yy: year }
}
