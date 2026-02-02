INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES
('batch_status', 'planned', 'system', NULL, '{
  "labels": { "ja": "計画済み", "en": "Planned" },
  "sort_order": 10,
  "is_terminal": false
}'::jsonb),

('batch_status', 'ready', 'system', NULL, '{
  "labels": { "ja": "準備完了", "en": "Ready" },
  "sort_order": 20,
  "is_terminal": false
}'::jsonb),

('batch_status', 'in_progress', 'system', NULL, '{
  "labels": { "ja": "製造中", "en": "In Progress" },
  "sort_order": 30,
  "is_terminal": false
}'::jsonb),

('batch_status', 'hold', 'system', NULL, '{
  "labels": { "ja": "保留", "en": "On Hold" },
  "sort_order": 40,
  "is_terminal": false
}'::jsonb),

('batch_status', 'finished', 'system', NULL, '{
  "labels": { "ja": "完了", "en": "Finished" },
  "sort_order": 50,
  "is_terminal": true
}'::jsonb);

CREATE OR REPLACE VIEW v_batch_status AS
SELECT
  def_key AS status_code,
  spec #>> '{labels,ja}' AS label_ja,
  spec #>> '{labels,en}' AS label_en,
  (spec->>'sort_order')::int AS sort_order,
  (spec->>'is_terminal')::boolean AS is_terminal
FROM registry_def
WHERE kind='batch_status' AND is_active=true;