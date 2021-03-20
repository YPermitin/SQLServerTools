SET NOCOUNT ON;

DECLARE -- Настройки
	-- Текущее время
	@timeNow TIME = CAST(GETDATE() AS TIME), 
	-- Начало доступного интервала времени обслуживания
	@timeFrom TIME = CAST('21:00:00' AS TIME),
	-- Окончание доступного интервала времени обслуживания
	@timeTo TIME = CAST('02:00:00' AS TIME);

-- Проверка доступен ли запуск обслуживания в текущее время
IF (@timeTo >= @timeFrom) BEGIN
    IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
		RETURN;
END ELSE BEGIN
    IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
        OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow)))		
	RETURN;
END

DECLARE -- Служебные переменные
    @Operation NVARCHAR(128) = 'UPDATE STATISTICS'
    ,@RunDate DATETIME = GetDate()
    ,@StartDate DATETIME
    ,@FinishDate DATETIME;

DECLARE @resample CHAR(8)='NO' -- Для включения установить значение RESAMPLE
DECLARE @dbsid VARBINARY(85)

SELECT @dbsid = owner_sid
FROM sys.databases
WHERE name = db_name()

DECLARE @exec_stmt NVARCHAR(4000)
-- "UPDATE STATISTICS [SYSNAME].[SYSNAME] [SYSNAME] WITH RESAMPLE NORECOMPUTE"
DECLARE @exec_stmt_head NVARCHAR(4000)
-- "UPDATE STATISTICS [SYSNAME].[SYSNAME] "
DECLARE @options NVARCHAR(100)
-- "RESAMPLE NORECOMPUTE"

DECLARE @index_names CURSOR

DECLARE @ind_name SYSNAME
DECLARE @ind_id INT
DECLARE @ind_rowmodctr INT
DECLARE @updated_count INT
DECLARE @skipped_count INT

DECLARE @sch_id INT
DECLARE @schema_name SYSNAME
DECLARE @table_name SYSNAME
DECLARE @table_id INT
DECLARE @table_type CHAR(2)
DECLARE @schema_table_name NVARCHAR(640)

DECLARE @compatlvl tinyINT

-- Получаем список объектов, для которых нужно обслуживание статистики
DECLARE ms_crs_tnames CURSOR LOCAL FAST_FORWARD READ_ONLY for
SELECT
    name, -- Имя объекта
    object_id, -- Идентификатор объекта
    schema_id, -- Идентификатор схемы
    type
-- Тип объекта
FROM sys.objects o
WHERE o.type = 'U' -- таблица (пользовательская)
    OR o.type = 'IT'
-- внутренняя таблица
OPEN ms_crs_tnames
FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type

-- Определяем уровень совместимости для базы данных
SELECT @compatlvl = cmptlevel
FROM sys.sysdatabases
WHERE name = db_name()

