/*
Скрипт сжимает все таблицы базы данных и их индексы. 
Операция сжатия выполняется отдельно для каждого индекса.
Доп. информация: https://docs.microsoft.com/ru-ru/sql/relational-databases/data-compression/data-compression
*/

declare @compress table
(
   id int identity,
   enableCommand varchar(max),
   indexType tinyint
)
insert into @compress
select distinct 'alter index ' + i.name + ' on [' + s.name + '].[' + o.name + '] rebuild with (data_compression = page)',
       i.type
from sys.indexes i
join sys.objects o
on i.object_id = o.object_id
join sys.schemas s
on o.schema_id = s.schema_id
where i.type > 0
and o.is_ms_shipped = 0
order by i.type

declare @counter int = 1, @sql varchar(max)

while @counter <= (select max(id) from @compress)
begin
   select @sql = enableCommand
   from @compress
   where id = @counter

   print @sql
   exec(@sql)

   select @counter += 1
end