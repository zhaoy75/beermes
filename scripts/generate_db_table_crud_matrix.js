#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DDL_DIR = path.join(ROOT, 'DB', 'ddl');
const DOCS_DIR = path.join(ROOT, 'docs');
const CSV_PATH = path.join(DOCS_DIR, 'db_table_crud_matrix.csv');
const MD_PATH = path.join(DOCS_DIR, 'db_table_crud_matrix.md');
const TABLE_LEVEL_CSV_PATH = path.join(DOCS_DIR, 'db_table_level_crud_matrix.csv');
const TABLE_LEVEL_MD_PATH = path.join(DOCS_DIR, 'db_table_level_crud_matrix.md');

const PROCESS_COLUMNS = [
  { key: 'register_raw_material_type', label: 'register raw material type' },
  { key: 'register_raw_material', label: 'register raw material' },
  { key: 'buy_raw_material_and_register_movement', label: 'buy raw material and register the movement' },
  { key: 'use_raw_material_in_production_and_register_movement', label: 'use raw material in production and register the movement' },
  { key: 'return_raw_material_and_register_movement', label: 'return raw material and register the movement' },
  { key: 'dispose_raw_material_and_register_movement', label: 'dispose raw material and register the movement' },
  { key: 'output_finished_product_and_register_movement', label: 'output finished product and register the movement' },
  { key: 'package_finished_product_and_register_movement', label: 'package the finished product and register the movement' },
  { key: 'ship_finished_product_and_register_movement', label: 'ship the finished product and register the movement' },
  { key: 'return_finished_product_and_register_movement', label: 'return the finished product and register the movement' },
  { key: 'dispose_finished_product_and_register_movement', label: 'dispose the finished product and register the movement' },
  { key: 'unpack_finished_product_and_register_movement', label: 'unpacking the finished product and register the movement' },
  { key: 'maintain_inventory_raw_and_finished_product', label: 'maintain the inventory of raw material and finished product' },
  { key: 'maintain_recipe_and_link_raw_material', label: 'maintain the recipe and link to the raw material' },
  { key: 'maintain_equipment_and_link_raw_material', label: 'maintain the equipment and link to the raw material' },
  { key: 'maintain_master_data_and_related_links', label: 'maintain the master data and related links' },
];

const COMMON_REFERENCE_TABLES = new Set([
  'public.registry_def',
  'public.mst_uom',
  'public.mst_sites',
]);

function emptyProcessMap() {
  return Object.fromEntries(PROCESS_COLUMNS.map((process) => [process.key, '']));
}

const TABLE_PROCESS_MAP = buildTableProcessMap();

main();

function main() {
  const checkOnly = process.argv.includes('--check');
  const ddlFiles = fs.readdirSync(DDL_DIR)
    .filter((file) => file.endsWith('.sql'))
    .sort();

  const tables = parseDdlFiles(ddlFiles);
  const fieldRows = buildMatrixRows(tables);
  const tableRows = buildTableLevelRows(tables);
  const csv = buildCsv(fieldRows);
  const markdown = buildMarkdown(fieldRows, ddlFiles, tables);
  const tableLevelCsv = buildTableLevelCsv(tableRows);
  const tableLevelMarkdown = buildTableLevelMarkdown(tableRows, ddlFiles, tables);

  if (checkOnly) {
    const mismatches = [];
    compareOutput(CSV_PATH, csv, mismatches);
    compareOutput(MD_PATH, markdown, mismatches);
    compareOutput(TABLE_LEVEL_CSV_PATH, tableLevelCsv, mismatches);
    compareOutput(TABLE_LEVEL_MD_PATH, tableLevelMarkdown, mismatches);
    if (mismatches.length > 0) {
      mismatches.forEach((message) => console.error(message));
      process.exit(1);
    }
    console.log(`CRUD matrix artifacts are up to date (${fieldRows.length} field rows, ${tableRows.length} table rows).`);
    return;
  }

  fs.writeFileSync(CSV_PATH, csv, 'utf8');
  fs.writeFileSync(MD_PATH, markdown, 'utf8');
  fs.writeFileSync(TABLE_LEVEL_CSV_PATH, tableLevelCsv, 'utf8');
  fs.writeFileSync(TABLE_LEVEL_MD_PATH, tableLevelMarkdown, 'utf8');
  console.log(`Generated CRUD matrix artifacts with ${fieldRows.length} field rows and ${tableRows.length} table rows.`);
}

