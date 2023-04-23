using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class AccountEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public AccountEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is Account account)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(account.FileName.ToString());

            account.Uuid = configObject.GetUuid(new[] { 1, 3 });
            account.Name = configObject.GetString(new[] { 1, 15, 1, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 15, 1, 3 });
            if (alias.Values.Count == 3)
            {
                account.Alias = configObject.GetString(new[] { 1, 15, 1, 3, 2 });
            }
            account.CodeType = CodeType.String;
            account.CodeLength = configObject.GetInt32(new[] { 1, 22 });
            account.DescriptionLength = configObject.GetInt32(new[] { 1, 23 });

            Configurator.ConfigurePropertyСсылка(account);
            Configurator.ConfigurePropertyВерсияДанных(account);
            Configurator.ConfigurePropertyПометкаУдаления(account);
            Configurator.ConfigurePropertyПредопределённый(account);
            Configurator.ConfigurePropertyРодитель(account);

            if (account.CodeLength > 0)
            {
                Configurator.ConfigurePropertyКод(account);
            }
            if (account.DescriptionLength > 0)
            {
                Configurator.ConfigurePropertyНаименование(account);
            }

            Configurator.ConfigurePropertyПорядок(account);
            Configurator.ConfigurePropertyВид(account);
            Configurator.ConfigurePropertyЗабалансовый(account);

            // 6 - коллекция реквизитов плана счетов
            ConfigObject properties = configObject.GetObject(new[] { 7 });
            // 6.0 = 6e65cbf5-daa8-4d8d-bef8-59723f4e5777 - идентификатор коллекции реквизитов плана счетов
            Guid propertiesUuid = configObject.GetUuid(new[] { 7, 0 });
            if (propertiesUuid == new Guid("6e65cbf5-daa8-4d8d-bef8-59723f4e5777"))
            {
                Configurator.ConfigureProperties(account, properties, PropertyPurpose.Property);
            }
            
            Configurator.ConfigureSharedProperties(account);

            // Признаки учета плана счетов
            ConfigObject propertiesAccounting = configObject.GetObject(new[] { 8 });
            // 6.0 = 78bd1243-c4df-46c3-8138-e147465cb9a4 - идентификатор коллекции реквизитов плана счетов
            Guid propertiesUuidAccounting = configObject.GetUuid(new[] { 8, 0 });
            if (propertiesUuidAccounting == new Guid("78bd1243-c4df-46c3-8138-e147465cb9a4"))
            {
                Configurator.ConfigureProperties(account, propertiesAccounting, PropertyPurpose.Property);
            }

            // 5 - коллекция табличных частей плана счетов
            ConfigObject tableParts = configObject.GetObject(new[] { 5 });
            // 5.0 = 932159f9-95b2-4e76-a8dd-8849fe5c5ded - идентификатор коллекции табличных частей плана счетов
            Guid collectionUuid = configObject.GetUuid(new[] { 5, 0 });
            if (collectionUuid == new Guid("4c7fec95-d1bd-4508-8a01-f1db090d9af8"))
            {
                Configurator.ConfigureTableParts(account, tableParts);
            }

            Configurator.ConfigurePredefinedValues(account);
        }
    }
}