-- Allow duplicate batch codes in public.mes_batches.
--
-- `mes_batches.id` is the canonical identifier. `batch_code` is a
-- business-visible display/search label and can be reused.

ALTER TABLE public.mes_batches
  DROP CONSTRAINT IF EXISTS mes_batches_tenant_id_batch_code_key;

CREATE INDEX IF NOT EXISTS idx_mes_batches_tenant_batch_code
  ON public.mes_batches (tenant_id, batch_code);
