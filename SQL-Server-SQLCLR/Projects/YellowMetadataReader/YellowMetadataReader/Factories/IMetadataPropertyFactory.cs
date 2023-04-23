using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Factories
{
    public interface IMetadataPropertyFactory
    {
        string GetPropertyName(SqlFieldInfo field);
        DatabaseField CreateField(SqlFieldInfo field);
        MetadataProperty CreateProperty(ApplicationObject owner, string name, SqlFieldInfo field);
    }
}
