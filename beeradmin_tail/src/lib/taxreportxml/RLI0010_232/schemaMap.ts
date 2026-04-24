export const schemaMap = {
  reportName: 'RLI0010_232',
  root: {
    procedureCode: 'RLI0010',
    version: '23.2.0',
    namespace: 'http://xml.e-tax.nta.go.jp/XSD/shuzei',
  },
  forms: {
    LIA010: { version: '4.1', required: true },
    LIA110: { version: '3.0', required: true, rowsPerPage: 18 },
    LIA130: { version: '1.0', required: false },
    LIA220: { version: '2.0', required: false, rowsPerPage: 18 },
    LIA260: { version: '3.0', required: false, rowsPerPage: 9 },
  },
  validation: {
    rootXsd: 'RLI0010-232.xsd',
  },
} as const
