import { element, emptyElement, joinXml } from './xml'

export function buildCatalogXml(options: { formIds: string[] }) {
  const { formIds } = options
  return element(
    'rdf:RDF',
    element(
      'rdf:description',
      joinXml([
        emptyElement('SEND_DATA'),
        element('IT_SEC', emptyElement('rdf:description', { about: '#IT' })),
        element(
          'FORM_SEC',
          element(
            'rdf:Seq',
            formIds
              .map((formId) => element('rdf:li', emptyElement('rdf:description', { about: `#${formId}` })))
              .join(''),
          ),
        ),
        emptyElement('TENPU_SEC'),
        emptyElement('XBRL_SEC'),
        emptyElement('XBRL2_1_SEC'),
        emptyElement('SOFUSHO_SEC'),
        emptyElement('ATTACH_SEC'),
        emptyElement('CSV_SEC'),
      ]),
      { id: 'REPORT' },
    ),
    {
      'xmlns:rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    },
  )
}
