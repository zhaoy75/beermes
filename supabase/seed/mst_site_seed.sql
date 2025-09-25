-- ブルワリーの主要な拠点を対象テナント向けに登録するシードデータ。
-- mst_site_types のレコードが存在し、tenant_id は auth.jwt() のデフォルトで補完される前提。

with site_types as (
  select code, id
  from public.mst_site_types
),
raw_sites as (
  select *
  from (values
    ('BREWERY_MAIN',    'サンライズブルーイング本社',              'brewery',       null,
      '{"address1":"ホップ通り1-2-3","ward":"墨田区","city":"東京都","prefecture":"東京都","postal_code":"130-0001","country":"JP"}'::jsonb,
      '{"phone":"+81-3-1234-5678","email":"hq@sunrisebrew.jp"}'::jsonb,
      '主力の製造拠点で、ブルーハウスとタップルームを併設。',
      true),

    ('BREWERY_PILOT',   'パイロットブルワリー兼ラボ',            'brewery',       'BREWERY_MAIN',
      '{"address1":"ホップ通り1-2-3","floor":"R&D アネックス","city":"東京都","prefecture":"東京都","postal_code":"130-0001","country":"JP"}'::jsonb,
      '{"phone":"+81-3-9876-5432","email":"pilot@sunrisebrew.jp"}'::jsonb,
      '試験醸造用の少量バッチ設備を備えた開発拠点。',
      true),

    ('WAREHOUSE_COLD',  '低温保管倉庫',                          'warehouse',     'BREWERY_MAIN',
      '{"address1":"チルレーン48","district":"江東区","city":"東京都","prefecture":"東京都","postal_code":"135-0007","country":"JP"}'::jsonb,
      '{"phone":"+81-3-2222-8100","contact":"中村 玲"}'::jsonb,
      '完成品と酵母を管理する冷蔵倉庫。',
      true),

    ('WAREHOUSE_DRY',   '常温資材倉庫',                          'warehouse',     'BREWERY_MAIN',
      '{"address1":"グレイン埠頭220","city":"横浜市","prefecture":"神奈川県","postal_code":"231-0001","country":"JP"}'::jsonb,
      '{"phone":"+81-45-210-3344","contact":"新井 拓海"}'::jsonb,
      '麦芽・ホップ・資材を保管する常温倉庫。',
      true),

    ('SUPPLIER_MALT',   '関東モルトサプライ株式会社',            'supplier',      null,
      '{"address1":"バーリーロード15","city":"さいたま市","prefecture":"埼玉県","postal_code":"330-0845","country":"JP"}'::jsonb,
      '{"phone":"+81-48-765-1100","email":"orders@kantomalt.jp"}'::jsonb,
      '主要なベースモルトの仕入先。',
      true),

    ('SUPPLIER_HOPS',   'パックノースホップ協同組合',            'supplier',      null,
      '{"address1":"カスケード通り902","city":"ヤキマ","state":"ワシントン州","postal_code":"98901","country":"US"}'::jsonb,
      '{"phone":"+1-509-555-2211","email":"export@pacnorthhops.com"}'::jsonb,
      'アロマ系ホップを供給する米国サプライヤー。',
      true),

    ('CUSTOMER_TAP',    'ダウンタウンタップルーム',              'customer',      null,
      '{"address1":"クラフト横丁9","city":"東京都","prefecture":"東京都","postal_code":"104-0061","country":"JP"}'::jsonb,
      '{"phone":"+81-3-6500-7788","contact":"鈴木 美香"}'::jsonb,
      '東京駅近くの旗艦タップルーム顧客。',
      true),

    ('CUSTOMER_DIST',   'メトロビバレッジディストリビューション','customer',      null,
      '{"address1":"ロジスティクスパーク2-19","city":"川崎市","prefecture":"神奈川県","postal_code":"210-0833","country":"JP"}'::jsonb,
      '{"phone":"+81-44-200-4422","email":"purchasing@metrobev.jp"}'::jsonb,
      '地域卸売のディストリビューター。',
      true),

    ('RECYCLER_WASTE',  'エコウェイストリサイクルパートナーズ','recycler',      null,
      '{"address1":"グリーンループ88","city":"千葉市","prefecture":"千葉県","postal_code":"260-0013","country":"JP"}'::jsonb,
      '{"phone":"+81-43-330-5566","email":"dispatch@ecowaste.jp"}'::jsonb,
      '搾りかすと資材のリサイクル業者。',
      true),

    ('TAX_KANTO',       '関東信越国税局',                        'tax_authority', null,
      '{"address1":"霞が関3-5-1","city":"東京都","prefecture":"東京都","postal_code":"100-8978","country":"JP"}'::jsonb,
      '{"phone":"+81-3-3581-4111"}'::jsonb,
      '管轄の税務当局窓口。',
      true)
  ) as t(code, name, site_type_code, parent_code, address_json, contact_json, notes, active)
)
insert into public.mst_sites (code, name, site_type_id, parent_site_id, address, contact, notes, active)
select
  r.code,
  r.name,
  st.id,
  parent_existing.id,
  r.address_json,
  r.contact_json,
  r.notes,
  r.active
from raw_sites r
join site_types st on st.code = r.site_type_code
left join public.mst_sites parent_existing on parent_existing.code = r.parent_code
on conflict (tenant_id, code) do update set
  name = excluded.name,
  site_type_id = excluded.site_type_id,
  parent_site_id = excluded.parent_site_id,
  address = excluded.address,
  contact = excluded.contact,
  notes = excluded.notes,
  active = excluded.active;

-- 親サイトが存在するタイミングで親子関係を再設定する。
update public.mst_sites s
set parent_site_id = parent.id
from (values
  ('BREWERY_PILOT',  'BREWERY_MAIN'),
  ('WAREHOUSE_COLD', 'BREWERY_MAIN'),
  ('WAREHOUSE_DRY',  'BREWERY_MAIN')
) as rel(child_code, parent_code)
join public.mst_sites parent on parent.code = rel.parent_code
where s.code = rel.child_code
  and s.parent_site_id is distinct from parent.id;
