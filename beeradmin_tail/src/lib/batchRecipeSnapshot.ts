type JsonRecord = Record<string, unknown>

export type BatchRecipeAttrFallback = {
  beerCategoryId?: string | null
  targetAbv?: number | null
  styleName?: string | null
}

export type BatchRecipeSource = {
  batch_code?: string | null
  batch_label?: string | null
  product_name?: string | null
  meta?: unknown
  released_reference_json?: unknown
  recipe_json?: unknown
  mes_recipe_id?: string | null
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function asRecord(value: unknown): JsonRecord | null {
  return isRecord(value) ? value : null
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : []
}

function asString(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed ? trimmed : null
}

function asNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : null
}

function getNestedRecord(value: unknown, key: string): JsonRecord | null {
  const record = asRecord(value)
  return record ? asRecord(record[key]) : null
}

function getNestedString(value: unknown, key: string): string | null {
  const record = asRecord(value)
  return record ? asString(record[key]) : null
}

function getNestedNumber(value: unknown, key: string): number | null {
  const record = asRecord(value)
  return record ? asNumber(record[key]) : null
}

function getPrimaryOutputName(recipeJson: unknown): string | null {
  const outputs = getNestedRecord(recipeJson, 'outputs')
  const primary = outputs ? asArray(outputs.primary) : []
  for (const item of primary) {
    const name = getNestedString(item, 'output_name')
    if (name) return name
  }
  return null
}

export function resolveMetaString(meta: unknown, key: string): string | null {
  const record = asRecord(meta)
  return record ? asString(record[key]) : null
}

export function resolveMetaNumber(meta: unknown, key: string): number | null {
  const record = asRecord(meta)
  return record ? asNumber(record[key]) : null
}

export function resolveBatchLabel(meta: unknown): string | null {
  return resolveMetaString(meta, 'label')
    ?? resolveMetaString(meta, 'batch_label')
    ?? resolveMetaString(meta, 'name')
}

export function resolveReleasedRecipeId(batch: BatchRecipeSource | null | undefined): string | null {
  if (!batch) return null
  return asString(batch.mes_recipe_id)
    ?? getNestedString(batch.released_reference_json, 'mes_recipe_id')
}

export function resolveReleasedRecipeCode(batch: BatchRecipeSource | null | undefined): string | null {
  if (!batch) return null
  return getNestedString(batch.released_reference_json, 'recipe_code')
    ?? resolveMetaString(batch.meta, 'product_code')
    ?? resolveMetaString(batch.meta, 'beer_code')
    ?? resolveMetaString(batch.meta, 'recipe_code')
    ?? asString(batch.batch_code)
}

export function resolveReleasedRecipeName(batch: BatchRecipeSource | null | undefined): string | null {
  if (!batch) return null
  return getNestedString(batch.released_reference_json, 'recipe_name')
    ?? getNestedString(getNestedRecord(batch.recipe_json, 'recipe_info'), 'recipe_name')
    ?? getPrimaryOutputName(batch.recipe_json)
    ?? asString(batch.product_name)
    ?? asString(batch.batch_label)
    ?? resolveBatchLabel(batch.meta)
}

export function resolveBatchDisplayName(batch: BatchRecipeSource | null | undefined): string | null {
  if (!batch) return null
  return asString(batch.product_name)
    ?? asString(batch.batch_label)
    ?? resolveBatchLabel(batch.meta)
    ?? resolveReleasedRecipeName(batch)
}

export function resolveBatchStyleName(
  batch: BatchRecipeSource | null | undefined,
  attr?: BatchRecipeAttrFallback | null,
): string | null {
  if (attr?.styleName) return asString(attr.styleName)
  if (!batch) return null
  const recipeInfo = getNestedRecord(batch.recipe_json, 'recipe_info')
  return getNestedString(batch.released_reference_json, 'style_name')
    ?? getNestedString(batch.released_reference_json, 'style')
    ?? getNestedString(recipeInfo, 'style_name')
    ?? getNestedString(recipeInfo, 'style')
    ?? resolveMetaString(batch.meta, 'style_name')
    ?? resolveMetaString(batch.meta, 'style')
}

export function resolveBatchBeerCategoryId(
  batch: BatchRecipeSource | null | undefined,
  attr?: BatchRecipeAttrFallback | null,
): string | null {
  if (attr?.beerCategoryId) return asString(attr.beerCategoryId)
  if (!batch) return null
  const recipeInfo = getNestedRecord(batch.recipe_json, 'recipe_info')
  return getNestedString(batch.released_reference_json, 'beer_category')
    ?? getNestedString(batch.released_reference_json, 'category')
    ?? getNestedString(batch.released_reference_json, 'recipe_category')
    ?? getNestedString(recipeInfo, 'beer_category')
    ?? getNestedString(recipeInfo, 'category')
    ?? getNestedString(recipeInfo, 'recipe_category')
    ?? resolveMetaString(batch.meta, 'beer_category')
    ?? resolveMetaString(batch.meta, 'category')
}

export function resolveBatchTargetAbv(
  batch: BatchRecipeSource | null | undefined,
  attr?: BatchRecipeAttrFallback | null,
): number | null {
  if (attr?.targetAbv != null) return asNumber(attr.targetAbv)
  if (!batch) return null
  const recipeInfo = getNestedRecord(batch.recipe_json, 'recipe_info')
  return getNestedNumber(batch.released_reference_json, 'actual_abv')
    ?? getNestedNumber(batch.released_reference_json, 'target_abv')
    ?? getNestedNumber(batch.released_reference_json, 'abv')
    ?? getNestedNumber(recipeInfo, 'actual_abv')
    ?? getNestedNumber(recipeInfo, 'target_abv')
    ?? getNestedNumber(recipeInfo, 'abv')
    ?? resolveMetaNumber(batch.meta, 'actual_abv')
    ?? resolveMetaNumber(batch.meta, 'target_abv')
}
