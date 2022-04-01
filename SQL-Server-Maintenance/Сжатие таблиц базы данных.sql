/*
Скрипт сжимает все таблицы базы данных и их индексы. 
Операция сжатия выполняется для таблицы и всех ее индексов за раз.
Доп. информация: https://docs.microsoft.com/ru-ru/sql/relational-databases/data-compression/data-compression
*/


declare @table_name sys.sysname, @IS_CLUSTERED bit, @SQL nvarchar(1000)
declare @c cursor
set @c = cursor local fast_forward for   
select distinct s.name + '.' + o.name, coalesce( (select 1 from sys.indexes i where o.object_id = i.object_id and i.type_desc = 'CLUSTERED' ), 0 ) IS_CLUSTERED
from sys.partitions p
  inner join sys.objects o on p.object_id = o.object_id and o.type_desc = 'USER_TABLE' and p.partition_number = 1
  inner join sys.schemas s on s.schema_id = o.schema_id
where p.data_compression_desc = 'NONE'
open @c
fetch next from @c into @table_name, @IS_CLUSTERED
while (@@fetch_status = 0) begin
  set @sql = 'ALTER INDEX ALL ON ' + @table_name + ' REBUILD WITH (DATA_COMPRESSION = PAGE);' -- DATA_COMPRESSION = PAGE / DATA_COMPRESSION = NONE
  execute (@sql)
  print @sql
  if ( @IS_CLUSTERED = 0 ) begin
    set @sql = 'ALTER TABLE ' + @table_name + ' REBUILD WITH (DATA_COMPRESSION = PAGE);' -- DATA_COMPRESSION = PAGE / DATA_COMPRESSION = NONE
    execute (@sql)
    print @sql
  end
  fetch next from @c into @table_name, @IS_CLUSTERED
end
