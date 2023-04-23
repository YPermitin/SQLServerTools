using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class CatalogEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public CatalogEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is Catalog catalog)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(catalog.FileName.ToString());

            catalog.Uuid = configObject.GetUuid(new[] { 1, 3 });
            catalog.Name = configObject.GetString(new[] { 1, 9, 1, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 9, 1, 3 });
            if (alias.Values.Count == 3)
            {
                catalog.Alias = configObject.GetString(new[] { 1, 9, 1, 3, 2 });
            }
            catalog.CodeType = (CodeType)configObject.GetInt32(new[] { 1, 18 });
            catalog.CodeLength = configObject.GetInt32(new[] { 1, 17 });
            catalog.DescriptionLength = configObject.GetInt32(new[] { 1, 19 });
            catalog.HierarchyType = (HierarchyType)configObject.GetInt32(new[] { 1, 36 });
            catalog.IsHierarchical = configObject.GetInt32(new[] { 1, 37 }) != 0;

            Configurator.ConfigurePropertyСсылка(catalog);
            Configurator.ConfigurePropertyВерсияДанных(catalog);
            Configurator.ConfigurePropertyПометкаУдаления(catalog);
            Configurator.ConfigurePropertyПредопределённый(catalog);

            // 1.12.1 - количество владельцев справочника
            // 1.12.N - описание владельцев
            // 1.12.N.2.1 - uuid'ы владельцев (file names)
            Guid ownerUuid = Guid.Empty;
            catalog.Owners = configObject.GetInt32(new[] { 1, 12, 1 });
            if (catalog.Owners == 1)
            {
                ownerUuid = configObject.GetUuid(new[] { 1, 12, 2, 2, 1 });
            }
            if (catalog.Owners > 0)
            {
                Configurator.ConfigurePropertyВладелец(catalog, ownerUuid);
            }

            if (catalog.CodeLength > 0)
            {
                Configurator.ConfigurePropertyКод(catalog);
            }
            if (catalog.DescriptionLength > 0)
            {
                Configurator.ConfigurePropertyНаименование(catalog);
            }
            if (catalog.IsHierarchical)
            {
                Configurator.ConfigurePropertyРодитель(catalog);
                if (catalog.HierarchyType == HierarchyType.Groups)
                {
                    Configurator.ConfigurePropertyЭтоГруппа(catalog);
                }
            }

            // 6 - коллекция реквизитов справочника
            ConfigObject properties = configObject.GetObject(new[] { 6 });
            // 6.0 = cf4abea7-37b2-11d4-940f-008048da11f9 - идентификатор коллекции реквизитов справочника
            Guid propertiesUuid = configObject.GetUuid(new[] { 6, 0 });
            if (propertiesUuid == new Guid("cf4abea7-37b2-11d4-940f-008048da11f9"))
            {
                Configurator.ConfigureProperties(catalog, properties, PropertyPurpose.Property);
            }

            Configurator.ConfigureSharedProperties(catalog);

            // 5 - коллекция табличных частей справочника
            ConfigObject tableParts = configObject.GetObject(new[] { 5 });
            // 5.0 = 932159f9-95b2-4e76-a8dd-8849fe5c5ded - идентификатор коллекции табличных частей справочника
            Guid collectionUuid = configObject.GetUuid(new[] { 5, 0 });
            if (collectionUuid == new Guid("932159f9-95b2-4e76-a8dd-8849fe5c5ded"))
            {
                Configurator.ConfigureTableParts(catalog, tableParts);
            }

            Configurator.ConfigurePredefinedValues(catalog);
        }
    }
}