using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class ConstantEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public ConstantEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(metadataObject.FileName.ToString());
            
            if (configObject == null) return; // TODO: log error

            metadataObject.Uuid = configObject.GetUuid(new[] { 1, 2 });
            metadataObject.Name = configObject.GetString(new[] { 1, 1, 1, 1, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 1, 1, 1, 3 });
            if (alias.Values.Count == 3)
            {
                metadataObject.Alias = configObject.GetString(new[] { 2 });
            }
        }
    }
}