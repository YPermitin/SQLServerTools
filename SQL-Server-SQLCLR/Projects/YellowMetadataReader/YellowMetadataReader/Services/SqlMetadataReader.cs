using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
// ReSharper disable NotAccessedField.Local
// ReSharper disable InconsistentNaming

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    public class SqlMetadataReader : ISqlMetadataReader
    {
        private sealed class ClusteredIndexInfo
        {
            // ReSharper disable once EmptyConstructor
            public ClusteredIndexInfo() { }
            public string NAME;
            public bool IS_UNIQUE;
            public bool IS_PRIMARY_KEY;
            public readonly List<ClusteredIndexColumnInfo> COLUMNS = new List<ClusteredIndexColumnInfo>();
            public bool HasNullableColumns
            {
                get
                {
                    foreach (ClusteredIndexColumnInfo item in COLUMNS)
                    {
                        if (item.IS_NULLABLE)
                        {
                            return true;
                        }
                    }
                    return false;
                }
            }
            public ClusteredIndexColumnInfo GetColumnByName(string name)
            {
                for (int i = 0; i < COLUMNS.Count; i++)
                {
                    if (COLUMNS[i].NAME == name) return COLUMNS[i];
                }
                return null;
            }
        }
        private sealed class ClusteredIndexColumnInfo
        {
            public ClusteredIndexColumnInfo() { }
            public byte KEY_ORDINAL;
            public string NAME;
            public bool IS_NULLABLE;
        }
        public string ConnectionString { get; private set; } = string.Empty;
        public string DatabaseName { get; private set; } = string.Empty;
        public void UseConnectionString(string connectionString)
        {
            ConnectionString = connectionString;
        }
        public void UseDatabaseName(string databaseName)
        {
            DatabaseName = databaseName;
        }
        public void ConfigureConnectionString(string server, string database, string userName, string password)
        {
            ConfigureConnectionStringForSQLServer(server, database, userName, password);
        }
        private void ConfigureConnectionStringForSQLServer(string server, string database, string userName, string password)
        {
            SqlConnectionStringBuilder connectionString = new SqlConnectionStringBuilder()
            {
                DataSource = server,
                InitialCatalog = database
            };
            if (!string.IsNullOrWhiteSpace(userName))
            {
                connectionString.UserID = userName;
                connectionString.Password = password;
            }
            connectionString.IntegratedSecurity = string.IsNullOrWhiteSpace(userName);
            ConnectionString = connectionString.ToString();
        }
        

        private List<SqlFieldInfo> GetSqlFields(string tableName)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine(@"SELECT");
            sb.AppendLine(@"    ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE,");
            sb.AppendLine(@"    ISNULL(CHARACTER_MAXIMUM_LENGTH, 0) AS CHARACTER_MAXIMUM_LENGTH,");
            sb.AppendLine(@"    ISNULL(NUMERIC_PRECISION, 0) AS NUMERIC_PRECISION,");
            sb.AppendLine(@"    ISNULL(NUMERIC_SCALE, 0) AS NUMERIC_SCALE,");
            sb.AppendLine(@"    CASE WHEN IS_NULLABLE = 'NO' THEN CAST(0x00 AS bit) ELSE CAST(0x01 AS bit) END AS IS_NULLABLE");
            sb.AppendLine(@"FROM");
            sb.AppendLine(@"    [{DatabaseName}].[INFORMATION_SCHEMA].[COLUMNS]");
            sb.AppendLine(@"WHERE");
            sb.AppendLine(@"    TABLE_NAME = N'{0}'");
            sb.AppendLine(@"ORDER BY");
            sb.AppendLine(@"    ORDINAL_POSITION ASC;");

            string sql = string.Format(sb.ToString(), tableName);

            List<SqlFieldInfo> list = new List<SqlFieldInfo>();
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            {
                using (SqlCommand command = new SqlCommand(sql.Replace("{DatabaseName}", DatabaseName), connection))
                {
                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            SqlFieldInfo item = new SqlFieldInfo()
                            {
                                ORDINAL_POSITION = reader.GetInt32(0),
                                COLUMN_NAME = reader.GetString(1),
                                DATA_TYPE = reader.GetString(2),
                                CHARACTER_MAXIMUM_LENGTH = reader.GetInt32(3),
                                NUMERIC_PRECISION = reader.GetByte(4),
                                NUMERIC_SCALE = reader.GetByte(5),
                                IS_NULLABLE = reader.GetBoolean(6)
                            };
                            list.Add(item);
                        }
                    }
                }
            }
            return list;
        }
        private ClusteredIndexInfo GetClusteredIndexInfo(string tableName)
        {
            ClusteredIndexInfo info = null;

            StringBuilder sb = new StringBuilder();
            sb.AppendLine(@"SELECT");
            sb.AppendLine(@"    i.name,");
            sb.AppendLine(@"    i.is_unique,");
            sb.AppendLine(@"    i.is_primary_key,");
            sb.AppendLine(@"    c.key_ordinal,");
            sb.AppendLine(@"    f.name,");
            sb.AppendLine(@"    f.is_nullable");
            sb.AppendLine(@"FROM [{DatabaseName}].[sys].[indexes] AS i");
            sb.AppendLine(@"INNER JOIN [{DatabaseName}].[sys].[tables] AS t ON t.object_id = i.object_id");
            sb.AppendLine(@"INNER JOIN [{DatabaseName}].[sys].[index_columns] AS c ON c.object_id = t.object_id AND c.index_id = i.index_id");
            sb.AppendLine(@"INNER JOIN [{DatabaseName}].[sys].[columns] AS f ON f.object_id = t.object_id AND f.column_id = c.column_id");
            sb.AppendLine(@"WHERE");
            sb.AppendLine(@"    t.object_id = OBJECT_ID(@table) AND i.type = 1 -- CLUSTERED");
            sb.AppendLine(@"ORDER BY");
            sb.AppendLine(@"c.key_ordinal ASC;");
            string sql = sb.ToString().Replace("{DatabaseName}", DatabaseName);

            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                connection.Open();

                command.Parameters.AddWithValue("table", tableName);
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        info = new ClusteredIndexInfo()
                        {
                            NAME = reader.GetString(0),
                            IS_UNIQUE = reader.GetBoolean(1),
                            IS_PRIMARY_KEY = reader.GetBoolean(2)
                        };
                        info.COLUMNS.Add(new ClusteredIndexColumnInfo()
                        {
                            KEY_ORDINAL = reader.GetByte(3),
                            NAME = reader.GetString(4),
                            IS_NULLABLE = reader.GetBoolean(5)
                        });
                        while (reader.Read())
                        {
                            info.COLUMNS.Add(new ClusteredIndexColumnInfo()
                            {
                                KEY_ORDINAL = reader.GetByte(3),
                                NAME = reader.GetString(4),
                                IS_NULLABLE = reader.GetBoolean(5)
                            });
                        }
                    }
                }
            }
            return info;
        }

        private string SelectSqlFieldsOrderedByNameScript()
        {
            return MS_SelectSqlFieldsOrderedByNameScript();
        }
        private string MS_SelectSqlFieldsOrderedByNameScript()
        {
            StringBuilder script = new StringBuilder();
            script.AppendLine("SELECT");
            script.AppendLine("c.column_id AS ORDINAL_POSITION,");
            script.AppendLine("c.name AS COLUMN_NAME,");
            script.AppendLine("s.name AS DATA_TYPE,");
            script.AppendLine("c.max_length AS CHARACTER_OCTET_LENGTH,");
            script.AppendLine("c.max_length AS CHARACTER_MAXIMUM_LENGTH,"); // TODO: for nchar and nvarchar devide by 2
            script.AppendLine("c.precision AS NUMERIC_PRECISION,");
            script.AppendLine("c.scale AS NUMERIC_SCALE,");
            script.AppendLine("c.is_nullable AS IS_NULLABLE");
            script.AppendLine("FROM [{DatabaseName}].[sys].[tables] AS t");
            script.AppendLine("INNER JOIN [{DatabaseName}].[sys].[columns] AS c ON c.object_id = t.object_id");
            script.AppendLine("INNER JOIN [{DatabaseName}].[sys].[types] AS s ON c.user_type_id = s.user_type_id");
            script.AppendLine("WHERE t.object_id = OBJECT_ID(@tableName)");
            script.AppendLine("ORDER BY c.name ASC;");
            return script.ToString().Replace("{DatabaseName}", DatabaseName);
        }
        
        public List<SqlFieldInfo> GetSqlFieldsOrderedByName(string tableName)
        {
            return MS_GetSqlFieldsOrderedByName(tableName);
        }
        private List<SqlFieldInfo> MS_GetSqlFieldsOrderedByName(string tableName)
        {
            List<SqlFieldInfo> list = new List<SqlFieldInfo>();
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            using (SqlCommand command = new SqlCommand(SelectSqlFieldsOrderedByNameScript(), connection))
            {
                command.Parameters.AddWithValue("tableName", $"{DatabaseName}.dbo.{tableName}");
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        SqlFieldInfo item = new SqlFieldInfo();
                        item.ORDINAL_POSITION = reader.GetInt32(0);
                        item.COLUMN_NAME = reader.GetString(1);
                        item.DATA_TYPE = reader.GetString(2);
                        item.CHARACTER_OCTET_LENGTH = reader.GetInt16(3);
                        item.CHARACTER_MAXIMUM_LENGTH = reader.GetInt16(4);
                        item.NUMERIC_PRECISION = reader.GetByte(5);
                        item.NUMERIC_SCALE = reader.GetByte(6);
                        item.IS_NULLABLE = reader.GetBoolean(7);
                        list.Add(item);
                    }
                }
            }
            return list;
        }
    }
}
