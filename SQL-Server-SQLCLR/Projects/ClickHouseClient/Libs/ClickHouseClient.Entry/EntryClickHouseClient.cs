using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Net;
using System.Security.Principal;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Server;
using Newtonsoft.Json;
using YPermitin.SQLCLR.ClickHouseClient.ADO;
using YPermitin.SQLCLR.ClickHouseClient.Copy;
using YPermitin.SQLCLR.ClickHouseClient.Models;
using YPermitin.SQLCLR.ClickHouseClient.Utility;

namespace YPermitin.SQLCLR.ClickHouseClient.Entry
{
    public class EntryClickHouseClient : EntryBase
    {
        private static SqlChars _emptyString = new SqlChars(string.Empty);
        private static readonly Dictionary<Type, Func<string, Type, string>> TypeConverters = new Dictionary<Type, Func<string, Type, string>>();
        static EntryClickHouseClient()
        {
            // Дата и время
            TypeConverters.Add(typeof(DateTime), (sourceName, sourceType) =>
            {
                return "datetime2(0)";
            });
            // Строковой тип
            TypeConverters.Add(typeof(string), (sourceName, sourceType) =>
            {
                return "nvarchar(max)";
            });            
            // Дробное число
            TypeConverters.Add(typeof(double), (sourceName, sourceType) =>
            {
                return "numeric(35,5)";
            });
            // Дробное число
            TypeConverters.Add(typeof(float), (sourceName, sourceType) =>
            {
                return "numeric(35,5)";
            });
            // Целое число            
            TypeConverters.Add(typeof(Int16), (sourceName, sourceType) =>
            {
                return "numeric(25,0)";
            });
            TypeConverters.Add(typeof(Int32), (sourceName, sourceType) =>
            {
                return "numeric(25,0)";
            });            
            TypeConverters.Add(typeof(UInt16), (sourceName, sourceType) =>
            {
                return "numeric(25,0)";
            });
            TypeConverters.Add(typeof(UInt32), (sourceName, sourceType) =>
            {
                return "numeric(25,0)";
            });
            // Целое число (большое)
            TypeConverters.Add(typeof(Int64), (sourceName, sourceType) =>
            {
                return "numeric(25,0)";
            });
            TypeConverters.Add(typeof(UInt64), (sourceName, sourceType) =>
            {
                return "numeric(25,0)";
            });
            // Байт
            TypeConverters.Add(typeof(byte), (sourceName, sourceType) =>
            {
                return "numeric(15,0)";
            });
            // Булево
            TypeConverters.Add(typeof(bool), (sourceName, sourceType) =>
            {
                return "bit";
            });
            // IP-адрес
            TypeConverters.Add(typeof(IPAddress), (sourceName, sourceType) =>
            {
                return "nvarchar(max)";
            });
            // Массивы
            TypeConverters.Add(typeof(Array), (sourceName, sourceType) =>
            {
                return "nvarchar(max)";
            });
            // Словари
            TypeConverters.Add(typeof(DictionaryBase), (sourceName, sourceType) =>
            {
                return "nvarchar(max)";
            });
            // Кортежи
            TypeConverters.Add(typeof(Tuple), (sourceName, sourceType) =>
            {
                return "nvarchar(max)";
            });
            // Уникальный идентификатор
            TypeConverters.Add(typeof(Guid), (sourceName, sourceType) =>
            {
                return "uniqueidentifier";
            });
        }

        /// <summary>
        /// Функция для выполнения запроса к ClickHouse и получения скалярного значения
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="queryText">SQL-текст запроса для выполнения</param>
        /// <returns>Результат запроса, представленный строкой</returns>
        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlChars ExecuteScalar(SqlChars connectionString, SqlChars queryText)
        {
            string connectionStringValue = new string(connectionString.Value);
            string queryTextValue = new string(queryText.Value);

            string resultAsString = string.Empty;

            using (var connection = new ClickHouseConnection(connectionStringValue))
            {
                var queryResult = connection.ExecuteScalarAsync(queryTextValue)
                    .GetAwaiter().GetResult();

                resultAsString = queryResult.ToString();
            }

            return new SqlChars(resultAsString);
        }


