export function paginate<T>(items: T[], size: number) {
  if (size <= 0) return [items]
  const pages: T[][] = []
  for (let index = 0; index < items.length; index += size) {
    pages.push(items.slice(index, index + size))
  }
  return pages.length > 0 ? pages : [[]]
}
