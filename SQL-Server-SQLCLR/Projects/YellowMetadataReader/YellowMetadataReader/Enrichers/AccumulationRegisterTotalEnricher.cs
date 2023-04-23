using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class AccumulationRegisterTotalEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public AccumulationRegisterTotalEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is AccumulationRegisterTotal register)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(register.FileName.ToString());

            register.Name = configObject.GetString(new[] { 1, 13, 1, 2 })
                + ".Итоги";
            ConfigObject alias = configObject.GetObject(new[] { 1, 13, 1, 3 });
            if (alias.Values.Count == 3)
            {
                register.Alias = configObject.GetString(new[] { 1, 13, 1, 3, 2 })
                    + " (Итоги)";
            }
            
            Configurator.ConfigurePropertyПериод(register);
            
            // 7 - коллекция измерений
            ConfigObject properties = configObject.GetObject(new[] { 7 });
            // 7.0 = b64d9a43-1642-11d6-a3c7-0050bae0a776 - идентификатор коллекции измерений
            Guid propertiesUuid = configObject.GetUuid(new[] { 7, 0 });
            if (propertiesUuid == new Guid("b64d9a43-1642-11d6-a3c7-0050bae0a776"))
            {
                Configurator.ConfigureProperties(register, properties, PropertyPurpose.Dimension);
            }

            // 5 - коллекция ресурсов
            properties = configObject.GetObject(new[] { 5 });
            // 5.0 = b64d9a41-1642-11d6-a3c7-0050bae0a776 - идентификатор коллекции ресурсов
            propertiesUuid = configObject.GetUuid(new[] { 5, 0 });
            if (propertiesUuid == new Guid("b64d9a41-1642-11d6-a3c7-0050bae0a776"))
            {
                Configurator.ConfigureProperties(register, properties, PropertyPurpose.Measure);
            }

            Configurator.ConfigureSharedProperties(register);
        }
    }
}