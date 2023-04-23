using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    public interface ISqlMetadataReader
    {
        string ConnectionString { get; }
        string DatabaseName { get; }
        void UseConnectionString(string connectionString);
        void UseDatabaseName(string databaseName);

        void ConfigureConnectionString(string server, string database, string userName, string password);
        List<SqlFieldInfo> GetSqlFieldsOrderedByName(string tableName);
    }
}
