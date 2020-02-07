SELECT 
    t.name AS TableName, 
    c.name AS FTCatalogName ,
    i.name AS UniqueIdxName,
    cl.name AS ColumnName
FROM 
    sys.tables t 
	INNER JOIN sys.fulltext_indexes fi 
		ON t.[object_id] = fi.[object_id] 
	INNER JOIN sys.fulltext_index_columns ic
		ON ic.[object_id] = t.[object_id]
	INNER JOIN sys.columns cl
		ON ic.column_id = cl.column_id
		AND ic.[object_id] = cl.[object_id]
	INNER JOIN sys.fulltext_catalogs c 
		ON fi.fulltext_catalog_id = c.fulltext_catalog_id
	INNER JOIN sys.indexes i
		ON fi.unique_index_id = i.index_id
		AND fi.[object_id] = i.[object_id];