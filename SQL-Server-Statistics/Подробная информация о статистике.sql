SET NOCOUNT ON;

DECLARE 
	@table_name nvarchar(max) = '<IndexName>.<TableName>'
	,@object_name nvarchar(max) = '<ObjectName>'
	,@stat_header_cmd nvarchar(max)
	,@the_histogram_cmd nvarchar(max)
	,@the_density_vector_cmd nvarchar(max);

SELECT @stat_header_cmd = 'DBCC SHOW_STATISTICS (''' + @table_name + ''', ''' + @object_name + ''') WITH  STAT_HEADER';
SELECT @the_histogram_cmd = 'DBCC SHOW_STATISTICS (''' + @table_name + ''', ''' + @object_name + ''') WITH HISTOGRAM';
SELECT @the_density_vector_cmd = 'DBCC SHOW_STATISTICS (''' + @table_name + ''', ''' + @object_name + ''') WITH DENSITY_VECTOR';

IF OBJECT_ID('tempdb..#the_stat_header') IS NOT NULL
	DROP TABLE #the_stat_header;
IF OBJECT_ID('tempdb..#the_histogram ') IS NOT NULL
	DROP TABLE #the_histogram;
IF OBJECT_ID('tempdb..#the_density_vector ') IS NOT NULL
	DROP TABLE #the_density_vector;

CREATE TABLE #the_stat_header (
    [Name] sql_variant NULL
,   [Updated] sql_variant NULL
,   [Rows] sql_variant NULL
,   [Rows Sampled] sql_variant NULL
,   [Steps] sql_variant NULL
,   [Density] sql_variant NULL
,   [Average key length] sql_variant NULL
,   [String index] sql_variant NULL
,   [Filter Expression] nvarchar(max) NULL
,   [Unfiltered Rows] sql_variant NULL
)
INSERT INTO #the_stat_header EXEC (@stat_header_cmd)

CREATE TABLE #the_density_vector (
    [All density] sql_variant
,   [Average Length] sql_variant
,   [Columns] sql_variant
)
INSERT INTO #the_density_vector EXEC (@the_density_vector_cmd)

CREATE TABLE #the_histogram (
    [RANGE_HI_KEY] sql_variant
,   [RANGE_ROWS] sql_variant
,   [EQ_ROWS] sql_variant
,   [DISTINCT_RANGE_ROWS]  sql_variant
,   [AVG_RANGE_ROWS] sql_variant
)
INSERT INTO #the_histogram EXEC (@the_histogram_cmd)

SELECT  
	-- Имя объекта статистики.
	[Name] AS [Имя]
	-- Дата и время последнего обновления статистики. 
	-- Функция STATS_DATE представляет собой альтернативный способ получения этих данных.
	,[Updated] AS [Обновлен]
	-- Общее число строк в таблице или индексированном представлении при последнем обновлении статистики. 
	-- Если статистика отфильтрована или соответствует отфильтрованному индексу, количество строк может быть меньше, чем количество строк в таблице.
	,[Rows] AS [Строка]
	-- Общее количество строк, выбранных для статистических вычислений. 
	-- Если имеет место условие «количество строк выборки < количество строк таблицы», 
	-- то отображаемые результаты определения гистограммы и вычисления плотности 
	-- представляют собой оценки, основанные на строках выборки.
	,[Rows Sampled] AS [Количество строк для стат. вычислений]
	-- Число шагов в гистограмме. Каждый шаг охватывает диапазон значений столбцов,
	-- за которым следует значение столбца, представляющее собой верхнюю границу. 
	-- Шаги гистограммы определяются в первом ключевом столбце статистики. Максимальное число шагов — 200.
	,[Steps] AS [Шаги]
	-- Рассчитывается как 1 / различающиеся значения для всех значений в первом ключевом столбце объекта статистики, 
	-- исключая возможные значения гистограммы. Это значение плотности не используется оптимизатором запросов 
	-- и отображается для обратной совместимости с версиями, выпущенными до SQL Server 2008.
	,[Density] AS [Плотность]
	-- Среднее число байтов на значение для всех ключевых столбцов в объекте статистики.
	,[Average key length] AS [Средняя длина ключа]
	-- Значение «Да» указывает, что объект статистики содержит сводную строковую статистику, 
	-- позволяющую уточнить оценку количества элементов для предикатов запроса, использующих оператор LIKE, 
	-- например WHERE ProductName LIKE '%Bike'. Сводная строковая статистика хранится отдельно от гистограммы 
	-- и создается в первом ключевом столбце объекта статистики, если он имеет тип char, varchar, nchar, nvarchar, varchar(max), nvarchar(max), text или ntext.
	,[String index] AS [Используется сводная строковая статистика]
	-- Предикат для подмножества строк таблицы, включенных в объект статистики. NULL — неотфильтрованная статистика. 
	,[Filter Expression] AS [Критерий фильтра]
	-- Общее количество строк в таблице перед применением критерия фильтра. 
	-- Если Filter Expression имеет значение NULL, то столбец Unfiltered Rows совпадает со столбцом Rows.
	,[Unfiltered Rows] AS [Количество строк без учета фильтра]
FROM #the_stat_header

SELECT
	-- Плотность равна 1 / различающиеся значения. В результатах отображаются плотности для каждого префикса столбцов объекта статистики, 
	-- по одной строке на плотность. Различающееся значение — это отдельный список значений столбцов на строку и на префикс столбцов. 
	-- Например, если объект статистики содержит ключевые столбцы (A, B, C), то в результатах приводится плотность отдельных списков значений 
	-- в каждом из следующих префиксов столбцов: (A), (A, B) и (A, B, C). 
	-- При использовании префикса (A, B, C) каждый из этих списков является отдельным списком значений: (3, 5, 6), (4, 4, 6), (4, 5, 6), (4, 5, 7). 
	-- При использовании префикса (A, B) одинаковые значения столбцов имеют следующие отдельные списки значений: (3, 5), (4, 4) и (4, 5).
	[All density] AS [Общая плотность]
	-- Средняя длина (в байтах) для хранения списка значений столбца для данного префикса столбца. 
	-- Если каждому значению в списке (3, 5, 6), например, требуется по 4 байта, то длина составляет 12 байт.
	,[Average Length] AS [Средняя длина]
	-- Имена столбцов в префиксе, для которых отображаются значения «Общая плотность» и «Средняя длина».
	,[Columns] AS [Столбцы]
FROM #the_density_vector

SELECT
	-- Верхнее граничное значение столбца для шага гистограммы. Это значение столбца называется также ключевым значением.
	[RANGE_HI_KEY] AS [Верхняя граница значения столбца]
	-- Предполагаемое количество строк, значение столбцов которых находится в пределах шага гистограммы, исключая верхнюю границу.
	,[RANGE_ROWS] AS [Предполагаемое количество строк]
	-- Предполагаемое количество строк, значение столбцов которых равно верхней границе шага гистограммы.
	,[EQ_ROWS] AS [Предполагаемое количество строк, равное верхней границе значений]
	-- Предполагаемое количество строк с различающимся значением столбца в пределах шага гистограммы, исключая верхнюю границу.
	,[DISTINCT_RANGE_ROWS] AS [Предполагаемое количество строк с различающимися значениями в шаге гистограммы]
	-- Среднее количество строк с повторяющимися значениями столбца в пределах шага гистограммы, исключая верхнюю границу. 
	-- Если значение DISTINCT_RANGE_ROWS больше 0, AVG_RANGE_ROWS вычисляется делением RANGE_ROWS на DISTINCT_RANGE_ROWS. 
	-- Если значение DISTINCT_RANGE_ROWS равно 0, AVG_RANGE_ROWS возвращает значение 1 для шага гистограммы.
	,[AVG_RANGE_ROWS] AS [Среднее количество строк с повторяющимися значениями в шаге гистограммы]
FROM #the_histogram

IF OBJECT_ID('tempdb..#the_stat_header') IS NOT NULL
	DROP TABLE #the_stat_header;
IF OBJECT_ID('tempdb..#the_histogram ') IS NOT NULL
	DROP TABLE #the_histogram;
IF OBJECT_ID('tempdb..#the_density_vector ') IS NOT NULL
	DROP TABLE #the_density_vector;
