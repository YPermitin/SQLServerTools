using System;
using System.Collections;
using Microsoft.SqlServer.Server;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Data;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Services;
using System.Linq;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;

namespace YPermitin.SQLCLR.YellowMetadataReader
{
    public  sealed class EntryMetadata : EntryBase
    {
        #region SqlQueries

        private const string QueryDatabaseList = "select [name] from sys.databases where NOT [name] in ('master', 'tempdb', 'model', 'msdb')";

        #endregion

        #region Infobases

        /// <summary>
        /// Получения списка баз, которые относятся к базам платформы 1С.
        ///
        /// Для каждой базы отображается информация о конфигурации
        /// и дате последнего обновления информационной базы из конфигуратора.
        /// </summary>
        /// <returns></returns>
        [SqlFunction(
            FillRowMethodName = "GetInfobasesFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetInfobases()
        {
            // Имена баз данных, которые относятся к базам платформы 1С
            List<string> infobasesNames = new List<string>();

            using (SqlConnection connection = new SqlConnection(ConnectionString))
            {
                connection.Open();

                // Получаем все имена баз данных на текущем экземпляре (кроме системных баз)
                List<string> allDatabaseNames = new List<string>();
                using (SqlCommand command = new SqlCommand(QueryDatabaseList, connection))
                {
                    command.CommandType = CommandType.Text;
                    using (var commandResult = command.ExecuteReader())
                    {
                        while (commandResult.Read())
                        {
                            string databaseName = commandResult.GetString(0);
                            allDatabaseNames.Add(databaseName);
                        }
                    }
                }

                // Кажду базу проверяем на наличие системных таблиц
                // 'IBVersion','Params','v8users', 'Config', 'DBSchema'.
                // Если все таблицы присутствуют, то считаем эту базы принадлежащей платформе 1С.
                foreach (var database in allDatabaseNames)
                {
                    try
                    {
                        List<string> internalTables1C = new List<string>();
                        string queryIsInfobase1C =
@"select 
	[name] 
from [" + database + @"].[sys].[tables]
where [name] in ('IBVersion','Params','v8users', 'Config', 'DBSchema')";
                        using (SqlCommand command = new SqlCommand(queryIsInfobase1C, connection))
                        {
                            command.CommandType = CommandType.Text;
                            using (var commandResult = command.ExecuteReader())
                            {
                                while (commandResult.Read())
                                {
                                    string internalTableName = commandResult.GetString(0);
                                    internalTables1C.Add(internalTableName);
                                }
                            }
                        }

                        // Если были обнаружены все 5 таблиц из списка,
                        // то добавляем базу в список для анализа
                        if (internalTables1C.Count == 5)
                        {
                            infobasesNames.Add(database);
                        }
                    }
                    catch
                    {
                        // ignored
                        // Любые ошибки обработки игнорируем. Базу данных, на которой возникла ошибка,
                        // пропускаем
                    }
                }
            }

            // Читаем информацию о информационной базе и ее конфигурации
            List<InfobaseInfo> infobases = new List<InfobaseInfo>();
            foreach (var infobaseName in infobasesNames)
            {
                try
                {
                    IMetadataService svc = new MetadataService();
                    svc.UseConnectionString(ConnectionString);
                    svc.UseDatabaseName(infobaseName);
                    var infobase = svc.OpenInfoBase(OpenInfobaseLevel.ConfigInfoOnly);

                    infobases.Add(new InfobaseInfo()
                    {
                        Name = infobaseName,
                        ConfigVersion = infobase.ConfigInfo.ConfigVersion,
                        ConfigAlias = infobase.ConfigInfo.Alias,
                        ConfigName = infobase.ConfigInfo.Name,
                        ConfigUiCompatibilityMode = infobase.ConfigInfo.UiCompatibilityMode.ToString(),
                        PlatformVersion = infobase.ConfigInfo.Version.ToString()
                    });
                }
                catch
                {
                    // Пропускаем без ошибок, т.к. скорее всего содержимое базы некорреткно
                }
            }

            // Дополняем информацию датой последнего обновления
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            {
                connection.Open();

                foreach (var infobase in infobases)
                {
                    string queryLastUpdateDate =
@"
IF (EXISTS (SELECT * 
			FROM [" + infobase.Name + @"].[sys].[tables] t
			WHERE t.[name] = 'Config'))
BEGIN
	SELECT
		CASE
			WHEN ldt.LastUpdate > '4000-01-01 00:00:00'
			THEN DATEADD(YEAR, -2000, ldt.LastUpdate)
			ELSE ldt.LastUpdate
		END AS [LastUpdate]
	        FROM
		        (SELECT 	
		            CASE 
				WHEN MAX([Creation]) > MAX([Modified])
			        THEN MAX([Creation])
			        ELSE MAX([Modified])
		        	END AS [LastUpdate]
	FROM [" + infobase.Name + @"].[dbo].[Config] WITH(NOLOCK)) AS [ldt]
END ELSE BEGIN
	SELECT NULL AS [LastUpdate]
END
";
                    try
                    {
                        using (SqlCommand command = new SqlCommand(queryLastUpdateDate, connection))
                        {
                            command.CommandType = CommandType.Text;
                            using (var commandResult = command.ExecuteReader())
                            {
                                while (commandResult.Read())
                                {
                                    DateTime? lastUpdate = commandResult.GetDateTime(0);
                                    infobase.InfobaseLastUpdate = lastUpdate;
                                }
                            }
                        }
                    }
                    catch
                    {
                        // ignored
                    }
                }
            }

            return infobases;
        }

        public static void GetInfobasesFillRow(object source, out SqlChars infobaseName, out SqlChars configVersion,
            out SqlChars configAlias, out SqlChars configName, out SqlChars configUiCompatibilityMode, 
            out SqlChars platformVersion, out SqlDateTime lastUpdate)
        {
            var sourceObject = (InfobaseInfo)source;
            infobaseName = new SqlChars(sourceObject.Name);
            configVersion = new SqlChars(sourceObject.ConfigVersion);
            configAlias = new SqlChars(sourceObject.ConfigAlias);
            configName = new SqlChars(sourceObject.ConfigName);
            configUiCompatibilityMode = new SqlChars(sourceObject.ConfigUiCompatibilityMode);
            platformVersion = new SqlChars(sourceObject.PlatformVersion);
            if (sourceObject.InfobaseLastUpdate == null ||
                sourceObject.InfobaseLastUpdate <= SqlDateTime.MinValue.Value)
            {
                lastUpdate = SqlDateTime.MinValue.Value;
            }
            else
            {
                lastUpdate = new SqlDateTime(sourceObject.InfobaseLastUpdate ?? SqlDateTime.MinValue.Value);
            }
        }

        public class InfobaseInfo
        {
            public string Name { get; set; }
            public string ConfigName { get; set; }
            public string ConfigAlias { get; set; }
            public string ConfigVersion { get; set; }
            public string PlatformVersion { get; set; }
            public string ConfigUiCompatibilityMode { get; set; }
            public DateTime? InfobaseLastUpdate { get; set; }
        }

        #endregion

        #region InfobaseTables

        /// <summary>
        /// Получение списка таблиц информационной базы в терминах прикладного решения
        /// </summary>
        /// <returns></returns>
        [SqlFunction(
            FillRowMethodName = "GetInfobaseTablesFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetInfobaseTables(string databaseName)
        {
            IMetadataService svc = new MetadataService();
            svc.UseConnectionString(ConnectionString);
            svc.UseDatabaseName(databaseName);

            var infobase = svc.OpenInfoBase();

            var allObjects = infobase.AllTypes
                .SelectMany(e => e.Value.Values)
                .ToList();

            return allObjects
                .Union(allObjects.SelectMany(e => e.TableParts))
                .Union(allObjects.SelectMany(e => e.NestedObjects))
                .ToList();
        }
        public static void GetInfobaseTablesFillRow(object source, out SqlChars tableSQL, out SqlChars table1C)
        {
            var sourceObject = (ApplicationObject)source;
            tableSQL = new SqlChars(sourceObject.TableName);
            table1C = new SqlChars(sourceObject.MetadataName);
        }

        #endregion

        #region InfobaseTablesWithFields

        /// <summary>
        /// Получение списка таблиц с полями информационной базы в терминах прикладного решения
        /// </summary>
        /// <returns></returns>
        [SqlFunction(
            FillRowMethodName = "GetInfobaseTablesWithFieldsFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetInfobaseTablesWithFields(string databaseName)
        {
            IMetadataService svc = new MetadataService();
            svc.UseConnectionString(ConnectionString);
            svc.UseDatabaseName(databaseName);

            var infobase = svc.OpenInfoBase();

            var allObjects = infobase.AllTypes
                .SelectMany(e => e.Value.Values)
                .Union(
                    infobase.AllTypes
                        .SelectMany(e => e.Value.Values)
                        .SelectMany(e => e.NestedObjects))
                .ToList();

            List<InfobaseTableFieldInfo> output = new List<InfobaseTableFieldInfo>();

            foreach (ApplicationObject objectItem in allObjects)
            {
                foreach (var propertyItem in objectItem.Properties)
                {
                    output.Add(new InfobaseTableFieldInfo()
                    {
                        TableSQL = objectItem.TableName,
                        Table1C = objectItem.MetadataName,
                        FieldSQL = propertyItem.DbName,
                        Field1C = propertyItem.Name
                    });
                }

                foreach (var tablePartItem in objectItem.TableParts)
                {
                    foreach (var propertyItemForTable in tablePartItem.Properties)
                    {
                        output.Add(new InfobaseTableFieldInfo()
                        {
                            TableSQL = tablePartItem.TableName,
                            Table1C = tablePartItem.MetadataName,
                            FieldSQL = propertyItemForTable.DbName,
                            Field1C = propertyItemForTable.Name
                        });
                    }
                }
            }

            return output;
        }
        
        public static void GetInfobaseTablesWithFieldsFillRow(object source,
            out SqlChars tableSQL, out SqlChars table1C,
            out SqlChars fieldSQL, out SqlChars field1C)
        {
            var sourceObject = (InfobaseTableFieldInfo)source;
            tableSQL = new SqlChars(sourceObject.TableSQL);
            table1C = new SqlChars(sourceObject.Table1C);
            fieldSQL = new SqlChars(sourceObject.FieldSQL);
            field1C = new SqlChars(sourceObject.Field1C);
        }

        public class InfobaseTableFieldInfo
        {
            public string TableSQL { get; set; }
            public string Table1C { get; set; }
            public string FieldSQL { get; set; }
            public string Field1C { get; set; }
        }

        #endregion

        #region InfobaseEnumerations

        /// <summary>
        /// Получения списка перечислений информационной базы с их значениями в терминах прикладного решения
        /// </summary>
        /// <returns></returns>
        [SqlFunction(
            FillRowMethodName = "GetInfobasesEnumerationsFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetInfobasesEnumerations(string databaseName)
        {
            IMetadataService svc = new MetadataService();
            svc.UseConnectionString(ConnectionString);
            svc.UseDatabaseName(databaseName);
            var infobase = svc.OpenInfoBase();

            var allEnumerations = infobase.Enumerations
                .Where(e => e.Value is Enumeration)
                .Select(e => (Enumeration)e.Value)
                .ToList();

            List<InfobaseEnumerationField> output = new List<InfobaseEnumerationField>();

            foreach (Enumeration enumerationItem in allEnumerations)
            {
                foreach (var valueItem in enumerationItem.Values)
                {
                    output.Add(new InfobaseEnumerationField()
                    {
                        TableSQL = enumerationItem.TableName,
                        Enumeration = enumerationItem.MetadataName,
                        ValueId = valueItem.Uuid.ToString(),
                        ValueOrder = valueItem.OrderNumber,
                        ValueName = valueItem.Name,
                        ValueAlias = valueItem.Alias
                    });
                }
            }

            return output;
        }

        public static void GetInfobasesEnumerationsFillRow(object source,
            out SqlChars tableSQL, out SqlChars table1C,
            out SqlChars valueId, out SqlChars valueName, out SqlChars valueAlias,
            out SqlInt32 orderNumber)
        {
            var sourceObject = (InfobaseEnumerationField)source;
            tableSQL = new SqlChars(sourceObject.TableSQL);
            table1C = new SqlChars(sourceObject.Enumeration);
            valueId = new SqlChars(sourceObject.ValueId);
            orderNumber = new SqlInt32(sourceObject.ValueOrder);
            valueName = new SqlChars(sourceObject.ValueName);
            valueAlias = new SqlChars(sourceObject.ValueAlias);
        }

        public class InfobaseEnumerationField
        {
            public string TableSQL { get; set; }
            public string Enumeration { get; set; }
            public string ValueId { get; set; }
            public int ValueOrder { get; set; }
            public string ValueName { get; set; }
            public string ValueAlias { get; set; }
        }

        #endregion

        #region InternalFormatData

        [SqlFunction]
        public static string ParseInternalString(byte[] data)
        {
            try
            {
                return InternalFormatReader.ParseToString(data);
            }
            catch (Exception e)
            {
                return $"Error: {e}";
            }
        }

        #endregion
    }
}
