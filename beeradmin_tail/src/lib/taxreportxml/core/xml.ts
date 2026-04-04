export type XmlAttributeValue = string | number | boolean | null | undefined

export function xmlEscape(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

export function serializeAttributes(attributes: Record<string, XmlAttributeValue>) {
  return Object.entries(attributes)
    .filter(([, value]) => value !== null && value !== undefined && value !== false)
    .map(([key, value]) => {
      if (value === true) return key
      return `${key}="${xmlEscape(String(value))}"`
    })
    .join(' ')
}

export function element(
  name: string,
  content: string,
  attributes: Record<string, XmlAttributeValue> = {},
) {
  const serialized = serializeAttributes(attributes)
  const open = serialized ? `<${name} ${serialized}>` : `<${name}>`
  return `${open}${content}</${name}>`
}

export function optionalElement(
  name: string,
  value: string | number | null | undefined,
  attributes: Record<string, XmlAttributeValue> = {},
) {
  if (value === null || value === undefined || value === '') return ''
  return element(name, xmlEscape(String(value)), attributes)
}

export function emptyElement(name: string, attributes: Record<string, XmlAttributeValue> = {}) {
  const serialized = serializeAttributes(attributes)
  return serialized ? `<${name} ${serialized}/>` : `<${name}/>`
}

export function joinXml(parts: Array<string | null | undefined>) {
  return parts.filter((part): part is string => Boolean(part && part.length)).join('')
}
