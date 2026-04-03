# Tax Report Profile Page UI Specification

## Purpose
- Provide a tenant-scoped page to maintain the liquor-tax report profile used by the current monthly 酒税申告 flow.
- Store tenant tax-report settings in `tenants.meta.tax_report_profile`.
- Allow all tenant users to view the stored profile.
- Allow only tenant `owner` / `admin` users to edit and save the profile.

## Entry Points
- Sidebar -> `税務管理` -> `申告基本情報`
- Route: `/taxReportProfile`
- Route name: `TaxReportProfile`

## Users and Permissions
- Tenant user: view the current tenant tax-report profile in read-only mode.
- Tenant `owner` / `admin`: edit and save the current tenant tax-report profile.
- System admin: retain tenant-row access and may edit when operating in a tenant-scoped session.

## Data Source
- Table: `tenants`
- Row: current tenant id from session metadata
- JSON path:
  - `meta.tax_report_profile`
- Stored key naming:
  - use the relevant `ITdefinition.xsd` element names for the JSON keys written by the page
  - example: `ZEIMUSHO`, `NOZEISHA_ID`, `NOZEISHA_BANGO`, `KANPU_KINYUKIKAN`, `DAIHYO_NM`, `SEIZOJO_NM`, `DAIRI_NM`

## Page Layout
### Header
- Title: `酒税申告基本情報`
- Subtitle:
  - explains that the page stores tenant-level profile data used by liquor-tax reports
- Actions:
  - `更新`
  - `保存` only when the current user has edit permission
- Status badge:
  - `参照のみ` for normal tenant users
  - `編集可` for tenant admin/owner users

### Body
1. Tenant summary card
   - tenant name
   - tenant id
2. Tax bureau section
3. Taxpayer / company section
4. Refund account section
5. Representative section
6. Brewery section
7. Tax accountant section

## Field Groups
### Tax Bureau
- `税務署コード`
- `税務署名`

### Taxpayer / Company
- `利用者識別番号`
- `法人番号`
- `名称・氏名カナ`
- `名称・氏名`
- `郵便番号1`
- `郵便番号2`
- `住所カナ`
- `住所`
- `電話番号1`
- `電話番号2`
- `電話番号3`

### Refund Account
- `金融機関名`
- `金融機関種別コード`
- `支店名`
- `支店種別コード`
- `預金種別コード`
- `口座番号`

### Representative
- `名称・氏名カナ`
- `名称・氏名`
- `郵便番号1`
- `郵便番号2`
- `住所`
- `電話番号1`
- `電話番号2`
- `電話番号3`

### Brewery
- `名称・氏名カナ`
- `名称・氏名`
- `郵便番号1`
- `郵便番号2`
- `住所`
- `電話番号1`
- `電話番号2`
- `電話番号3`

### Tax Accountant
- `税理士名`
- `電話番号1`
- `電話番号2`
- `電話番号3`

## Behavior
- On page load:
  - resolve current tenant from session metadata
  - load the current tenant row from `tenants`
  - normalize `meta.tax_report_profile` into grouped form state keyed by the current IT definition names
  - accept older ad hoc key names for backward compatibility with already-saved tenant metadata
- For normal tenant users:
  - all form fields are disabled
  - save action is hidden or disabled
  - a read-only notice is shown
- For tenant `owner` / `admin` users:
  - form fields are editable
  - save updates `tenants.meta.tax_report_profile` using the IT definition element names
  - unrelated keys inside `tenants.meta` are preserved

## Non-Goals
- No full editor for every optional field defined by `ITdefinition.xsd`
- No automatic XML regeneration from this page in the same task