        /// <summary>
        /// Функция для выполнения простого запроса.
        /// 
        /// Возвращается только первая колонка из результата запроса в виде строки.
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="queryText">SQL-текст запроса для выполнения</param>
        /// <returns>Набор результата запроса (только первая колонка в виде строки)</returns>
        [SqlFunction(
            FillRowMethodName = "ExecuteSimpleFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable ExecuteSimple(SqlChars connectionString, SqlChars queryText)
        {
            List<ExecuteSimpleRowResult> resultRows = new List<ExecuteSimpleRowResult>();

            string connectionStringValue = new string(connectionString.Value);
            string queryTextValue = new string(queryText.Value);

            using (var connection = new ClickHouseConnection(connectionStringValue))
            {
                using (var reader = connection.ExecuteReaderAsync(queryTextValue)
                    .GetAwaiter().GetResult())
                {
                    while(reader.Read())
                    {
                        resultRows.Add(new ExecuteSimpleRowResult()
                        {
                            ResultValue = ConvertTypeToSqlCommandType(reader.GetValue(0)).ToString()
                        });                        
                    }
                }
            }

            return resultRows;
        }
        public static void ExecuteSimpleFillRow(object resultRow, out SqlChars rowValue)
        {
            var resultRowObject = (ExecuteSimpleRowResult)resultRow;
            rowValue = new SqlChars(resultRowObject.ResultValue);
        }

        /// <summary>
        /// Выполнение команды к ClickHouse без получения результата
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="queryText">SQL-текст команды</param>
        [SqlProcedure]
        public static void ExecuteStatement(SqlChars connectionString, SqlChars queryText)
        {
            string connectionStringValue = new string(connectionString.Value);
            string queryTextValue = new string(queryText.Value);

            using (var connection = new ClickHouseConnection(connectionStringValue))
            {
                var queryResult = connection.ExecuteStatementAsync(queryTextValue)
                    .GetAwaiter().GetResult();
            }
        }

        /// <summary>
        /// Функция для получения текста запроса создания временной таблицы 
        /// для сохранения результата запроса к ClickHouse
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="queryText">SQL-текст запроса для выполнения</param>
        /// <returns>Текст SQL-запроса для создания временной таблицы результата запроса</returns>
        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlChars GetCreateTempDbTableCommand(SqlChars connectionString, SqlChars queryText, SqlChars tempTableName)
        {
            string connectionStringValue = new string(connectionString.Value);
            string queryTextValue = new string(queryText.Value);
            // Устанавливаем LIMIT 0, чтобы запрос не возвращал результата.
            // Используется только для анализа схемы данных.
            string regexLimitStmt = @"limit[ ][\d]+";
            if (Regex.IsMatch(queryTextValue, regexLimitStmt, RegexOptions.IgnoreCase))
            {
                queryTextValue = Regex.Replace(queryTextValue, regexLimitStmt, "LIMIT 0", RegexOptions.IgnoreCase);
            } else
            {
                queryTextValue = queryTextValue + "\n LIMIT 0";
            }

            string tempTableNameValue = new string(tempTableName.Value);
            if (!tempTableNameValue.StartsWith("#", StringComparison.InvariantCultureIgnoreCase))
            {
                throw new Exception("Temp table name should begin with # (local temp table) or ## (global temp table)");
            }

            string resultAsString;

            using (var connection = new ClickHouseConnection(connectionStringValue))
            {
                using (var reader = connection.ExecuteReaderAsync(queryTextValue)
                    .GetAwaiter().GetResult())
                {
                    // Анализ результата запроса и создание под него временной таблицы
                    StringBuilder queryCreateTempTable = new StringBuilder();
                    queryCreateTempTable.Append("CREATE TABLE ");
                    queryCreateTempTable.Append(tempTableNameValue);
                    queryCreateTempTable.Append(" (\n");
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        string fieldName = reader.GetName(i);
                        Type fieldType = reader.GetFieldType(i);
                        int fieldNumber = i + 1;

                        queryCreateTempTable.Append("   [");
                        queryCreateTempTable.Append(fieldName);
                        queryCreateTempTable.Append("] ");
                        queryCreateTempTable.Append(ConvertClickHouseTypeToSqlType(fieldType, fieldName));

                        if (fieldNumber != reader.FieldCount)
                        {
                            queryCreateTempTable.Append(",");
                        }

                        queryCreateTempTable.Append("\n");
                    }
                    queryCreateTempTable.Append(")");

                    resultAsString = queryCreateTempTable.ToString();
                }
            }

            return new SqlChars(resultAsString);
        }
        
        /// <summary>
        /// Выполнение запроса к ClickHouse с сохранением результата во временную локальную таблицу
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="queryText">SQL-текст команды</param>
        /// <param name="tempTableName">Имя временной таблицы для сохранения результата</param>
        [SqlProcedure]
        public static void ExecuteToTempTable(SqlChars connectionString, SqlChars queryText, SqlChars tempTableName)
        {
            string tempTableNameValue = new string(tempTableName.Value);
            
            if(!tempTableNameValue.StartsWith("#", StringComparison.InvariantCultureIgnoreCase))
            {
                throw new Exception("Temp table name should begin with # (local temp table)");
            }
            if (tempTableNameValue.StartsWith("##", StringComparison.InvariantCultureIgnoreCase))
            {
                throw new Exception("Temp table name should begin with # (local temp table). Global temp table with ## not supported by this method.");
            }

            ExecuteToTempTableInternal(connectionString, queryText, tempTableName, _emptyString);
        }

        /// <summary>
        /// Выполнение запроса к ClickHouse с сохранением результата во временную глобальную таблицу
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="queryText">SQL-текст команды</param>
        /// <param name="tempTableName">Имя временной таблицы для сохранения результата</param>
        /// <param name="sqlServerConnectionString">Строка подключения к SQL Server для выполнения BULK INSERT.
        /// Если передана пустая строка, то вставка во временную таблицу будет выполняться обычными инструкциями INSERT.
        /// </param>
        [SqlProcedure]
        public static void ExecuteToGlobalTempTable(SqlChars connectionString, SqlChars queryText, SqlChars tempTableName, SqlChars sqlServerConnectionString)
        {
            string tempTableNameValue = new string(tempTableName.Value);

            if (!tempTableNameValue.StartsWith("##", StringComparison.InvariantCultureIgnoreCase))
            {
                throw new Exception("Temp table name should begin with ## (global temp table).");
            }

            ExecuteToTempTableInternal(connectionString, queryText, tempTableName, sqlServerConnectionString);
        }

        /// <summary>
        /// Операция массовой вставки данных из временной таблицы SQL Server
        /// в таблицу ClickHouse
        /// </summary>
        /// <param name="connectionString">Строка подключения к ClickHouse</param>
        /// <param name="sourceTempTableName">Имя временной таблицы с исходными данными</param>
        /// <param name="destinationTableName">Имя таблицы ClickHouse для вставки данных</param>
        [SqlProcedure]
        public static void ExecuteBulkInsertFromTempTable(SqlChars connectionString, SqlChars sourceTempTableName, SqlChars destinationTableName)
        {
            string connectionStringValue = new string(connectionString.Value);
            string sourceTempTableNameValue = new string(sourceTempTableName.Value);
            string destinationTableNameValue = new string(destinationTableName.Value);


            using (SqlConnection sqlConnection = GetSqlConnection())
            {
                if (sqlConnection.State != ConnectionState.Open)
                {
                    sqlConnection.Open();
                }

                List<object[]> rowsForInsert = new List<object[]>();

                string tempTableSelectQuery =
                    @"
SELECT * FROM " + sourceTempTableNameValue + @"
";
                using (SqlCommand tempTableReader = new SqlCommand(tempTableSelectQuery, sqlConnection))
                {
                    tempTableReader.CommandType = CommandType.Text;

                    using (var reader = tempTableReader.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            object[] rowValues = new object[reader.FieldCount];
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                var columnValue = reader.GetValue(i);
                                rowValues[i] = columnValue;
                            }
                            rowsForInsert.Add(rowValues);
                        }
                    }
                }

                using (var connection = new ClickHouseConnection(connectionStringValue))
                {
                    using (var bulkCopy = new ClickHouseBulkCopy(connection)
                           {
                               DestinationTableName = destinationTableNameValue,
                               BatchSize = 100000,
                               MaxDegreeOfParallelism = 1
                           })
                    {
                        bulkCopy.InitAsync().GetAwaiter().GetResult();
                        bulkCopy.WriteToServerAsync(rowsForInsert).GetAwaiter().GetResult();
                    }
                }
            }
        }
        
