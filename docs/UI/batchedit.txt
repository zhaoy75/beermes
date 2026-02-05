please make or rewrite batchedit.vue page according to following specification


I change mes_batch table, please modify the ddl first and then modify バッチ管理 page accordingly

1. delete following field 
  vessel_id
  target_volume_l
  actual_og
  actual_fg
  actual_abv
  actual_srm
2. add following field 
  batch_label as varchar
  scale_factor as numeric
  recipe_json as jsonb
  planned_end as timestamp
  actual_start as timestamp
  actual_end as timestamp
  kpi as jsonb    
  material_consumption as jsonb 
  output_actual as jsonb
3. kpi jsonb should include following kpi
   - volume_l
   - og
   - fg
   - abv
   - srm
   - ibu
  the format should be like {[{"id": "***", "name": "***", uom: "", "planed": ***,  "actual":  ]}
4. material_consumption jsonb should include planned and actual consumption of each material used in the batch
   material_consumption": [
      {
        "material_id": "MALT_PILSNER",
        "planned_qty": 200,
        "actual_qty": 203.5,
        "uom": "kg",
        "variance": 3.5,
        "batches": [
          { "batch_id": "BATCH-MALT-20260110-01", "qty": 203.5, "uom": "kg" }
        ]
      },
5. output_actual as jsonb should include actual output of the batch with disposition information
          {
            "material_id": "BEER_GREEN",
            "qty": 682,
            "uom": "L",
            "type": "intermediate",
            "disposition": {
              "type": "transfer",
              "to": [
                {
                  "batch_id": "BATCH-20260123-0001",
                  "qty": 682,
                  "uom": "kg"
                }
              ]
            }
          },


kpi in バッチ管理　should following format definition in registry_def table.
1. format definition stored in registry_def table with kind =kpi_definition	and def_key=beer_production_kpi
2. format definition should be like below
{
    "kpi_meta": [
      {
        "id": "tax_category_code",
        "name": "製品種類",
        "uom": "",
        "datasource": "registry_def",
        "search_key_flg": true,
      },
      {
        "id": "volume",
        "name": "生産量",
        "uom": "l"
      },
      {
        "id": "abv",
        "name": "ABV",
        "uom": ""
      },
      {
        "id": "og",
        "name": "OG",
        "uom": ""
      },
      {
        "id": "fg",
        "name": "FG",
        "uom": ""
      },
      {
        "id": "srm",
        "name": "SRM",
        "uom": ""
      },
      {
        "id": "ibu",
        "name": "IBU",
        "uom": ""
      }
    ]
  }
3. each kpi in mes_batch.kpi jsonb should follow the kpi_meta definition
4. when creating or editing a batch, the kpi section should be dynamically generated based on the kpi_meta definition
5. if search_key_flg is true, the kpi should be included in the search section of バッチ管理 page and shown in the search condition section



- in the material consumption section, please find a way to input material consumption for each material class separately
  - material class is defined in registry_def table with kind=material_class AND category='原材料'
- the output should be a separate section showing the actual output of the batch with disposition information
  - disposition type include transfer to another batch, transfer to warehouse, disposal
  - if disposition type is transfer to another batch, user should be able to select the target batch from existing batches
  - if disposition type is transfer to warehouse, user should be able to select the target warehouse from mst_site table
  - if disposition type is disposal, user should be able to input the disposal reason

for batchedit.vue, please make the following changes to material consumption section
- material consumption section should be grouped by material class like a table, 
  columns should include material class, material name, planned qty, actual qty, variance and details notes
- in the details notes column, there should be a button to open a dialog to show and edit the detailed consumption records for each material

for batchedit.vue, please make the following changes to material consumption section
- material consumption section should only have a table. columns should include material class name, planned qty for input, actual qty for input, variance and details notes
- in the details notes column, there should be a button to open a dialog to show and edit the detailed consumption records for each material

for batchedit.vue, please make the following changes to material consumption section
- cut width of variance columns from material consumption table to half.
- material class is defined in registry_def table with kind=material_class AND category='原材料'

for batchedit.vue, please make the following changes to material consumption section
- detail notes should allow user to input some text
- please add material list column to show all material used under each material class
  - 詳細　button should open a dialog to show the material list with columns material name, planned qty, actual qty, variance and notes

for batchedit.vue page kpi section 
・all table height and cell height should be smaller
