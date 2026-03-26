export type WorkbookCellStyle = 'default' | 'border'

export type WorkbookCellValue = string | number | null | undefined

export type WorkbookCellObject = {
  style?: WorkbookCellStyle
  value: WorkbookCellValue
}

export type WorkbookCell = WorkbookCellValue | WorkbookCellObject

export type WorkbookSheet = {
  name: string
  rows: WorkbookCell[][]
}

type WorkbookOptions = {
  createdAtIso?: string
  creator?: string
  sheets: WorkbookSheet[]
}

const encoder = new TextEncoder()
const crc32Table = buildCrc32Table()

export function createWorkbookBlob(options: WorkbookOptions) {
  const createdAtIso = options.createdAtIso ?? new Date().toISOString()
  const creator = options.creator ?? 'Codex'
  const sheets = normalizeSheetNames(options.sheets)

  const files = [
    { name: '[Content_Types].xml', data: xmlBytes(buildContentTypesXml(sheets.length)) },
    { name: '_rels/.rels', data: xmlBytes(buildRootRelationshipsXml()) },
    { name: 'docProps/app.xml', data: xmlBytes(buildAppXml(sheets.map((sheet) => sheet.name))) },
    { name: 'docProps/core.xml', data: xmlBytes(buildCoreXml(createdAtIso, creator)) },
    { name: 'xl/workbook.xml', data: xmlBytes(buildWorkbookXml(sheets)) },
    { name: 'xl/_rels/workbook.xml.rels', data: xmlBytes(buildWorkbookRelationshipsXml(sheets.length)) },
    { name: 'xl/styles.xml', data: xmlBytes(buildStylesXml()) },
    ...sheets.map((sheet, index) => ({
      name: `xl/worksheets/sheet${index + 1}.xml`,
      data: xmlBytes(buildWorksheetXml(sheet.rows)),
    })),
  ]

  return zipStoredFiles(files)
}

function normalizeSheetNames(sheets: WorkbookSheet[]) {
  const used = new Set<string>()
  return sheets.map((sheet, index) => {
    const base = sanitizeSheetName(sheet.name || `Sheet${index + 1}`) || `Sheet${index + 1}`
    let candidate = base
    let counter = 2
    while (used.has(candidate)) {
      const suffix = `_${counter}`
      const truncated = base.slice(0, Math.max(1, 31 - suffix.length))
      candidate = `${truncated}${suffix}`
      counter += 1
    }
    used.add(candidate)
    return {
      ...sheet,
      name: candidate,
    }
  })
}

