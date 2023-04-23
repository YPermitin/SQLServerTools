using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class EnumerationEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public EnumerationEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is Enumeration enumeration)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(enumeration.FileName.ToString());

            if (configObject == null) return; // TODO: log error

            enumeration.Uuid = configObject.GetUuid(new[] { 1, 1 });
            enumeration.Name = configObject.GetString(new[] { 1, 5, 1, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 5, 1, 3 });
            if (alias.Values.Count == 3)
            {
                enumeration.Alias = configObject.GetString(new[] { 1, 5, 1, 3, 2 });
            }
            Configurator.ConfigurePropertyСсылка(enumeration);
            Configurator.ConfigurePropertyПорядок(enumeration);

            // 6 - коллекция значений
            ConfigObject values = configObject.GetObject(new[] { 6 });
            // 6.0 = bee0a08c-07eb-40c0-8544-5c364c171465 - идентификатор коллекции значений
            Guid valuesUuid = configObject.GetUuid(new[] { 6, 0 });
            if (valuesUuid == new Guid("bee0a08c-07eb-40c0-8544-5c364c171465"))
            {
                ConfigureValues(enumeration, values);
            }
        }
        private void ConfigureValues(Enumeration enumeration, ConfigObject values)
        {
            int valuesCount = values.GetInt32(new[] { 1 }); // количество значений
            if (valuesCount == 0) return;

            int offset = 2;
            int orderNumber = 0;
            for (int v = 0; v < valuesCount; v++)
            {
                // V.0.1.1.2 - value uuid
                Guid uuid = values.GetUuid(new[] { v + offset, 0, 1, 1, 2 });
                // V.0.1.2 - value name
                string name = values.GetString(new[] { v + offset, 0, 1, 2 });
                // P.0.1.3 - value alias descriptor
                string alias = string.Empty;
                ConfigObject aliasDescriptor = values.GetObject(new[] { v + offset, 0, 1, 3 });
                if (aliasDescriptor.Values.Count == 3)
                {
                    // P.0.1.3.2 - value alias
                    alias = values.GetString(new[] { v + offset, 0, 1, 3, 2 });
                }
                enumeration.Values.Add(new EnumValue()
                {
                    Uuid = uuid,
                    Name = name,
                    Alias = alias,
                    OrderNumber = orderNumber
                });

                orderNumber += 1;
            }
        }
    }
}