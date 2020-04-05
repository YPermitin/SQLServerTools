SELECT
	[name] AS [TableName],
	[object_id] AS [ObjectId],
	[schema_id] AS [SchemaId],
	[parent_object_id] AS [ParentObjectId],
	[type] AS [TableType],
	[create_date] AS [Created],
	[modify_date] AS [Modified],
	[is_published] AS [IsPublished],
	[is_schema_published] AS [IsSchemaPublished]
FROM tempdb.sys.objects
WHERE [is_ms_shipped] = 0