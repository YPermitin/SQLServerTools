use master;
GO
------------------------------------------------------------------------------------------
--  sp_MoveTablesToFileGroup
--
--  Moves tables, heaps and indexes and LOBS to a filegroup.
--  Author:   Mark White   (maranite@gmail.com)
------------------------------------------------------------------------------------------
CREATE PROC [dbo].[sp_MoveTablesToFileGroup]
    @SchemaFilter        varchar(255)   = '%',          -- Filter which table schemas to work on
    @TableFilter         varchar(255)   = '%',          -- Filter which tables to work on
    @DataFileGroup       varchar(255)   = 'PRIMARY',    -- Name of filegroup that data must be moved to
    @LobFileGroup        varchar(255)   = NULL,         -- Name of filegroup that LOBs (if any) must be moved to
    @FromFileGroup       varchar(255)   = '%',          -- Only move objects that currenly occupy this filegroup
    @ClusteredIndexes    bit            = 1,            -- 1 = move clustered indexes (table data), else 0
    @SecondaryIndexes    bit            = 1,            -- 1 = move secondary indexes, else 0
    @Heaps               bit            = 1,            -- 1 = move heaps (lazy-assed, unindexed crap), else 0
    @Online              bit            = 0,            -- 1 = keep indexes online (required Enterprise edition)
    @ProduceScript       bit            = 0             -- 1 = emit a T-SQL script instead of performing the moves