function sanitizeSheetName(value: string) {
  return value.replace(/[\\/*?:[\]]/g, '').trim().slice(0, 31)
}

function buildWorksheetXml(rows: WorkbookCell[][]) {
  const rowXml = rows
    .map((row, rowIndex) => {
      const cellXml = row
        .map((cell, columnIndex) => buildCellXml(cell, rowIndex + 1, columnIndex + 1))
        .filter((value) => value.length > 0)
        .join('')
      return `<row r="${rowIndex + 1}">${cellXml}</row>`
    })
    .join('')

  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>${rowXml}</sheetData>
</worksheet>`
}

function buildCellXml(cell: WorkbookCell, rowIndex: number, columnIndex: number) {
  const normalized = normalizeCell(cell)
  if (normalized.value == null || normalized.value === '') {
    if (!normalized.styleIndex) return ''
    const ref = `${columnName(columnIndex)}${rowIndex}`
    return `<c r="${ref}" s="${normalized.styleIndex}"/>`
  }
  const ref = `${columnName(columnIndex)}${rowIndex}`
  const styleAttr = normalized.styleIndex ? ` s="${normalized.styleIndex}"` : ''
  if (typeof normalized.value === 'number' && Number.isFinite(normalized.value)) {
    return `<c r="${ref}"${styleAttr}><v>${normalized.value}</v></c>`
  }
  const text = escapeXml(String(normalized.value))
  return `<c r="${ref}"${styleAttr} t="inlineStr"><is><t xml:space="preserve">${text}</t></is></c>`
}

function buildWorkbookXml(sheets: WorkbookSheet[]) {
  const sheetXml = sheets
    .map(
      (sheet, index) =>
        `<sheet name="${escapeXmlAttr(sheet.name)}" sheetId="${index + 1}" r:id="rId${index + 1}"/>`,
    )
    .join('')

  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>${sheetXml}</sheets>
</workbook>`
}

function buildWorkbookRelationshipsXml(sheetCount: number) {
  const sheetRels = Array.from({ length: sheetCount }, (_, index) =>
    `<Relationship Id="rId${index + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${index + 1}.xml"/>`,
  ).join('')
  const styleRel = `<Relationship Id="rId${sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>`

  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  ${sheetRels}${styleRel}
</Relationships>`
}

function buildRootRelationshipsXml() {
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>`
}

function buildContentTypesXml(sheetCount: number) {
  const sheetOverrides = Array.from({ length: sheetCount }, (_, index) =>
    `<Override PartName="/xl/worksheets/sheet${index + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`,
  ).join('')

  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  ${sheetOverrides}
</Types>`
}

function buildStylesXml() {
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="2">
    <border/>
    <border>
      <left style="thin"><color auto="1"/></left>
      <right style="thin"><color auto="1"/></right>
      <top style="thin"><color auto="1"/></top>
      <bottom style="thin"><color auto="1"/></bottom>
    </border>
  </borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/>
  </cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>`
}

function normalizeCell(cell: WorkbookCell) {
  if (typeof cell === 'object' && cell !== null && 'value' in cell) {
    return {
      styleIndex: resolveStyleIndex(cell.style),
      value: cell.value,
    }
  }
  return {
    styleIndex: 0,
    value: cell,
  }
}

function resolveStyleIndex(style: WorkbookCellStyle | undefined) {
  if (style === 'border') return 1
  return 0
}

function buildAppXml(sheetNames: string[]) {
  const titlePairs = sheetNames.map((name) => `<vt:lpstr>${escapeXml(name)}</vt:lpstr>`).join('')
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
 xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex</Application>
  <HeadingPairs>
    <vt:vector size="2" baseType="variant">
      <vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>
      <vt:variant><vt:i4>${sheetNames.length}</vt:i4></vt:variant>
    </vt:vector>
  </HeadingPairs>
  <TitlesOfParts>
    <vt:vector size="${sheetNames.length}" baseType="lpstr">${titlePairs}</vt:vector>
  </TitlesOfParts>
</Properties>`
}

function buildCoreXml(createdAtIso: string, creator: string) {
  const safeCreator = escapeXml(creator)
  const safeDate = escapeXml(createdAtIso)
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:dcmitype="http://purl.org/dc/dcmitype/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>${safeCreator}</dc:creator>
  <cp:lastModifiedBy>${safeCreator}</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">${safeDate}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">${safeDate}</dcterms:modified>
</cp:coreProperties>`
}

function xmlBytes(value: string) {
  return encoder.encode(value)
}

function zipStoredFiles(files: Array<{ name: string; data: Uint8Array }>) {
  const localParts: Uint8Array[] = []
  const centralParts: Uint8Array[] = []
  let offset = 0

  files.forEach((file) => {
    const nameBytes = encoder.encode(file.name)
    const crc = crc32(file.data)
    const localHeader = new Uint8Array(30 + nameBytes.length)
    const localView = new DataView(localHeader.buffer)
    localView.setUint32(0, 0x04034b50, true)
    localView.setUint16(4, 20, true)
    localView.setUint16(6, 0, true)
    localView.setUint16(8, 0, true)
    localView.setUint16(10, 0, true)
    localView.setUint16(12, 0, true)
    localView.setUint32(14, crc, true)
    localView.setUint32(18, file.data.length, true)
    localView.setUint32(22, file.data.length, true)
    localView.setUint16(26, nameBytes.length, true)
    localView.setUint16(28, 0, true)
    localHeader.set(nameBytes, 30)

    const centralHeader = new Uint8Array(46 + nameBytes.length)
    const centralView = new DataView(centralHeader.buffer)
    centralView.setUint32(0, 0x02014b50, true)
    centralView.setUint16(4, 20, true)
    centralView.setUint16(6, 20, true)
    centralView.setUint16(8, 0, true)
    centralView.setUint16(10, 0, true)
    centralView.setUint16(12, 0, true)
    centralView.setUint16(14, 0, true)
    centralView.setUint32(16, crc, true)
    centralView.setUint32(20, file.data.length, true)
    centralView.setUint32(24, file.data.length, true)
    centralView.setUint16(28, nameBytes.length, true)
    centralView.setUint16(30, 0, true)
    centralView.setUint16(32, 0, true)
    centralView.setUint16(34, 0, true)
    centralView.setUint16(36, 0, true)
    centralView.setUint32(38, 0, true)
    centralView.setUint32(42, offset, true)
    centralHeader.set(nameBytes, 46)

    localParts.push(localHeader, file.data)
    centralParts.push(centralHeader)
    offset += localHeader.length + file.data.length
  })

  const centralSize = centralParts.reduce((sum, part) => sum + part.length, 0)
  const end = new Uint8Array(22)
  const endView = new DataView(end.buffer)
  endView.setUint32(0, 0x06054b50, true)
  endView.setUint16(4, 0, true)
  endView.setUint16(6, 0, true)
  endView.setUint16(8, files.length, true)
  endView.setUint16(10, files.length, true)
  endView.setUint32(12, centralSize, true)
  endView.setUint32(16, offset, true)
  endView.setUint16(20, 0, true)

  return new Blob([...localParts, ...centralParts, end], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  })
}

function columnName(index: number) {
  let value = index
  let name = ''
  while (value > 0) {
    const remainder = (value - 1) % 26
    name = String.fromCharCode(65 + remainder) + name
    value = Math.floor((value - 1) / 26)
  }
  return name
}

function escapeXml(value: string) {
  return stripInvalidXmlChars(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}

function escapeXmlAttr(value: string) {
  return escapeXml(value).replace(/"/g, '&quot;')
}

function stripInvalidXmlChars(value: string) {
  return value.replace(/[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD]/g, '')
}

function buildCrc32Table() {
  const table = new Uint32Array(256)
  for (let i = 0; i < 256; i += 1) {
    let current = i
    for (let j = 0; j < 8; j += 1) {
      current = (current & 1) !== 0 ? 0xedb88320 ^ (current >>> 1) : current >>> 1
    }
    table[i] = current >>> 0
  }
  return table
}

function crc32(data: Uint8Array) {
  let crc = 0xffffffff
  for (let i = 0; i < data.length; i += 1) {
    crc = crc32Table[(crc ^ data[i]) & 0xff] ^ (crc >>> 8)
  }
  return (crc ^ 0xffffffff) >>> 0
}
