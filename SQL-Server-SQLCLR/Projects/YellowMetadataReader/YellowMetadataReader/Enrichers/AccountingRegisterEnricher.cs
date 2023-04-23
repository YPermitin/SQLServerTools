using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class AccountingRegisterEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public AccountingRegisterEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is AccountingRegister register)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(register.FileName.ToString());

            register.Name = configObject.GetString(new[] { 1, 15, 1, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 15, 1, 3 });
            if (alias.Values.Count == 3)
            {
                register.Alias = configObject.GetString(new[] { 1, 15, 1, 3, 2 });
            }

            Configurator.ConfigurePropertyПериод(register);
            Configurator.ConfigurePropertyНомерЗаписи(register);
            Configurator.ConfigurePropertyАктивность(register);
            Configurator.ConfigurePropertyСчетДт(register);
            Configurator.ConfigurePropertyСчетКт(register);

            // 7 - коллекция измерений
            ConfigObject properties = configObject.GetObject(new[] { 3 });
            // 7.0 = 35b63b9d-0adf-4625-a047-10ae874c19a3 - идентификатор коллекции измерений
            Guid propertiesUuid = configObject.GetUuid(new[] { 3, 0 });
            if (propertiesUuid == new Guid("35b63b9d-0adf-4625-a047-10ae874c19a3"))
            {
                Configurator.ConfigureProperties(register, properties, PropertyPurpose.Dimension);
            }
            // TODO: ???
            // Configurator.ConfigurePropertyDimHash(register);
            // Справка 1С: Хеш-функция измерений.
            // Поле присутствует, если количество измерений не позволяет организовать уникальный индекс по измерениям.

            // 5 - коллекция ресурсов
            properties = configObject.GetObject(new[] { 5 });
            // 5.0 = 63405499-7491-4ce3-ac72-43433cbe4112 - идентификатор коллекции ресурсов
            propertiesUuid = configObject.GetUuid(new[] { 5, 0 });
            if (propertiesUuid == new Guid("63405499-7491-4ce3-ac72-43433cbe4112"))
            {
                Configurator.ConfigureProperties(register, properties, PropertyPurpose.Measure);
            }

            // 6 - коллекция реквизитов
            properties = configObject.GetObject(new[] { 7 });
            // 6.0 = 9d28ee33-9c7e-4a1b-8f13-50aa9b36607b - идентификатор коллекции реквизитов
            propertiesUuid = configObject.GetUuid(new[] { 6, 0 });
            if (propertiesUuid == new Guid("9d28ee33-9c7e-4a1b-8f13-50aa9b36607b"))
            {
                Configurator.ConfigureProperties(register, properties, PropertyPurpose.Property);
            }

            Configurator.ConfigureSharedProperties(register);
        }
    }
}