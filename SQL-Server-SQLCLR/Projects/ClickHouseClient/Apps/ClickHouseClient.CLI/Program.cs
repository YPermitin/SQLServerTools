using System;
using System.Data;
using System.Data.SqlClient;
using YPermitin.SQLCLR.ClickHouseClient.Entry;
using YPermitin.SQLCLR.ClickHouseClient.Entry.Extensions;
using YPermitin.SQLCLR.ClickHouseClient.Models;

namespace ClickHouseClient.CLI
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Начало проверки работы с ClickHouse.");

            // Строка подключения к SQL Server
            EntryBase.ConnectionString = @"server=localhost;database=master;trusted_connection=true;";
            // Строка подключения к ClickHouse
            string clickHouseConnectionString = @"Host=yy-comp;Port=8123;Username=default;password=;Database=default;";
                        
            Console.WriteLine("Строка подключения SQL Server: {0}", EntryBase.ConnectionString);
            Console.WriteLine("Строка подключения ClickHouse: {0}", clickHouseConnectionString);

            Console.Write("Установка соединения с SQL Server...");
            // Создаем соединение с SQL Server для дальнейшей работы
            using (SqlConnection sqlConnection = new SqlConnection(EntryBase.ConnectionString))
            {
                sqlConnection.Open();
                Console.WriteLine("OK!");
                // Устанавливаем подключение для отладки
                EntryBase.DebugConnection = sqlConnection;

                #region ExecuteScalar

                Console.WriteLine("Начало работы метода ExecuteScalar.");

                // Выполняем запрос с возвратом одного значения
                string clickHouseVersion = EntryClickHouseClient.ExecuteScalar(
                    connectionString: clickHouseConnectionString.ToSqlChars(),
                    queryText: "SELECT version()".ToSqlChars())
                    .ToStringFromSqlChars();
                Console.WriteLine("Версия ClickHouse: {0}", clickHouseVersion);

                Console.WriteLine("Окончание работы метода ExecuteScalar.");

                #endregion

                #region ExecuteStatement

                Console.WriteLine("Начало работы метода ExecuteStatement.");

                // Выполняем запрос без возврата результата.
                // В качестве примера создаем таблицу, предварительно удалив, если она существовала.

                Console.WriteLine("Удаляем существующую таблицу, если она существует.");
                EntryClickHouseClient.ExecuteStatement(
                    connectionString: clickHouseConnectionString.ToSqlChars(),
                    queryText: @"
DROP TABLE IF EXISTS SimpleTable
".ToSqlChars());

                Console.WriteLine("Создаем таблицу.");
                EntryClickHouseClient.ExecuteStatement(
                    connectionString: clickHouseConnectionString.ToSqlChars(),
                    queryText: @"
CREATE TABLE IF NOT EXISTS SimpleTable
(
	Id UInt64,
	Period datetime DEFAULT now(),
	Name String
)
ENGINE = MergeTree
ORDER BY Id;
".ToSqlChars());

                // А затем вставляем 100 записей
                Console.WriteLine("Добавленые новых записей....");
                for (int i = 1; i <= 10; i++)
                {
                    string rowName = "Row " + i;
                    EntryClickHouseClient.ExecuteStatement(
                        connectionString: clickHouseConnectionString.ToSqlChars(),
                        queryText: (@"
INSERT INTO SimpleTable
(
    Id, 
    Name
)
VALUES(" + i + @", '" + rowName + @"');
").ToSqlChars()
                    );

                    Console.WriteLine("Добавлена запись {0} - {1}", i, rowName);
                }

                Console.WriteLine("Окончание работы метода ExecuteStatement.");

                #endregion

                #region ExecuteSimple

                Console.WriteLine("Начало работы метода ExecuteSimple.");

                // Выполняем просто запрос с возвратом результата.
                // У этого метода одно ограничение - возвращается только первая колонока запроса SELECT
                // и только в виде строки.
                // Для возвращения нескольких колонок можно возвращать кортеж, который будет преобразован к JSON-строке.

                var simpleQueryResult = EntryClickHouseClient.ExecuteSimple(
                    connectionString: clickHouseConnectionString.ToSqlChars(),
                    queryText: @"
SELECT
	tuple(name, engine, data_path)
FROM `system`.`databases`
".ToSqlChars());

                var enumerator = simpleQueryResult.GetEnumerator();
                int rowsCount = 0;
                while (enumerator.MoveNext())
                {
                    Console.WriteLine(((ExecuteSimpleRowResult)enumerator.Current).ResultValue);
                    rowsCount++;
                }

                Console.WriteLine("Количество записей из результата запроса: {0}.", rowsCount);

                Console.WriteLine("Окончание работы метода ExecuteSimple.");

                #endregion

                #region ExecuteToTempTable

                Console.WriteLine("Начало работы метода ExecuteToTempTable.");

                // Создаем временную таблицу для сохранения результата запроса из ClickHouse
                Console.WriteLine("Создаем временную таблицу.");
                string sqlCreateTempTable = @"
IF(OBJECT_ID('tempdb..#logs') IS NOT NULL)
    DROP TABLE #logs;
CREATE TABLE #logs
(
    [EventTime] datetime2(0),
    [Query] nvarchar(max),
    [Tables] nvarchar(max),
    [QueryId] uniqueidentifier
);
";
                SqlCommand sqlCreateTempTableCommand = new SqlCommand(sqlCreateTempTable, sqlConnection);
                sqlCreateTempTableCommand.CommandType = System.Data.CommandType.Text;
                sqlCreateTempTableCommand.ExecuteNonQuery();

                // Выполняем запрос к ClickHouse и сохраняем во временную таблицу
                Console.WriteLine("Выполняем запрос к ClickHouse и сохраняем результат во временную таблицу.");
                EntryClickHouseClient.ExecuteToTempTable(
                    connectionString: clickHouseConnectionString.ToSqlChars(),
                    queryText: @"
select
	event_time,
	query,
	tables,
	query_id
from `system`.query_log
limit 1000
".ToSqlChars(),
                    tempTableName: "#logs".ToSqlChars());

                int totalRows = 0;
                SqlCommand sqlTempTableRows = new SqlCommand("SELECT COUNT(*) FROM #logs", sqlConnection);
                sqlTempTableRows.CommandType = System.Data.CommandType.Text;
                totalRows = (int)sqlTempTableRows.ExecuteScalar();                
                Console.WriteLine("Всего записей прочитано: {0}", totalRows);

                Console.WriteLine("Окончание работы метода ExecuteToTempTable.");

                #endregion

                #region ExecuteToGlobalTempTable

                Console.WriteLine("Начало работы метода ExecuteToGlobalTempTable.");

                // Создаем временную таблицу для сохранения результата запроса из ClickHouse
                Console.WriteLine("Создаем ГЛОБАЛЬНУЮ временную таблицу.");
                string sqlCreateGlobalTempTable = @"
IF(OBJECT_ID('tempdb..##logs') IS NOT NULL)
    DROP TABLE #logs;
CREATE TABLE ##logs
(
    [EventTime] datetime2(0),
    [Query] nvarchar(max),
    [Tables] nvarchar(max),
    [QueryId] uniqueidentifier
);
";
                SqlCommand sqlCreateGlobalTempTableCommand = new SqlCommand(sqlCreateGlobalTempTable, sqlConnection);
                sqlCreateTempTableCommand.CommandType = System.Data.CommandType.Text;
                sqlCreateTempTableCommand.ExecuteNonQuery();

                // Выполняем запрос к ClickHouse и сохраняем во временную таблицу
                Console.WriteLine("Выполняем запрос к ClickHouse и сохраняем результат во временную таблицу.");
                EntryClickHouseClient.ExecuteToGlobalTempTable(
                    connectionString: clickHouseConnectionString.ToSqlChars(),
                    queryText: @"
select
	event_time,
	query,
	tables,
	query_id
from `system`.query_log
limit 10
".ToSqlChars(),
                    tempTableName: "##logs".ToSqlChars(),
                    sqlServerConnectionString: EntryBase.ConnectionString.ToSqlChars());

                int totalRowsGlobal = 0;
                SqlCommand sqlTempTableRowsGlobal = new SqlCommand("SELECT COUNT(*) FROM ##logs", sqlConnection);
                sqlTempTableRowsGlobal.CommandType = System.Data.CommandType.Text;
                totalRowsGlobal = (int)sqlTempTableRowsGlobal.ExecuteScalar();
                Console.WriteLine("Всего записей прочитано: {0}", totalRowsGlobal);

                Console.WriteLine("Окончание работы метода ExecuteToGlobalTempTable.");

                #endregion
            }

            // Очищаем отладочное соединение SQL Server
            EntryBase.DebugConnection = null;

            Console.WriteLine("Окончание проверки работы с ClickHouse.");
        }
    }
}
