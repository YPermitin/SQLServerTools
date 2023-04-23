using System;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.IO;
using System.IO.Compression;
using System.Text;
using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    /// <summary>
    /// Интерфейс для чтения файлов конфигурации 1С из таблиц IBVersion, DBSchema, Params и Config
    /// </summary>
    public interface IConfigFileReader
    {
        ///<summary>Возвращает установленную ранее строку подключения к базе данных 1С</summary>
        string ConnectionString { get; }
        string DatabaseName { get; }

        ///<summary>Устанавливает строку подключения к базе данных 1С</summary>
        ///<param name="connectionString">Строка подключения к базе данных 1С</param>
        void UseConnectionString(string connectionString);
        void UseDatabaseName(string databaseName);

        ///<summary>Формирует строку подключения к базе данных 1С по параметрам</summary>
        ///<param name="server">Имя или сетевой адрес сервера SQL Server</param>
        ///<param name="database">Имя базы данных SQL Server</param>
        ///<param name="userName">Имя пользователя (если не указано, используется Windows аутентификация)</param>
        ///<param name="password">Пароль пользователя SQL Server (используется только в случае SQL Server аутентификации)</param>
        void ConfigureConnectionString(string server, string database, string userName, string password);

        ///<summary>Получает требуемую версию платформы 1С для работы с базой данных</summary>
        ///<returns>Требуемая версия платформы 1С</returns>
        int GetPlatformRequiredVersion();

        ///<summary>Получает количество лет, используемое платформой 1С, для добавления к значениям дат</summary>
        ///<returns>Количество лет, добавляемое к датам. Значения по умолчанию: SQL Server = 2000, PostrgeSQL = 0.</returns>
        int GetYearOffset();

        ///<summary>Получает файл метаданных в "сыром" (как есть) бинарном виде</summary>
        ///<param name="fileName">Имя файла метаданных: root, DBNames или значение UUID</param>
        ///<returns>Бинарные данные файла метаданных</returns>
        byte[] ReadBytes(string fileName);
        byte[] ReadParamsFile(string fileName);
        byte[] ReadConfigFile(string fileName);

        ///<summary>Функция определяет является ли форматом файла метаданных UTF-8</summary>
        ///<param name="fileData">Бинарные данные файла метаданных</param>
        ///<returns>true - формат файла UTF-8; false - формат файла другой (deflate)</returns>
        bool IsUtf8(byte[] fileData);

        StreamReader CreateReader(byte[] fileData);
        StreamReader CreateStreamReader(byte[] fileData);
        ///<summary>Распаковывает файл метаданных по алгоритму deflate и создаёт поток для чтения в формате UTF-8</summary>
        ///<param name="fileData">Бинарные данные файла метаданных</param>
        ///<returns>Поток для чтения файла метаданных в формате UTF-8</returns>
        StreamReader CreateDeflateReader(byte[] fileData);

        ///<summary>Читает файл конфигурации и формирует его данные в виде древовидной структуры</summary>
        /// <param name="fileName">Имя файла метаданных: root, DBNames, DBSchema или UUID файла</param>
        /// <returns>Дерево значений файла конфигурации</returns>
        ConfigObject ReadConfigObject(string fileName);

        string ReadConfigObjectAsString(string fileName);
    }

    /// <summary>
    /// Класс для чтения файлов конфигурации 1С из SQL Server
    /// </summary>
    public sealed class ConfigFileReader : IConfigFileReader
    {
        #region "Constants"

        private const string RootFileName = "root"; // Config
        private const string DbnamesFileName = "DBNames"; // Params
        private const string DbschemaFileName = "DBSchema"; // DBSchema

        private const string MsIbversionQueryScript = "SELECT TOP 1 [PlatformVersionReq] FROM [{DatabaseName}].[dbo].[IBVersion];";
        private const string MsParamsQueryScript = "SELECT [BinaryData] FROM [{DatabaseName}].[dbo].[Params] WHERE [FileName] = @FileName;";
        private const string MsConfigQueryScript = "SELECT [BinaryData] FROM [{DatabaseName}].[dbo].[Config] WHERE [FileName] = @FileName;"; // Version 8.3 ORDER BY [PartNo] ASC";
        private const string MsDbschemaQueryScript = "SELECT TOP 1 [SerializedData] FROM [{DatabaseName}].[dbo].[DBSchema];";
        private const string MsYearoffsetQueryScript = "SELECT TOP 1 [Offset] FROM [{DatabaseName}].[dbo].[_YearOffset];";
        
        #endregion

        private readonly ConfigFileParser _fileParser = new ConfigFileParser();

        public string ConnectionString { get; private set; } = string.Empty;
        public string DatabaseName { get; private set; } = string.Empty;
        private byte[] CombineArrays(byte[] a1, byte[] a2)
        {
            if (a1 == null) return a2;

            byte[] result = new byte[a1.Length + a2.Length];
            Buffer.BlockCopy(a1, 0, result, 0, a1.Length);
            Buffer.BlockCopy(a2, 0, result, a1.Length, a2.Length);
            return result;
        }
        private DbConnection CreateDbConnection()
        {
            return new SqlConnection(ConnectionString);
        }
        private void ConfigureFileNameParameter(DbCommand command, string fileName)
        {
            if (string.IsNullOrWhiteSpace(fileName)) return;

            ((SqlCommand)command).Parameters.AddWithValue("FileName", fileName);
        }
        private T ExecuteScalar<T>(string script, string fileName)
        {
            T result = default(T);
            using (DbConnection connection = CreateDbConnection())
            using (DbCommand command = connection.CreateCommand())
            {
                command.CommandText = script.Replace("{DatabaseName}", DatabaseName);
                command.CommandType = CommandType.Text;
                ConfigureFileNameParameter(command, fileName);
                connection.Open();
                object value = command.ExecuteScalar();
                if (value != null)
                {
                    result = (T)value;
                }
            }
            return result;
        }
        private byte[] ExecuteReader(string script, string fileName)
        {
            byte[] fileData = null;
            using (DbConnection connection = CreateDbConnection())
            using (DbCommand command = connection.CreateCommand())
            {
                command.CommandText = script.Replace("{DatabaseName}", DatabaseName);
                command.CommandType = CommandType.Text;
                ConfigureFileNameParameter(command, fileName);
                connection.Open();
                using (DbDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        byte[] data = (byte[])reader[0];
                        fileData = CombineArrays(fileData, data);
                    }
                }
            }
            return fileData;
        }
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

        public int GetPlatformRequiredVersion()
        {
            return ExecuteScalar<int>(MsIbversionQueryScript, null);
        }
        public int GetYearOffset()
        {
            return ExecuteScalar<int>(MsYearoffsetQueryScript, null);
        }

        public bool IsUtf8(byte[] fileData)
        {
            if (fileData == null) throw new ArgumentNullException(nameof(fileData));

            if (fileData.Length < 3) return false;

            return fileData[0] == 0xEF  // (b)yte
                && fileData[1] == 0xBB  // (o)rder
                && fileData[2] == 0xBF; // (m)ark
        }
        public byte[] ReadBytes(string fileName)
        {
            switch (fileName)
            {
                case RootFileName:
                    return ExecuteReader(MsConfigQueryScript, fileName);
                case DbnamesFileName:
                    return ExecuteReader(MsParamsQueryScript, fileName);
                case DbschemaFileName:
                    return ExecuteReader(MsDbschemaQueryScript, fileName);
                default:
                    return ExecuteReader(MsConfigQueryScript, fileName);
            }
        }
        public byte[] ReadParamsFile(string fileName)
        {
            return ExecuteReader(MsParamsQueryScript, fileName);
        }
        public byte[] ReadConfigFile(string fileName)
        {
            return ExecuteReader(MsConfigQueryScript, fileName);
        }
        public StreamReader CreateReader(byte[] fileData)
        {
            if (IsUtf8(fileData))
            {
                return CreateStreamReader(fileData);
            }
            return CreateDeflateReader(fileData);
        }
        public StreamReader CreateStreamReader(byte[] fileData)
        {
            MemoryStream memory = new MemoryStream(fileData);
            return new StreamReader(memory, Encoding.UTF8);
        }
        public StreamReader CreateDeflateReader(byte[] fileData)
        {
            MemoryStream memory = new MemoryStream(fileData);
            DeflateStream stream = new DeflateStream(memory, CompressionMode.Decompress);
            
            return new StreamReader(stream, Encoding.UTF8);
        }
        public ConfigObject ReadConfigObject(string fileName)
        {
            byte[] fileData = ReadBytes(fileName);
            
            if (fileData == null)
            {
                return null; // file name is not found
            }

            using (StreamReader stream = CreateReader(fileData))
            {
                return _fileParser.Parse(stream);
            }
        }

        public string ReadConfigObjectAsString(string fileName)
        {
            byte[] fileData = ReadBytes(fileName);

            if (fileData == null)
            {
                return null; // file name is not found
            }

            StringBuilder dataAsString = new StringBuilder();

            using (StreamReader reader = CreateReader(fileData))
            {
                string stringLine;
                do
                {
                    stringLine = reader.ReadLine();
                    if (stringLine != null)
                    {
                        dataAsString.AppendLine(stringLine);
                    }
                } while (stringLine != null);
            }

            return dataAsString.ToString();
        }
    }
}