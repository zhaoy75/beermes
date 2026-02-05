I want to create an vue page to maintain attr_def table.
- the layout include a main screen (table) and a right side drawer (edit)
- Main screen (table) should list all attr_def data in a table with following columns
	•	Code
	•	Display name (multi-lang)
	•	Domain / Industry
	•	Data type (number / text / enum / bool)
	•	UOM
	•	Validation (min/max/regex)
	•	Active flag
	•	🔒 Usage count (how many sets/entities use it)
- Right-side drawer (edit)
	•	Technical fields (JSON schema-like)
	•	Enum values editor
	•	Default value
	•	Deprecation flag (⚠️ never delete)
- data type should be input by a dropdown list
- validate check is needed for data type
- Warn if attr is already used
- backend is supabase
- the will be a filter to search by code and filter by domain

