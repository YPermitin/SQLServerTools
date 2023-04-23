using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers.Converters
{
    public interface IConfigObjectConverter
    {
        object Convert(ConfigObject configObject);
    }
}