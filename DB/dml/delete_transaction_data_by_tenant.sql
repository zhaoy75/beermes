-- Delete transaction data for one tenant.
--
-- Usage:
--   1. Replace the all-zero UUID below with the target tenant id.
--   2. Review the NOTICE row counts after execution.
--   3. Run with a role that can delete the target tenant rows if RLS applies.
--
-- This intentionally keeps tenant master/configuration data:
-- tenants, tenant_members, mst_sites, mst_package, mst_equipment, mst_uom,
-- recipes, registry_def, attr_def, attr_set, type_def, and industry rows.
--
-- This does not delete Supabase Storage objects referenced by tax report file metadata.

begin;

do $$
declare
  v_tenant_id uuid := '2a231822-aa8d-452a-aa5f-9f5e4293cdaa'::uuid;
  v_table_name text;
  v_table_regclass regclass;
  v_deleted integer;
  v_transaction_tables text[] := array[
    -- Tax report references must go before tax reports and movements.
    'public.tax_report_movement_refs',
    'public.tax_reports',

    -- MES execution children must go before public.mes_batches.
    'mes.batch_equipment_assignment',
    'mes.batch_material_actual',
    'mes.batch_material_plan',
    'mes.batch_execution_log',
    'mes.batch_deviation',
    'mes.equipment_reservation',
    'mes.batch_step',
    'public.mes_batch_steps',
    'public.mes_batch_relation',

    -- Lot and movement graph children must go before lots and movements.
    'public.lot_edge',
    'public.inv_movement_lines',
    'public.inv_movements',
    'public.inv_inventory'
  ];
  v_parent_tables text[] := array[
    'public.lot',
    'public.mes_batches'
  ];
begin
  if v_tenant_id = '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'Replace v_tenant_id with the target tenant id before running this script.';
  end if;

  raise notice 'Deleting transaction data for tenant_id=%', v_tenant_id;

  foreach v_table_name in array v_transaction_tables loop
    v_table_regclass := to_regclass(v_table_name);

    if v_table_regclass is null then
      raise notice 'Skipped %, table does not exist', v_table_name;
    else
      execute format('delete from %s where tenant_id = $1', v_table_regclass)
        using v_tenant_id;
      get diagnostics v_deleted = row_count;
      raise notice 'Deleted % row(s) from %', v_deleted, v_table_name;
    end if;
  end loop;

  -- Entity attributes do not have foreign keys to batch/lot parents, so clean
  -- transaction entity attributes explicitly before deleting the parent rows.
  v_table_regclass := to_regclass('public.entity_attr');
  if v_table_regclass is null then
    raise notice 'Skipped public.entity_attr, table does not exist';
  else
    delete from public.entity_attr
    where tenant_id = v_tenant_id
      and entity_type in ('batch', 'lot');
    get diagnostics v_deleted = row_count;
    raise notice 'Deleted % row(s) from public.entity_attr', v_deleted;
  end if;

  v_table_regclass := to_regclass('public.entity_attr_set');
  if v_table_regclass is null then
    raise notice 'Skipped public.entity_attr_set, table does not exist';
  else
    delete from public.entity_attr_set
    where tenant_id = v_tenant_id
      and entity_type in ('batch', 'lot');
    get diagnostics v_deleted = row_count;
    raise notice 'Deleted % row(s) from public.entity_attr_set', v_deleted;
  end if;

  foreach v_table_name in array v_parent_tables loop
    v_table_regclass := to_regclass(v_table_name);

    if v_table_regclass is null then
      raise notice 'Skipped %, table does not exist', v_table_name;
    else
      execute format('delete from %s where tenant_id = $1', v_table_regclass)
        using v_tenant_id;
      get diagnostics v_deleted = row_count;
      raise notice 'Deleted % row(s) from %', v_deleted, v_table_name;
    end if;
  end loop;

  raise notice 'Transaction data delete completed for tenant_id=%', v_tenant_id;
end $$;

commit;