function compareOutput(filePath, expected, mismatches) {
  if (!fs.existsSync(filePath)) {
    mismatches.push(`Missing generated file: ${path.relative(ROOT, filePath)}`);
    return;
  }
  const actual = fs.readFileSync(filePath, 'utf8');
  if (actual !== expected) {
    mismatches.push(`Out-of-date generated file: ${path.relative(ROOT, filePath)}`);
  }
}

function parseDdlFiles(files) {
  const tables = new Map();

  files.forEach((file) => {
    const fullPath = path.join(DDL_DIR, file);
    const content = fs.readFileSync(fullPath, 'utf8');
    parseCreateTableStatements(content, file, tables);
    parseAlterAddColumnStatements(content, file, tables);
  });

  return tables;
}

function parseCreateTableStatements(content, file, tables) {
  const lines = content.split(/\r?\n/);

  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(/create table(?: if not exists)?\s+([^\s(]+)\s*\(/i);
    if (!match) continue;

    const tableName = normalizeTableName(match[1]);
    const table = ensureTable(tables, tableName);
    table.files.add(file);

    let depth = parenDelta(stripSqlLineComment(lines[index]));
    const pendingComments = [];

    for (index += 1; index < lines.length; index += 1) {
      const rawLine = lines[index];
      const codeLine = stripSqlLineComment(rawLine);
      depth += parenDelta(codeLine);

      const trimmedCode = codeLine.trim();
      if (depth <= 0 && (trimmedCode === ');' || trimmedCode === ')' || trimmedCode === ');')) break;

      parseColumnLine(rawLine, table, pendingComments);

      if (depth <= 0) break;
    }
  }
}

function parseAlterAddColumnStatements(content, file, tables) {
  const regex = /alter table\s+([^\s]+)\s+add column(?: if not exists)?\s+("?[A-Za-z_][A-Za-z0-9_]*"?)\s+(.+?);/ig;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const tableName = normalizeTableName(match[1]);
    const table = ensureTable(tables, tableName);
    table.files.add(file);
    upsertColumn(table, match[2], match[3], '', [], file);
  }
}

function parseColumnLine(rawLine, table, pendingComments) {
  const trimmed = rawLine.trim();
  if (!trimmed) return;

  if (trimmed.startsWith('--')) {
    pendingComments.push(cleanComment(trimmed));
    return;
  }

  const [codePart, inlineComment = ''] = splitSqlLineComment(rawLine);
  const code = codePart.trim();
  if (!code) return;
  if (/^\)/.test(code)) {
    pendingComments.length = 0;
    return;
  }
  if (/^(constraint|primary key|foreign key|unique|check|exclude|references|on|or|and|create|alter|drop)\b/i.test(code)) {
    pendingComments.length = 0;
    return;
  }

  const match = code.match(/^("?[A-Za-z_][A-Za-z0-9_]*"?)\s+(.+?)(?:,)?$/);
  if (!match) {
    pendingComments.length = 0;
    return;
  }

  const extractedType = extractColumnType(match[2]);
  if (!isLikelyColumnType(extractedType)) {
    pendingComments.length = 0;
    return;
  }

  upsertColumn(table, match[1], match[2], inlineComment, pendingComments, null);
  pendingComments.length = 0;
}

function upsertColumn(table, rawColumnName, definition, inlineComment, pendingComments, file) {
  const columnName = unquoteIdentifier(rawColumnName);
  const type = extractColumnType(definition);
  const references = extractReference(definition);
  const isPrimary = /\bprimary\s+key\b/i.test(definition);
  const commentParts = [...pendingComments];
  if (inlineComment && inlineComment.trim()) commentParts.push(cleanComment(inlineComment));

  const description = inferDescription({
    name: columnName,
    type,
    isPrimary,
    references,
    comments: commentParts,
  });

  table.columns.set(columnName, {
    name: columnName,
    type,
    description,
    isPrimary,
    references,
    order: table.columns.size,
    file: file || null,
  });
}

function ensureTable(tables, tableName) {
  if (!tables.has(tableName)) {
    tables.set(tableName, {
      name: tableName,
      files: new Set(),
      columns: new Map(),
    });
  }
  return tables.get(tableName);
}

