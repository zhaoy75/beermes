# AGENTS.md

## Core workflow
- Before changing code, always check whether a spec exists.
- If no spec exists, create or update `specs/current-task.md` first.
- Do not implement until the spec is written.
- Treat `specs/current-task.md` as the source of truth for scope.

## Required process
1. Read relevant code and docs.
2. Create or update `specs/current-task.md` with:
   - goal
   - scope
   - non-goals
   - affected files
   - data model / API changes
   - validation plan
3. Show the planned file changes briefly.
4. Only then modify code.
5. After implementation, update the spec with final decisions.

## Coding rules
- Follow existing project style and architecture.
- Keep diffs small and scoped.
- Do not refactor unrelated code.
- Add tests for changed behavior where feasible.
- Run the required checks before finishing.

## Domain rules
- Follow durable quantity and money rules in `docs/domain/quantity-and-money.md`.

## Validation
- Run:
  - unit tests
  - lint
  - type-check
- If a check fails, fix it before ending.

## Output style
- Summarize:
  - what spec was created/updated
  - what code changed
  - what validations ran
  - any remaining risks

## Other rules
- when output excel file
  - always use ms932 encode
  - always add lines to table.
  - table header cell background will be gray
  - table header font should be bold
