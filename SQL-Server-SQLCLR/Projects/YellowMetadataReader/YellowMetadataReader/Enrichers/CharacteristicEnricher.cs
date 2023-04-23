using System;
using YPermitin.SQLCLR.YellowMetadataReader.Enrichers.Converters;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class CharacteristicEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        private IConfigObjectConverter TypeInfoConverter { get; }
        public CharacteristicEnricher(Configurator configurator)
        {
            Configurator = configurator;
            TypeInfoConverter = Configurator.GetConverter<DataTypeInfo>();
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is Characteristic model)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(model.FileName.ToString());

            model.Uuid = configObject.GetUuid(new[] { 1, 3 });
            model.TypeUuid = configObject.GetUuid(new[] { 1, 9 });
            model.Name = configObject.GetString(new[] { 1, 13, 1, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 13, 1, 3 });
            if (alias.Values.Count == 3)
            {
                model.Alias = configObject.GetString(new[] { 1, 13, 1, 3, 2 });
            }
            model.CodeLength = configObject.GetInt32(new[] { 1, 21 });
            model.DescriptionLength = configObject.GetInt32(new[] { 1, 23 });
            model.IsHierarchical = configObject.GetInt32(new[] { 1, 19 }) != 0;

            Configurator.ConfigurePropertyСсылка(model);
            Configurator.ConfigurePropertyВерсияДанных(model);
            Configurator.ConfigurePropertyПометкаУдаления(model);
            Configurator.ConfigurePropertyПредопределённый(model);
            Configurator.ConfigurePropertyТипЗначения(model);

            if (model.CodeLength > 0)
            {
                Configurator.ConfigurePropertyКод(model);
            }
            if (model.DescriptionLength > 0)
            {
                Configurator.ConfigurePropertyНаименование(model);
            }
            if (model.IsHierarchical)
            {
                Configurator.ConfigurePropertyРодитель(model);
                if (model.HierarchyType == HierarchyType.Groups)
                {
                    Configurator.ConfigurePropertyЭтоГруппа(model);
                }
            }

            // 1.18 - описание типов значений характеристики
            ConfigObject propertyTypes = configObject.GetObject(new[] { 1, 18 });
            model.TypeInfo = (DataTypeInfo)TypeInfoConverter.Convert(propertyTypes);

            // 3 - коллекция реквизитов
            ConfigObject properties = configObject.GetObject(new[] { 3 });
            // 3.0 = 31182525-9346-4595-81f8-6f91a72ebe06 - идентификатор коллекции реквизитов
            Guid propertiesUuid = configObject.GetUuid(new[] { 3, 0 });
            if (propertiesUuid == new Guid("31182525-9346-4595-81f8-6f91a72ebe06"))
            {
                Configurator.ConfigureProperties(model, properties, PropertyPurpose.Property);
            }

            Configurator.ConfigureSharedProperties(model);

            // 5 - коллекция табличных частей
            ConfigObject tableParts = configObject.GetObject(new[] { 5 });
            // 5.0 = 54e36536-7863-42fd-bea3-c5edd3122fdc - идентификатор коллекции табличных частей
            Guid collectionUuid = configObject.GetUuid(new[] { 5, 0 });
            if (collectionUuid == new Guid("54e36536-7863-42fd-bea3-c5edd3122fdc"))
            {
                Configurator.ConfigureTableParts(model, tableParts);
            }

            Configurator.ConfigurePredefinedValues(model);
        }
    }
}