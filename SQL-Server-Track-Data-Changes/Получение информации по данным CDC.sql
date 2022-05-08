/*
Получение всех сведений о изменениях по данным CDC.
https://docs.microsoft.com/en-us/sql/relational-databases/system-functions/cdc-fn-cdc-get-all-changes-capture-instance-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15
*/

-- Например, если таблица "Users" в схеме "dbo" включена в отслеживание изменений с помощью CDC,
-- то получить изменения можно следующим образом:
DECLARE @from_lsn binary(10), @to_lsn binary(10);
-- Идентификатор начальной транзакции
SET @from_lsn = sys.fn_cdc_get_min_lsn('dbo_Users');  
-- Идентификатор конечной транзакции
SET @to_lsn   = sys.fn_cdc_get_max_lsn();  
-- Запрос к системной функции
SELECT
	--__$start_lsn - идентификатор транзакции, связанный с фиксацией изменений
	--__$seqval -- порядковый номер записи для упорядочивания истории изменений в рамках одной транзакции
	--__$operation -- тип DML-операции (
	--		1 - delete (удаление), 
	--		2 - insert (добавление), 
	--		3 - update (обновление, используется, если используется "all update old", 
	--		4 - update (обновление с новыми значениями столбцов)
	--)
	--__$update_mask -- битовая маска со значениями, соответствующая каждому захваченному столбцу захваченных изменений.
	*
FROM cdc.fn_cdc_get_all_changes_dbo_Users (
    @from_lsn, 
    @to_lsn, 
    N'all' -- Опция вывода строк. 
    -- "all" - возвращает все изменения, а для операций обновления выводится одна запись с новыми значениями. 
    -- "all update old" - возвращает все изменения, а для операций обновления выводится две строки.
    -- Одна со старыми значениями, другая с новыми.
);





/*
Получение сведений об изменениях по данным CDC. 
В отличии от cdc.fn_cdc_get_all_changes_<instance_captured> (https://docs.microsoft.com/en-us/sql/relational-databases/system-functions/cdc-fn-cdc-get-all-changes-capture-instance-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15)
возвращает на каждое изменение только одну запись, самую актуальную.
https://docs.microsoft.com/en-us/sql/relational-databases/system-functions/cdc-fn-cdc-get-net-changes-capture-instance-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15
*/
-- Например, если таблица "Users" в схеме "dbo" включена в отслеживание изменений с помощью CDC,
-- то получить изменения можно следующим образом:
DECLARE @from_lsn binary(10), @to_lsn binary(10);
-- Идентификатор начальной транзакции
SET @from_lsn = sys.fn_cdc_get_min_lsn('dbo_Users');  
-- Идентификатор конечной транзакции
SET @to_lsn   = sys.fn_cdc_get_max_lsn();  
-- Запрос к системной функции
SELECT
	--__$start_lsn - идентификатор транзакции, связанный с фиксацией изменений
	--__$operation -- тип DML-операции (
	--		1 - delete (удаление), 
	--		2 - insert (добавление), 
	--		3 - update (обновление, используется, если используется "all update old", 
	--		4 - update (обновление с новыми значениями столбцов)
    --      5 - для применения операции нужно сделать INSERT или UPDATE (при фильтре "all with merge")
	--)
	--__$update_mask -- битовая маска со значениями, соответствующая каждому захваченному столбцу захваченных изменений.
	*
FROM cdc.fn_cdc_get_net_changes_dbo_Users (
    @from_lsn, 
    @to_lsn, 
    N'all' -- Опция вывода строк. 
    -- "all" - возвращает изменения по строке с финальным значением LSN. Колонка "__$update_mask" всегда будет NULL.
    -- "all with mask" - возвращает изменения по строке с финальным значением LSN. 
    -- Для операций UPDATE в колонку "__$update_mask" записываются захваченные столбцы, измененные при обновлении.
    -- "all with merge" - возвращает изменения по строке с финальным значением LSN. Колонка "__$operation" будет иметь
    -- одно из двух значений: 1 - данные были удалены, 5 - для применения операции нужно сделать либо INSERT, либо UPDATE.
);





/*
Преобразование LSN в дату и время, и наоборот.
*/
-- Для указанного LSN возвращает дату и время изменения
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/system-functions/sys-fn-cdc-map-lsn-to-time-transact-sql?view=sql-server-ver15
SELECT sys.fn_cdc_map_lsn_to_time('<ЗначениеLSN>')

-- Преобразование даты в LSN
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/system-functions/sys-fn-cdc-map-time-to-lsn-transact-sql?view=sql-server-ver15
select sys.fn_cdc_map_time_to_lsn(
    'largest less than or equal', -- Способ обнаружения LSN:
    --  "largest less than" - наибольший
    --  "largest less than or equal" - наибольший или равный
    --  "smallest greater than" - наименьший
    --  "smallest greater than or equal" - наименьший или равный
    getdate() -- Дата и время для поиска подходящего LSN
); 





/*
Получение нижней конечной точки LSN для экземпляра отслеживания.
https://docs.microsoft.com/ru-ru/sql/relational-databases/system-functions/sys-fn-cdc-get-min-lsn-transact-sql?view=sql-server-ver15
*/
SELECT sys.fn_cdc_get_min_lsn ('<capture_instance_name>')

-- Например, если таблица "Users" в схеме "dbo" включена в отслеживание изменений с помощью CDC,
-- то получить минимальный LSN можно следующей командой:
SELECT sys.fn_cdc_get_min_lsn ('dbo_Users')





/*
Получение верхней конечной точки LSN для экземпляра отслеживания. По факту возвращается максимальный идентификатор транзакции LSN
из таблицы cdc.lsn_time_mapping (https://docs.microsoft.com/ru-ru/sql/relational-databases/system-tables/cdc-lsn-time-mapping-transact-sql?view=sql-server-ver15)
https://docs.microsoft.com/ru-ru/sql/relational-databases/system-functions/sys-fn-cdc-get-max-lsn-transact-sql?view=sql-server-ver15
*/
SELECT sys.fn_cdc_get_max_lsn()