WHILE (@@fetch_status <> -1)
BEGIN
    -- Формируем полное имя объекта (схема + имя)
    SELECT @schema_name = schema_name(@sch_id)
    SELECT @schema_table_name = quotename(@schema_name, '[') +'.'+ quotename(rtrim(@table_name), '[')

    --PRINT @schema_table_name

    -- Пропускаем таблицы, для которых отключен кластерный индекс
    IF (1 = isnull((SELECT is_disabled
        FROM sys.indexes
        WHERE object_id = @table_id AND index_id = 1), 0))
	BEGIN
        --PRINT @schema_table_name 
        FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
        CONTINUE;
    END
	ELSE BEGIN
        -- Пропускаем локальные временные таблицы
        IF ((@@fetch_status <> -2) AND (substring(@table_name, 1, 1) <> '#'))
		BEGIN
            SELECT @updated_count = 0
            SELECT @skipped_count = 0

            -- Подготавливаем начало команды: UPDATE STATISTICS [schema].[name]
            SELECT @exec_stmt_head = 'UPDATE STATISTICS ' + @schema_table_name + ' '

            -- Обходим индексы и объекты статистики для текущего объекта
            -- Объекты статистики как пользовательские, так и созданные автоматически.				
            IF ((@table_type = 'U') AND (1 = OBJECTPROPERTY(@table_id, 'TableIsMemoryOptimized')))	-- In-Memory OLTP
			BEGIN
                -- Hekaton-индексы (функциональность In-Memory OLTP) не отображаются в системном представлении sys.sysindexes,
                -- Поэтому нужно использовать sys.stats для их обработки.
                -- Примечание: OBJECTPROPERTY возвращает NULL для типа объекта "IT" (внутренние таблицы), 
                -- поэтому можно использовать это только для типа 'U' (пользовательские таблицы)
                -- Для Hekaton-индексов (функциональность In-Memory OLTP) 
                SET @index_names = CURSOR LOCAL FAST_FORWARD READ_ONLY for
						SELECT name, stat.stats_id, modification_counter AS rowmodctr
                FROM sys.stats AS stat
						CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id)
                WHERE stat.object_id = @table_id AND indexproperty(stat.object_id, name, 'ishypothetical') = 0
                    AND indexproperty(stat.object_id, name, 'iscolumnstore') = 0
                -- Для колоночных индексов статистика не обновляется
                ORDER BY stat.stats_id
            END ELSE 
            BEGIN
                -- Для обычных таблиц
                SET @index_names = CURSOR LOCAL FAST_FORWARD READ_ONLY for
						SELECT name, indid, rowmodctr
                FROM sys.sysindexes
                WHERE id = @table_id AND indid > 0 AND indexproperty(id, name, 'ishypothetical') = 0
                    AND indexproperty(id, name, 'iscolumnstore') = 0
                ORDER BY indid
            END

            OPEN @index_names
            FETCH @index_names INTO @ind_name, @ind_id, @ind_rowmodctr

            -- Если объектов статистик нет, то пропускаем
            IF @@fetch_status < 0
			BEGIN
                FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
                CONTINUE;
            END ELSE 
				BEGIN
                WHILE @@fetch_status >= 0
					BEGIN
                    -- Формируем имя индекса
                    DECLARE @ind_name_quoted NVARCHAR(258)
                    SELECT @ind_name_quoted = quotename(@ind_name, '[')

                    SELECT @options = ''

                    -- Если нет данных о накопленных изменениях или они больше 0 (количество измененных строк)
                    IF ((@ind_rowmodctr is null) OR (@ind_rowmodctr <> 0))
						BEGIN
                        SELECT @exec_stmt = @exec_stmt_head + @ind_name_quoted

                        -- Добавляем полное сканирование (FULLSCAN) для оптимизированных в памяти таблиц, если уровень совместимости < 130
                        IF ((@compatlvl < 130) AND (@table_type = 'U') AND (1 = OBJECTPROPERTY(@table_id, 'TableIsMemoryOptimized'))) -- In-Memory OLTP
								SELECT @options = 'FULLSCAN'

							-- add resample IF needed
							ELSE IF (upper(@resample)='RESAMPLE')
								SELECT @options = 'RESAMPLE '

                        -- Для уровнея совместимости больше 90 определяем доп. параметры
                        IF (@compatlvl >= 90)
                                -- Устанавливаем параметр NORECOMPUTE, если свойство AUTOSTATS для него было установлено в OFF
								IF ((SELECT no_recompute
                        FROM sys.stats
                        WHERE object_id = @table_id AND name = @ind_name) = 1)
								BEGIN
                            IF (len(@options) > 0) SELECT @options = @options + ', NORECOMPUTE'
									ELSE SELECT @options = 'NORECOMPUTE'
                        END

                        -- Добавляем сформированные параметры в команду обновления статистики
                        IF (len(@options) > 0)
								SELECT @exec_stmt = @exec_stmt + ' WITH ' + @options
                        
                        SET @StartDate = GetDate();
                        
                        -- Проверка доступен ли запуск обслуживания в текущее время
                        SET @timeNow = CAST(GETDATE() AS TIME);
                        IF (@timeTo >= @timeFrom) BEGIN
                            IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
                                RETURN;
                        END ELSE BEGIN
                            IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
                                OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow)))		
                            RETURN;
                        END

                        BEGIN TRY                            
                            EXEC sp_executesql @exec_stmt;
                            SET @FinishDate = GetDate();

                            -- Здесь можно сохранить информацию о проведенной операции обслуживания
                            --  @table_name - имя таблицы
                            --  @ind_name - имя индекса
                            --  @Operation - вид операции (перестроение или реорганизация)
                            --  @RunDate - дата запуска операции обслуживания (начало запуска всего скрипта)
                            --  @StartDate - начало конкретно этой операции
                            --  @FinishDate - завершение конкретно этой операции
                        END TRY
                        BEGIN CATCH
                            PRINT CAST(Error_message() AS NVARCHAR(250)) + ' ' + CAST(Error_Number() AS NVARCHAR(250)) + ' ' + CAST(Error_Line() AS NVARCHAR(250));
                        END CATCH
                        
                        SELECT @updated_count = @updated_count + 1
                    END ELSE
					BEGIN
                        SELECT @skipped_count = @skipped_count + 1
                    END
                    FETCH @index_names INTO @ind_name, @ind_id, @ind_rowmodctr
                END
            END
            DEALLOCATE @index_names
        END
    END
    FETCH NEXT FROM ms_crs_tnames INTO @table_name, @table_id, @sch_id, @table_type
END
DEALLOCATE ms_crs_tnames
