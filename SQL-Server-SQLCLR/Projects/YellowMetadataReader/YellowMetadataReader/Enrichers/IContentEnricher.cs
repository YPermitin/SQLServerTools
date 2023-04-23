using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public interface IContentEnricher
    {
        void Enrich(MetadataObject metadataObject);
    }
}