function normalizeTableName(rawName) {
  const cleaned = rawName.replace(/["`]/g, '');
  if (cleaned.includes('.')) return cleaned;
  return `public.${cleaned}`;
}

function unquoteIdentifier(value) {
  return value.replace(/["`]/g, '');
}

function splitSqlLineComment(line) {
  const index = line.indexOf('--');
  if (index === -1) return [line, ''];
  return [line.slice(0, index), line.slice(index + 2)];
}

function stripSqlLineComment(line) {
  return splitSqlLineComment(line)[0];
}

function parenDelta(input) {
  let depth = 0;
  for (const char of input) {
    if (char === '(') depth += 1;
    else if (char === ')') depth -= 1;
  }
  return depth;
}

function extractColumnType(definition) {
  const upper = ` ${definition.toUpperCase()} `;
  const stopTokens = [
    ' GENERATED ',
    ' NOT ',
    ' NULL ',
    ' DEFAULT ',
    ' PRIMARY ',
    ' REFERENCES ',
    ' CONSTRAINT ',
    ' CHECK ',
    ' UNIQUE ',
    ' COLLATE ',
  ];
  let end = definition.length;
  stopTokens.forEach((token) => {
    const index = upper.indexOf(token);
    if (index > 0 && index - 1 < end) end = index - 1;
  });
  return definition.slice(0, end).trim().replace(/\s+/g, ' ');
}

function extractReference(definition) {
  const match = definition.match(/\breferences\s+([^\s(,]+)/i);
  if (!match) return null;
  return normalizeTableName(match[1]);
}

function isLikelyColumnType(type) {
  if (!type) return false;
  const normalized = type.trim();
  if (!normalized) return false;

  const firstToken = normalized.split(/\s+/)[0].toUpperCase();
  if (['IN', 'IS', 'OR', 'AND', 'ON', '=', '<', '>', '<=', '>='].includes(firstToken)) {
    return false;
  }

  return true;
}

function cleanComment(comment) {
  return comment
    .replace(/^--\s*/, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function inferDescription({ name, type, isPrimary, references, comments }) {
  const comment = comments.map(cleanComment).filter(Boolean).join(' ');
  if (comment) return comment;
  if (isPrimary) return 'Primary key';
  if (name === 'tenant_id') return 'Tenant scope';
  if (references) return `Reference to ${references}`;
  if (name === 'meta' || name === 'meta_json' || /meta/.test(name)) return 'Free-form metadata JSON';
  if (name === 'created_at') return 'Created timestamp';
  if (name === 'updated_at') return 'Updated timestamp';
  if (name === 'created_by') return 'Created by user';
  if (name === 'updated_by') return 'Updated by user';
  if (name === 'status') return 'Status';
  if (name.endsWith('_id')) return `${humanize(name.slice(0, -3))} reference id`;
  if (name.endsWith('_code')) return `${humanize(name.slice(0, -5))} code`;
  if (name.endsWith('_name')) return `${humanize(name.slice(0, -5))} name`;
  if (name.endsWith('_json')) return `${humanize(name.slice(0, -5))} JSON payload`;
  if (name.endsWith('_at')) return `${humanize(name)} timestamp`;
  if (name === 'id') return 'Identifier';
  if (type.includes('json')) return `${humanize(name)} JSON data`;
  return humanize(name);
}

function humanize(value) {
  return value
    .replace(/_/g, ' ')
    .replace(/\b([a-z])/g, (match) => match.toUpperCase());
}

function buildMatrixRows(tables) {
  return Array.from(tables.values())
    .sort((a, b) => a.name.localeCompare(b.name))
    .flatMap((table) => {
      const fieldRows = Array.from(table.columns.values())
        .sort((a, b) => a.order - b.order)
        .map((column) => buildFieldRow(table.name, column));
      return fieldRows;
    });
}

function buildFieldRow(tableName, column) {
  const tableMap = TABLE_PROCESS_MAP[tableName] || emptyProcessMap();
  const row = {
    'table name': tableName,
    'field name': column.name,
    'field type': column.type,
    description: column.description,
  };

  PROCESS_COLUMNS.forEach((process) => {
    row[process.label] = adjustCrudForField(tableMap[process.key] || '', column);
  });

  return row;
}

function buildTableLevelRows(tables) {
  return Array.from(tables.values())
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((table) => buildTableLevelRow(table));
}

function buildTableLevelRow(table) {
  const tableMap = TABLE_PROCESS_MAP[table.name] || emptyProcessMap();
  const row = {
    'table name': table.name,
    'table description': inferTableDescription(table),
  };

  PROCESS_COLUMNS.forEach((process) => {
    row[process.label] = normalizeCrudCode(tableMap[process.key] || '');
  });

  return row;
}

function adjustCrudForField(code, column) {
  if (!code) return '';
  const letters = new Set(normalizeCrudCode(code).split(''));

  if (column.isPrimary || column.name === 'id') {
    letters.delete('U');
  }
  if (column.name === 'tenant_id') {
    letters.delete('U');
  }
  if (column.name === 'created_at' || column.name === 'created_by') {
    letters.delete('U');
  }

  return ['C', 'R', 'U', 'D'].filter((letter) => letters.has(letter)).join('');
}

function normalizeCrudCode(code) {
  return ['C', 'R', 'U', 'D']
    .filter((letter) => String(code || '').toUpperCase().includes(letter))
    .join('');
}

function buildCsv(rows) {
  const headers = [
    'table name',
    'field name',
    'field type',
    'description',
    ...PROCESS_COLUMNS.map((process) => process.label),
  ];

  const lines = [headers, ...rows.map((row) => headers.map((header) => row[header] ?? ''))]
    .map((cells) => cells.map(csvEscape).join(','));

  return `${lines.join('\n')}\n`;
}

function csvEscape(value) {
  const normalized = String(value ?? '');
  return `"${normalized.replace(/"/g, '""')}"`;
}

function buildMarkdown(rows, ddlFiles, tables) {
  const tableCount = tables.size;
  const fieldCount = rows.length;
  const processLines = PROCESS_COLUMNS.map((process) => `- \`${process.label}\``).join('\n');

  return [
    '# DB Table CRUD Matrix',
    '',
    'Generated by `node scripts/generate_db_table_crud_matrix.js`.',
    '',
    '## Scope',
    `- DDL files parsed: ${ddlFiles.length}`,
    `- Tables included: ${tableCount}`,
    `- Field rows included: ${fieldCount}`,
    '- Rows represent table fields only. Views, enum types, policies, triggers, and functions are excluded.',
    '',
    '## CRUD Legend',
    '- `C`: create',
    '- `R`: read',
    '- `U`: update',
    '- `D`: delete',
    '',
    '## Process Columns',
    processLines,
    '',
    '## Mapping Rules',
    '- This is a design-oriented CRUD matrix, not a direct runtime audit log.',
    '- Table rows are generated from `DB/ddl` table definitions and `ADD COLUMN` statements.',
    '- Duplicate table definitions are merged by final normalized table name.',
    '- Field descriptions come from inline SQL comments when available; otherwise they are inferred from names and FK/PK hints.',
    '- Process CRUD codes are primarily table-driven and then lightly adjusted for obvious system-managed fields such as `id`, `tenant_id`, and `created_at`.',
    '- The user-provided final truncated process label is normalized to `maintain the master data and related links`.',
    '',
    '## Output',
    `- CSV data: [db_table_crud_matrix.csv](/Users/zhao/dev/other/beer/docs/db_table_crud_matrix.csv)`,
    `- Table-level CSV data: [db_table_level_crud_matrix.csv](/Users/zhao/dev/other/beer/docs/db_table_level_crud_matrix.csv)`,
    '',
  ].join('\n');
}

function buildTableLevelCsv(rows) {
  const headers = [
    'table name',
    'table description',
    ...PROCESS_COLUMNS.map((process) => process.label),
  ];

  const lines = [headers, ...rows.map((row) => headers.map((header) => row[header] ?? ''))]
    .map((cells) => cells.map(csvEscape).join(','));

  return `${lines.join('\n')}\n`;
}

function buildTableLevelMarkdown(rows, ddlFiles, tables) {
  const processLines = PROCESS_COLUMNS.map((process) => `- \`${process.label}\``).join('\n');

  return [
    '# DB Table Level CRUD Matrix',
    '',
    'Generated by `node scripts/generate_db_table_crud_matrix.js`.',
    '',
    '## Scope',
    `- DDL files parsed: ${ddlFiles.length}`,
    `- Tables included: ${tables.size}`,
    `- Table rows included: ${rows.length}`,
    '- Rows represent normalized tables only. CRUD codes are aggregated at table level.',
    '',
    '## CRUD Legend',
    '- `C`: create',
    '- `R`: read',
    '- `U`: update',
    '- `D`: delete',
    '',
    '## Process Columns',
    processLines,
    '',
    '## Mapping Rules',
    '- This is a design-oriented CRUD matrix, not a direct runtime audit log.',
    '- Table rows are generated from `DB/ddl` table definitions and `ADD COLUMN` statements.',
    '- Duplicate table definitions are merged by final normalized table name.',
    '- Table-level CRUD codes come from the same design-time process mapping used by the field-level matrix.',
    '',
    '## Output',
    `- CSV data: [db_table_level_crud_matrix.csv](/Users/zhao/dev/other/beer/docs/db_table_level_crud_matrix.csv)`,
    '',
  ].join('\n');
}

function inferTableDescription(table) {
  const sourceFiles = Array.from(table.files).sort();
  const sourceNote = sourceFiles.length > 0 ? `source: ${sourceFiles.join(', ')}` : 'source: unknown';
  return `${table.columns.size} fields; ${sourceNote}`;
}

function buildTableProcessMap() {
  const map = {};

  const apply = (tables, updates) => {
    tables.forEach((table) => {
      if (!map[table]) map[table] = emptyProcessMap();
      Object.entries(updates).forEach(([key, value]) => {
        map[table][key] = value;
      });
    });
  };

  apply(['public.type_def'], {
    register_raw_material_type: 'CRUD',
    register_raw_material: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['public.type_closure'], {
    register_raw_material_type: 'CRD',
    register_raw_material: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRD',
  });

  apply(['public.attr_def', 'public.attr_set', 'public.attr_set_rule', 'public.entity_attr_set'], {
    register_raw_material_type: 'R',
    register_raw_material: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['public.entity_attr'], {
    register_raw_material: 'CRU',
    maintain_recipe_and_link_raw_material: 'CRU',
    maintain_equipment_and_link_raw_material: 'CRU',
  });

  apply(['public.registry_def'], {
    register_raw_material_type: 'R',
    register_raw_material: 'R',
    buy_raw_material_and_register_movement: 'R',
    use_raw_material_in_production_and_register_movement: 'R',
    return_raw_material_and_register_movement: 'R',
    dispose_raw_material_and_register_movement: 'R',
    output_finished_product_and_register_movement: 'R',
    package_finished_product_and_register_movement: 'R',
    ship_finished_product_and_register_movement: 'R',
    return_finished_product_and_register_movement: 'R',
    dispose_finished_product_and_register_movement: 'R',
    unpack_finished_product_and_register_movement: 'R',
    maintain_inventory_raw_and_finished_product: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['public.mst_uom', 'public.mst_sites'], {
    register_raw_material: 'R',
    buy_raw_material_and_register_movement: 'R',
    use_raw_material_in_production_and_register_movement: 'R',
    return_raw_material_and_register_movement: 'R',
    dispose_raw_material_and_register_movement: 'R',
    output_finished_product_and_register_movement: 'R',
    package_finished_product_and_register_movement: 'R',
    ship_finished_product_and_register_movement: 'R',
    return_finished_product_and_register_movement: 'R',
    dispose_finished_product_and_register_movement: 'R',
    unpack_finished_product_and_register_movement: 'R',
    maintain_inventory_raw_and_finished_product: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['public.mst_package'], {
    package_finished_product_and_register_movement: 'R',
    ship_finished_product_and_register_movement: 'R',
    return_finished_product_and_register_movement: 'R',
    dispose_finished_product_and_register_movement: 'R',
    unpack_finished_product_and_register_movement: 'R',
    maintain_inventory_raw_and_finished_product: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['mes.mst_material'], {
    register_raw_material: 'CRUD',
    buy_raw_material_and_register_movement: 'R',
    use_raw_material_in_production_and_register_movement: 'R',
    return_raw_material_and_register_movement: 'R',
    dispose_raw_material_and_register_movement: 'R',
    maintain_inventory_raw_and_finished_product: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'R',
  });

  apply(['public.mst_equipment', 'public.mst_equipment_tank'], {
    use_raw_material_in_production_and_register_movement: 'R',
    package_finished_product_and_register_movement: 'R',
    maintain_equipment_and_link_raw_material: 'CRUD',
    maintain_master_data_and_related_links: 'R',
  });

  apply(['mes.mst_equipment_template'], {
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['mes.mst_recipe', 'mes.mst_recipe_version', 'mes.mst_step_template', 'mes.mst_parameter_def', 'mes.mst_quality_check', 'mes.recipe_approval_flow_def', 'mes.recipe_approval_event', 'mes.recipe_change_history', 'public.mes_recipes', 'public.mes_recipe_steps'], {
    use_raw_material_in_production_and_register_movement: 'R',
    output_finished_product_and_register_movement: 'R',
    maintain_recipe_and_link_raw_material: 'CRUD',
  });

  apply(['public.mes_batches'], {
    use_raw_material_in_production_and_register_movement: 'RU',
    output_finished_product_and_register_movement: 'RU',
    package_finished_product_and_register_movement: 'R',
    ship_finished_product_and_register_movement: 'R',
    return_finished_product_and_register_movement: 'R',
    dispose_finished_product_and_register_movement: 'R',
    unpack_finished_product_and_register_movement: 'R',
    maintain_inventory_raw_and_finished_product: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
  });

  apply(['public.mes_batch_relation'], {
    output_finished_product_and_register_movement: 'CRU',
    package_finished_product_and_register_movement: 'CRU',
    return_finished_product_and_register_movement: 'CRU',
    unpack_finished_product_and_register_movement: 'CRU',
    maintain_inventory_raw_and_finished_product: 'R',
  });

  apply(['mes.batch_step', 'public.mes_batch_steps', 'mes.batch_material_plan', 'mes.batch_material_actual', 'mes.batch_equipment_assignment', 'mes.batch_execution_log', 'mes.batch_deviation'], {
    use_raw_material_in_production_and_register_movement: 'CRU',
    output_finished_product_and_register_movement: 'RU',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
  });

  apply(['public.inv_movements', 'public.inv_movement_lines'], {
    buy_raw_material_and_register_movement: 'CR',
    use_raw_material_in_production_and_register_movement: 'CR',
    return_raw_material_and_register_movement: 'CR',
    dispose_raw_material_and_register_movement: 'CR',
    output_finished_product_and_register_movement: 'CR',
    package_finished_product_and_register_movement: 'CR',
    ship_finished_product_and_register_movement: 'CR',
    return_finished_product_and_register_movement: 'CR',
    dispose_finished_product_and_register_movement: 'CR',
    unpack_finished_product_and_register_movement: 'CR',
    maintain_inventory_raw_and_finished_product: 'R',
  });

  apply(['public.lot'], {
    buy_raw_material_and_register_movement: 'CR',
    use_raw_material_in_production_and_register_movement: 'RU',
    return_raw_material_and_register_movement: 'CRU',
    dispose_raw_material_and_register_movement: 'RU',
    output_finished_product_and_register_movement: 'CR',
    package_finished_product_and_register_movement: 'CRU',
    ship_finished_product_and_register_movement: 'RU',
    return_finished_product_and_register_movement: 'CRU',
    dispose_finished_product_and_register_movement: 'RU',
    unpack_finished_product_and_register_movement: 'CRU',
    maintain_inventory_raw_and_finished_product: 'RU',
  });

  apply(['public.lot_edge'], {
    buy_raw_material_and_register_movement: 'CR',
    use_raw_material_in_production_and_register_movement: 'CR',
    return_raw_material_and_register_movement: 'CR',
    dispose_raw_material_and_register_movement: 'CR',
    output_finished_product_and_register_movement: 'CR',
    package_finished_product_and_register_movement: 'CR',
    ship_finished_product_and_register_movement: 'CR',
    return_finished_product_and_register_movement: 'CR',
    dispose_finished_product_and_register_movement: 'CR',
    unpack_finished_product_and_register_movement: 'CR',
    maintain_inventory_raw_and_finished_product: 'R',
  });

  apply(['public.inv_inventory'], {
    buy_raw_material_and_register_movement: 'CRU',
    use_raw_material_in_production_and_register_movement: 'RU',
    return_raw_material_and_register_movement: 'CRU',
    dispose_raw_material_and_register_movement: 'RU',
    output_finished_product_and_register_movement: 'CRU',
    package_finished_product_and_register_movement: 'CRU',
    ship_finished_product_and_register_movement: 'RU',
    return_finished_product_and_register_movement: 'CRU',
    dispose_finished_product_and_register_movement: 'RU',
    unpack_finished_product_and_register_movement: 'CRU',
    maintain_inventory_raw_and_finished_product: 'CRUD',
  });

  apply(['public.industry'], {
    register_raw_material_type: 'R',
    register_raw_material: 'R',
    maintain_recipe_and_link_raw_material: 'R',
    maintain_equipment_and_link_raw_material: 'R',
    maintain_master_data_and_related_links: 'CRUD',
  });

  apply(['public.tax_reports'], {
    ship_finished_product_and_register_movement: 'R',
    return_finished_product_and_register_movement: 'R',
    dispose_finished_product_and_register_movement: 'R',
  });

  apply(['public.tenants', 'public.tenant_members', 'public.tenant_invitations'], {});

  Object.keys(map).forEach((tableName) => {
    COMMON_REFERENCE_TABLES.forEach((referenceTable) => {
      if (!map[referenceTable]) return;
      if (tableName === referenceTable) return;
    });
  });

  return map;
}