        private static SqlConnection GetSqlConnection()
        {
            if (DebugConnection == null)
            {
                return new SqlConnection(ConnectionString);
            }

            return DebugConnection;
        }
        private static bool SQLServerBulkInsertAvailable(DbDataReader reader, string destinationTableName, string sqlServerConnectionString = "")
        {
            // Должна быть заполнена строка подключения к SQL Server для BULK-операций, т.к. контекстное подключение
            // не позволяет их выполнять
            if (string.IsNullOrEmpty(sqlServerConnectionString))
            {
                return false;
            }

            // Проверка допустимых типов
            bool arrayDetected = false;
            bool dictionaryDetected = false;
            bool tupleDetected = false;
            for (int i = 0; i < reader.FieldCount; i++)
            {
                var fieldType = reader.GetFieldType(i);

                arrayDetected = arrayDetected || fieldType.IsArray;
                dictionaryDetected = dictionaryDetected || IsDictionary(fieldType);
                tupleDetected = tupleDetected || IsTupleType(fieldType);
            }
            if (arrayDetected || dictionaryDetected || tupleDetected)
            {
                return false;
            }

            // BULK-операции доступны только для глобальных временных таблиц.
            if (!destinationTableName.StartsWith("##"))
            {
                return false;
            }

            return true;
        }
        private static void ExecuteToTempTableInternal(SqlChars connectionString, SqlChars queryText, SqlChars tempTableName, SqlChars sqlServerConnectionString)
        {
            string connectionStringValue = new string(connectionString.Value);
            string queryTextValue = new string(queryText.Value);
            string tempTableNameValue = new string(tempTableName.Value);
            string sqlServerConnectionStringValue = new string(sqlServerConnectionString.Value);

            SqlConnection sqlConnection = GetSqlConnection();
            if (sqlConnection.State != ConnectionState.Open)
            {
                sqlConnection.Open();
            }

            // Проверяем наличие созданной временной таблицы
            bool tempTableExists = false;
            StringBuilder checkTempTableExists = new StringBuilder();
            checkTempTableExists.Append("SELECT\n");
            checkTempTableExists.Append("   CASE WHEN OBJECT_ID('tempdb..");
            checkTempTableExists.Append(tempTableNameValue);
            checkTempTableExists.Append("') IS NULL\n");
            checkTempTableExists.Append("       THEN CAST(0 as bit)\n");
            checkTempTableExists.Append("       ELSE CAST(1 as bit)\n");
            checkTempTableExists.Append("END AS [TempTableExists]\n");
            using (SqlCommand command = new SqlCommand(checkTempTableExists.ToString(), sqlConnection))
            {
                command.CommandType = CommandType.Text;
                var checkResult = command.ExecuteScalar();
                tempTableExists = (bool)checkResult;
            }

            // Создаем временную таблицу, если она не была создана ранее
            if (!tempTableExists)
            {
                StringBuilder createTempTableIfNotExists = new StringBuilder();
                createTempTableIfNotExists.Append("IF(OBJECT_ID('tempdb..");
                createTempTableIfNotExists.Append(tempTableNameValue);
                createTempTableIfNotExists.Append("') IS NULL)\n");
                createTempTableIfNotExists.AppendLine("BEGIN");
                createTempTableIfNotExists.Append(
                    new string(GetCreateTempDbTableCommand(connectionString, queryText, tempTableName).Value));
                createTempTableIfNotExists.AppendLine("END");
                using (SqlCommand command = new SqlCommand(createTempTableIfNotExists.ToString(), sqlConnection))
                {
                    command.CommandType = CommandType.Text;
                    command.ExecuteNonQuery();
                }
            }

            using (var connection = new ClickHouseConnection(connectionStringValue))
            {
                using (var reader = connection.ExecuteReaderAsync(queryTextValue)
                           .GetAwaiter().GetResult())
                {
                    if (SQLServerBulkInsertAvailable(reader, tempTableNameValue, sqlServerConnectionStringValue))
                    {
                        WindowsImpersonationContext impersonatedIdentity = null;
                        if (SqlContext.IsAvailable)
                        {
                            WindowsIdentity currentIdentity = SqlContext.WindowsIdentity;
                            impersonatedIdentity = currentIdentity.Impersonate();
                        }

                        try
                        {
                            using (SqlConnection bulkInsertConnection = new SqlConnection(sqlServerConnectionStringValue))
                            {
                                bulkInsertConnection.Open();
                                using (SqlBulkCopy bc = new SqlBulkCopy(bulkInsertConnection))
                                {
                                    bc.DestinationTableName = tempTableNameValue;
                                    bc.WriteToServer(reader);
                                }
                                bulkInsertConnection.Close();
                            }
                        }
                        finally
                        {
                            if (impersonatedIdentity != null)
                            {
                                impersonatedIdentity.Undo();
                            }
                        }
                    }
                    else
                    {
                        #region InsertTempDbTable

                        StringBuilder queryInsertToTempTable = new StringBuilder();
                        queryInsertToTempTable.Append("INSERT INTO ");
                        queryInsertToTempTable.Append(tempTableNameValue);
                        queryInsertToTempTable.Append(" VALUES (");
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            int fieldNumber = i + 1;
                            queryInsertToTempTable.Append("@P");
                            queryInsertToTempTable.Append(fieldNumber);
                            if (fieldNumber != reader.FieldCount)
                            {
                                queryInsertToTempTable.Append(",");
                            }

                            queryInsertToTempTable.Append("\n");
                        }

                        queryInsertToTempTable.Append(")");

                        using (SqlCommand command = new SqlCommand(queryInsertToTempTable.ToString(), sqlConnection))
                        {
                            command.CommandType = CommandType.Text;

                            while (reader.Read())
                            {
                                command.Parameters.Clear();
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    object fieldValue = reader.GetValue(i);
                                    int fieldNumber = i + 1;
                                    command.Parameters.AddWithValue($"@P{fieldNumber}",
                                        ConvertTypeToSqlCommandType(fieldValue));
                                }

                                command.ExecuteNonQuery();
                            }
                        }

                        #endregion
                    }
                }
            }
        }
        private static string ConvertClickHouseTypeToSqlType(Type sourceType, string sourceName)
        {
            Type typeForSearch = sourceType;
            if (sourceType.IsArray)
            {
                sourceType = typeof(Array);
            }
            else if (IsDictionary(sourceType))
            {
                sourceType = typeof(DictionaryBase);
            }
            else if (IsTupleType(sourceType))
            {
                sourceType = typeof(Tuple);
            }

            if (TypeConverters.TryGetValue(sourceType, out var convertFunc))
            {
                return convertFunc(sourceName, sourceType);
            }
            else
            {
                throw new InvalidCastException($"Can't find type converter from {sourceType.Name}");
            }
        }
        private static object ConvertTypeToSqlCommandType(object sourceValue)
        {
            object prepearedValue;
            Type sourceType = sourceValue.GetType();

            if (sourceType.IsArray)
            {
                prepearedValue = JsonConvert.SerializeObject(sourceValue);
            }
            else if (IsDictionary(sourceType))
            {
                prepearedValue = JsonConvert.SerializeObject(sourceValue);
            }
            else if (IsTupleType(sourceType))
            {
                prepearedValue = JsonConvert.SerializeObject(sourceValue);
            }
            else
            {
                if (sourceValue is UInt16 || sourceValue is UInt32 || sourceValue is Int16)
                {
                    prepearedValue = Convert.ToInt32(sourceValue);
                }
                else if (sourceValue is UInt64)
                {
                    prepearedValue = Convert.ToDecimal(sourceValue);
                }
                else if (sourceValue is byte)
                {
                    prepearedValue = Convert.ToInt32(sourceValue);
                }
                else if (sourceValue is IPAddress)
                {
                    prepearedValue = sourceValue.ToString();
                }
                else if (sourceValue is string
                         || sourceValue is decimal
                         || sourceValue is DateTime
                         || sourceValue is Guid)
                {
                    prepearedValue = sourceValue;
                }
                else if (sourceValue is DateTimeOffset offset)
                {
                    prepearedValue = offset.UtcDateTime;
                }
                else
                {
                    prepearedValue = JsonConvert.SerializeObject(sourceValue);
                }
            }

            return prepearedValue;
        }
        private static bool IsTupleType(Type type, bool checkBaseTypes = false)
        {
            if (type == null)
                throw new ArgumentNullException(nameof(type));

            if (type == typeof(Tuple))
                return true;

            while (type != null)
            {
                if (type.IsGenericType)
                {
                    var genType = type.GetGenericTypeDefinition();
                    if (genType == typeof(Tuple<>)
                        || genType == typeof(Tuple<,>)
                        || genType == typeof(Tuple<,,>)
                        || genType == typeof(Tuple<,,,>)
                        || genType == typeof(Tuple<,,,,>)
                        || genType == typeof(Tuple<,,,,,>)
                        || genType == typeof(Tuple<,,,,,,>)
                        || genType == typeof(Tuple<,,,,,,,>)
                        || genType == typeof(Tuple<,,,,,,,>))
                        return true;
                }

                if (!checkBaseTypes)
                    break;

                type = type.BaseType;
            }

            return false;
        }
        private static bool IsDictionary(Type type)
        {
            return type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Dictionary<,>);
        }
    }
}
