## Purpose
- Edit mst_site


## Entry Points
マスターメンテナンス　→ サイト管理

## Users and Permissions
- Tenant User: edit all mst_iste information

## Page Layout
### Header: サイト管理
- Title: サイト管理

### Body: 
- There are 2 panel
  2.1 site tree panel (left side) with tree panel and add/delete button
  2.2 site information edit panel
  
### Modal Dialog
  address input dialog (common dialog can be used in other page)

## Field Definitions
### site tree panel (left side panel)
    search area with site code and site type (registry_def with kind "site_type")
    site tree (tree node name = site name(site code))
      for site tree there should be  a virtual root node named サイトルート
    add/delete button 

### site information edit panel
    code
    name
    site_type_id (dropdown egistry_def with kind "site_type")
    address area (edit button to a common address input dialog using rule define in registry_def with kind "address_rule")
    notes

## Action
  ### add button
  ### delete button 
    delete descent tree node

## Business Rules

## Data Handling
- site information stored in mst_sites
- site_type stored in registry_def table with kind "site_type"

## other
- this page should be multilanguage (english and japanese)