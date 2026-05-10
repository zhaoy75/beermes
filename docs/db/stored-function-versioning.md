# Stored Function Versioning

- Every `create or replace function` in `DB/function/*.sql` must have a matching version comment immediately after the function body:

```sql
comment on function public.product_move(jsonb) is '{"version":1}';
```

- New function: start at `{"version":1}`.
- Existing function: increment by 1 when behavior, validation, side effects, return payload, volatility, security mode, or signature changes.
- Whitespace/comment-only edits: keep the version unchanged.
- Use PostgreSQL identity argument types only; omit parameter names and defaults.