AS
BEGIN
    SET NOCOUNT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;

    IF FILEGROUP_ID(@DataFileGroup) IS NULL 
        RAISERROR('Invalid Data FileGroup specified.',10,1);
    
    IF @Online = 1 AND SERVERPROPERTY('EngineEdition') <> 3 
        RAISERROR('SQL Server Enterprise edition is required for online index operations.',10,1);

    IF (@LobFileGroup IS NOT NULL) AND (@@MICROSOFTVERSION / 0x01000000) < 11
        RAISERROR('LOB data can only be moved in SQL 2012 or newer. Consider re-creating your table/s.',10,1);

    DECLARE @SQL VARCHAR(MAX) = '';
    DECLARE @Script VARCHAR(MAX) = '';
	DECLARE @RANDOM_NAME VARCHAR(100) = REPLACE(NEWID(),'-','');

    DECLARE C CURSOR FOR 
        WITH TYPED_COLUMNS AS (
            SELECT name = '[' + col.name + '] ', col.is_nullable, col.user_type_id, col.max_length, col.object_id, col.column_id, 
                  [type_name] = '[' + typ.name + '] '
            from sys.columns col
            JOIN sys.types typ on typ.user_type_id = col.user_type_id
        ),   
        INDEX_COLUMNS AS (
            SELECT col.*, k.index_id, k.is_included_column, k.key_ordinal, k.is_descending_key
            from TYPED_COLUMNS col
            join sys.index_columns as k on k.object_id = col.object_id and k.column_id = col.column_id
        )
        SELECT DISTINCT
        /*  If the table contains LOB data which does not reside where the caller would like it to reside, then use the Brad Hoff's neat 
            partition scheme trick to move LOB data. Effectively, we simply create a partition function & scheme, rebuild the index on that
			scheme, and then allow the normal rebuild (without partitioning) to be done afterwards.
            For details, see Kimberly Tripp's site: http://www.sqlskills.com/blogs/kimberly/understanding-lob-data-20082008r2-2012/)         
	    */
        CASE WHEN COALESCE([lob_fg], @LobFileGroup,'PRIMARY') <> COALESCE(@LobFileGroup, [lob_fg], 'PRIMARY') AND [first_ix_col_type] IS NOT NULL AND [type_desc] <> 'NONCLUSTERED'
        THEN            
            'CREATE PARTITION FUNCTION PF_' + random_name + ' (' + [first_ix_col_type] + ') AS RANGE RIGHT FOR VALUES (0);' + CHAR(13) + 
            'CREATE PARTITION SCHEME PS_' + random_name + ' AS PARTITION PF_' + random_name + ' TO ([' + @LobFileGroup + '],[' + @LobFileGroup + ']);' + CHAR(13) + CHAR(13) +
            CASE [type_desc]
				WHEN 'HEAP' 
				THEN 'CREATE CLUSTERED ' + index_on_table + ' (' + index_columns + ') ' + options + ' ON PS_' + random_name + '(' + [first_ix_col_name] + ');' + CHAR(13) 
					+ 'DROP ' + index_on_table + ';' + CHAR(13) 
        
				ELSE 'CREATE ' + is_unique + [type_desc] + ' '
							   + index_on_table + ' (' + index_columns + ')' + CHAR(13) + [includes / filters] + options +  'ON PS_' + random_name + '(' + [first_ix_col_name] + ');' + CHAR(13) 
				END 
				+ CHAR(13)
			ELSE '' END 
        + 
        CASE [type_desc]
            WHEN 'HEAP' 
            THEN 'CREATE CLUSTERED ' + index_on_table + ' (' + index_columns + ') ' + options + ' ON [' + @DataFileGroup + '];' + CHAR(13) 
               + 'DROP ' + index_on_table + ';' + CHAR(13)       
        
            ELSE 'CREATE ' + is_unique + [type_desc] + ' '
									   + index_on_table + ' (' + index_columns + ')' + CHAR(13) + [includes / filters] + options +  'ON [' + @DataFileGroup + '];'
        END
        + 
        CASE WHEN COALESCE([lob_fg], @LobFileGroup,'PRIMARY') <> COALESCE(@LobFileGroup, [lob_fg], 'PRIMARY')   AND [first_ix_col_type] IS NOT NULL
        THEN            
            CHAR(13) + CHAR(13) + 
            'DROP PARTITION SCHEME PS_' + random_name + ';' + CHAR(13) +
            'DROP PARTITION FUNCTION PF_' + random_name + ';' + CHAR(13) + CHAR(13) 
        ELSE '' END 
        FROM 
        (
            select distinct 
					index_on_table       =   'INDEX [' + ISNULL(i.name, 'PK_' + sch.name + '_' +  obj.name) COLLATE DATABASE_DEFAULT + ']' + CHAR(13) + 'ON [' + sch.name + '].[' + obj.name + ']',
                    type_desc            =   i.type_desc,
                    is_unique            =   CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END ,                                
                    [lob_fg]             =   CASE WHEN (i.type IN (0,1) AND EXISTS (SELECT * FROM TYPED_COLUMNS col WHERE col.object_id = obj.object_id and col.max_length = -1)) 
                                                    OR (i.type = 2 AND EXISTS (SELECT * FROM INDEX_COLUMNS col WHERE col.object_id = i.object_id and col.index_id = i.index_id AND col.max_length = -1)) 
                                                THEN 
                                                    FILEGROUP_NAME(obj.lob_data_space_id)
                                                END,
                    [index_columns]         =   REPLACE(
                                                    ISNULL(
                                                        (SELECT col.name + CASE WHEN is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END as [data()]
                                                        FROM INDEX_COLUMNS col 
                                                        where col.object_id = i.object_id and col.index_id = i.index_id and col.is_included_column <> 1 
                                                        and i.type in (1,2)
                                                        order by key_ordinal
                                                        for xml path(''))
                                                        ,
                                                        (select TOP 1 '[' + col.name + '] ' as [data()]
                                                        from sys.columns col  
                                                        where col.object_id = i.object_id and i.type = 0 and (col.user_type_id in (48,52,56,58,59,62,104,127,106,108) or col.max_length between 1 and 800)
                                                        order by col.is_nullable desc
                                                        for xml path(''))
                                                     )
                                                , ' ['   
                                                , ', ['
                                                ),
                    [first_ix_col_name]         =   ISNULL(
                                                        (SELECT TOP 1 col.name
                                                        FROM INDEX_COLUMNS col 
                                                        WHERE col.object_id = i.object_id and col.index_id = i.index_id 
                                                        and col.is_included_column <> 1 and i.type in (1,2)
                                                        order by key_ordinal)
                                                        ,
                                                        (select TOP 1 name --type_name 
                                                        from TYPED_COLUMNS col 
                                                        where col.object_id = i.object_id and i.type = 0 and (col.user_type_id in (48,52,56,58,59,62,104,127,106,108) or col.max_length between 1 and 800)
                                                        order by col.is_nullable desc)
                                                    ),
                    [first_ix_col_type]      =      ISNULL(
                                                        (select TOP 1 type_name
                                                        FROM INDEX_COLUMNS col 
                                                        JOIN sys.types typ on typ.user_type_id = col.user_type_id
                                                        WHERE col.object_id = i.object_id and col.index_id = i.index_id 
                                                        and col.is_included_column <> 1 and i.type in (1,2)
                                                        order by key_ordinal)
                                                        ,
                                                        (select TOP 1 type_name + CASE WHEN col.user_type_id not in (48,52,56,58,59,62,104,127,106,108) THEN '(' + CONVERT(VARCHAR(10), col.max_length) + ')' ELSE '' END
                                                        from TYPED_COLUMNS col 
                                                        where col.object_id = i.object_id and i.type = 0 and (col.user_type_id in (48,52,56,58,59,62,104,127,106,108) or col.max_length between 1 and 800)
                                                        order by col.is_nullable desc)
                                                     ),
                    [includes / filters]   =   ISNULL(
                                                    REPLACE('INCLUDE (*)','*',   
                                                        REPLACE(
                                                            (select col.name as [data()]
                                                            from INDEX_COLUMNS col 
                                                            where col.object_id = i.object_id and col.index_id = i.index_id and col.is_included_column <> 0
                                                            order by key_ordinal, col.column_id
                                                            for xml path('')
                                                            ),  
                                                            ']  [', 
                                                            '], ['
                                                        )) + CHAR(13) 
                                                    ,''
                                                ) + 
                                                ISNULL ('WHERE ' + i.filter_definition + CHAR(13) , ''),

                    options               = ' WITH ('
                                            + ISNULL( CASE WHEN i.type IN (1, 2) THEN 'DROP_EXISTING = ON ' END, 'DROP_EXISTING = OFF')
                                            + ISNULL(', FILLFACTOR = '         + NULLIF(CAST(fill_factor AS VARCHAR(10)), '0') , '')
                                            + ISNULL(', PAD_INDEX = '         + CASE is_padded WHEN 1 THEN 'ON' ELSE 'OFF' END, '')
                                            + ISNULL(', ALLOW_ROW_LOCKS = '      + CASE allow_row_locks WHEN 1 THEN 'ON' ELSE 'OFF' END ,'')
                                            + ISNULL(', ALLOW_PAGE_LOCKS = '   + CASE allow_page_locks WHEN 1 THEN 'ON' ELSE 'OFF' END , '')
                                            + ISNULL(', IGNORE_DUP_KEY = '      + CASE ignore_dup_key WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' END, '')
                                            + ISNULL(', DATA_COMPRESSION = '   + data_compression_desc, '')
                                            + ISNULL(', STATISTICS_NORECOMPUTE = ' + CASE no_recompute WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' END, '')
                                            + CASE WHEN @Online = 1 AND SERVERPROPERTY('EngineEdition') = 3 THEN ', ONLINE = ON' ELSE '' END
                                            + ') ' + CHAR(13),
                    random_name            = 'MOVE_HELPER_' + @RANDOM_NAME
            from sys.indexes    i	(readpast)
            join sys.filegroups f   (readpast)   ON i.data_space_id = f.data_space_id 
            join sys.tables     obj (readpast)   ON i.object_id=obj.object_id
            join sys.schemas    sch            ON obj.schema_id=sch.schema_id
            left join sys.partitions part      ON i.object_id = part.object_id and i.index_id = part.index_id
            left join sys.stats stats         ON i.object_id=stats.object_id and i.index_id = stats.stats_id
            where sch.name <> 'sys' 
            and sch.name LIKE ISNULL(@SchemaFilter, '%')
            and obj.name LIKE ISNULL(@TableFilter,  '%')
            and f.name LIKE ISNULL(@FromFileGroup, '%')
            and (f.name <> @DataFileGroup 
                OR 
                COALESCE(FILEGROUP_NAME(obj.lob_data_space_id), @LobFileGroup,'PRIMARY') <> COALESCE(@LobFileGroup, FILEGROUP_NAME(obj.lob_data_space_id), 'PRIMARY'))
            and (   (i.type = 1 AND @ClusteredIndexes = 1)
                 OR (i.type = 2 AND @SecondaryIndexes = 1)
                 OR (i.type = 0 AND @Heaps = 1)
            )
        ) AS Script_Builder
        

    OPEN C;
    FETCH NEXT FROM C INTO @SQL;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @ProduceScript = 1
            SELECT @SQL
        ELSE
            EXEC (@SQL);
        
        FETCH NEXT FROM C INTO @SQL;
    END

    CLOSE C;
    DEALLOCATE C;
END
GO

EXEC sp_ms_marksystemobject 'sp_MoveTablesToFileGroup'
