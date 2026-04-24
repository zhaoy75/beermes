# Quantity and Money Rules

## Purpose
- Keep volume, tax, and money calculation behavior consistent across the beer application.
- Use this document as the durable source for product/domain rules.
- Keep implementation-process rules in `AGENTS.md`; `AGENTS.md` should only point here for these domain rules.

## Beer Volume
- Beer volume calculations should use milliliters as the canonical unit at calculation/output boundaries.
- Unit/package beer volume should be presented in mL.
- Total/aggregate beer volume should be presented in L.
- Always include the unit label when presenting beer volume.
- Official tax form previews and XML/export output should use the official unit required by the form/schema.

## Money and Tax Amounts
- Yen amounts should be integer values.
- Fractions smaller than 1 yen should be discarded before display or XML/export output.
- Do not round fractional yen up unless a specific tax/form rule explicitly requires rounding.
- For negative/refund intermediate amounts, discard fractional yen toward zero unless the relevant tax/form rule says otherwise.

## Current Compatibility Rules
- Existing storage and API fields such as `volume_l` and `qty_l` remain compatible until a schema/API migration is explicitly specified.
- When stored values are in L, convert through integer mL at calculation/output boundaries.
- Future storage can add `volume_ml`, but code should continue to tolerate existing `volume_l` data during migration.
