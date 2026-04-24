import { buildCatalogXml } from '../../core/catalog'
import { element, joinXml } from '../../core/xml'
import { buildItXml } from './it'
import { buildLia010Xml } from './lia010'
import { buildLia110Xml } from './lia110'
import { buildLia130Xml } from './lia130'
import { buildLia220Xml } from './lia220'
import type { RLI0010_232_Input } from '../types'
import { LIA010_ID, LIA130_ID, buildLia110Id, buildLia220Id } from '../constants'

export function buildXml(input: RLI0010_232_Input) {
  const lia110Pages = buildLia110Xml(input)
  const lia130Xml = buildLia130Xml(input)
  const lia220Pages = buildLia220Xml(input)
  const formIds = [
    LIA010_ID,
    ...lia110Pages.map((_, index) => buildLia110Id(index + 1)),
    ...(lia130Xml ? [LIA130_ID] : []),
    ...lia220Pages.map((_, index) => buildLia220Id(index + 1)),
  ]
  return `<?xml version="1.0" encoding="UTF-8"?>${element(
    'DATA',
    element(
      'RLI0010',
      joinXml([
        element('CATALOG', buildCatalogXml({ formIds }), { id: 'CATALOG' }),
        element('CONTENTS', joinXml([
          buildItXml(input.profile, input.report.generatedAt),
          buildLia010Xml(input),
          ...lia110Pages,
          lia130Xml,
          ...lia220Pages,
        ]), { id: 'CONTENTS' }),
      ]),
      { id: 'RLI0010', VR: '23.2.0' },
    ),
    {
      id: 'DATA',
      xmlns: 'http://xml.e-tax.nta.go.jp/XSD/shuzei',
      'xmlns:gen': 'http://xml.e-tax.nta.go.jp/XSD/general',
      'xmlns:kyo': 'http://xml.e-tax.nta.go.jp/XSD/kyotsu',
      'xmlns:dsig': 'http://www.w3.org/2000/09/xmldsig#',
      'xmlns:xlink': 'http://www.w3.org/1999/xlink',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
    },
  )}`
}
