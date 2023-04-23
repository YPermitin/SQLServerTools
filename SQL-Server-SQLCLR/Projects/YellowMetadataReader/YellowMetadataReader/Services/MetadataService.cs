using System.IO;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    public class MetadataService : IMetadataService
    {
        private readonly IConfigFileReader _configFileReader;
        private readonly ISqlMetadataReader _sqlMetadataReader;

        public string ConnectionString { get; private set; } = string.Empty;
        public string DatabaseName { get; private set; } = string.Empty;

        public MetadataService()
        {
            _configFileReader = new ConfigFileReader();
            _sqlMetadataReader = new SqlMetadataReader();
        }

        public IMetadataService UseConnectionString(string connectionString)
        {
            ConnectionString = connectionString;
            _sqlMetadataReader.UseConnectionString(ConnectionString);
            _configFileReader.UseConnectionString(ConnectionString);
            return this;
        }

        public IMetadataService UseDatabaseName(string databaseName)
        {
            DatabaseName = databaseName;

            _sqlMetadataReader.UseConnectionString(ConnectionString);
            _sqlMetadataReader.UseDatabaseName(DatabaseName);

            _configFileReader.UseConnectionString(ConnectionString);
            _configFileReader.UseDatabaseName(DatabaseName);

            return this;
        }

        public IMetadataService ConfigureConnectionString(string server, string database, string userName, string password)
        {
            _configFileReader.ConfigureConnectionString(server, database, userName, password);
            ConnectionString = _configFileReader.ConnectionString;
            _sqlMetadataReader.UseConnectionString(ConnectionString);
            return this;
        }

        public InfoBase OpenInfoBase(OpenInfobaseLevel level = OpenInfobaseLevel.ConfigFull)
        {
            Configurator configurator = new Configurator(_configFileReader, _sqlMetadataReader);
            return configurator.OpenInfoBase(level);
        }

        public byte[] ReadConfigFile(string fileName)
        {
            return _configFileReader.ReadBytes(fileName);
        }

        public StreamReader CreateReader(byte[] fileData)
        {
            return _configFileReader.CreateDeflateReader(fileData);
        }
    }
}
