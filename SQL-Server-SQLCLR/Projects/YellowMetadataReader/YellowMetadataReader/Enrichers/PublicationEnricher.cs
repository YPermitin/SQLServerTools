using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class PublicationEnricher : IContentEnricher
    {
        private Configurator Configurator { get; }
        public PublicationEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is Publication publication)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(publication.FileName.ToString());

            if (configObject == null) return; // TODO: log error

            publication.Uuid = configObject.GetUuid(new[] { 1, 3 });
            publication.Name = configObject.GetString(new[] { 1, 12, 2 });
            ConfigObject alias = configObject.GetObject(new[] { 1, 12, 3 });
            if (alias.Values.Count == 3)
            {
                publication.Alias = configObject.GetString(new[] { 1, 12, 3, 2 });
            }
            publication.CodeLength = configObject.GetInt32(new[] { 1, 15 });
            publication.DescriptionLength = configObject.GetInt32(new[] { 1, 17 });
            publication.IsDistributed = configObject.GetInt32(new[] { 1, 26 }) != 0;

            Configurator.ConfigurePropertyСсылка(publication);
            Configurator.ConfigurePropertyВерсияДанных(publication);
            Configurator.ConfigurePropertyПометкаУдаления(publication);
            Configurator.ConfigurePropertyКод(publication);
            Configurator.ConfigurePropertyНаименование(publication);
            Configurator.ConfigurePropertyНомерОтправленного(publication);
            Configurator.ConfigurePropertyНомерПринятого(publication);
            Configurator.ConfigurePropertyПредопределённый(publication);

            // 3 - коллекция реквизитов
            ConfigObject properties = configObject.GetObject(new[] { 3 });
            // 3.0 = 1a1b4fea-e093-470d-94ff-1d2f16cda2ab - идентификатор коллекции реквизитов
            Guid propertiesUuid = configObject.GetUuid(new[] { 3, 0 });
            if (propertiesUuid == new Guid("1a1b4fea-e093-470d-94ff-1d2f16cda2ab"))
            {
                Configurator.ConfigureProperties(publication, properties, PropertyPurpose.Property);
            }

            Configurator.ConfigureSharedProperties(publication);

            // 5 - коллекция табличных частей
            ConfigObject tableParts = configObject.GetObject(new[] { 5 });
            // 5.0 = 52293f4b-f98c-43ea-a80f-41047ae7ab58 - идентификатор коллекции табличных частей
            Guid collectionUuid = configObject.GetUuid(new[] { 5, 0 });
            if (collectionUuid == new Guid("52293f4b-f98c-43ea-a80f-41047ae7ab58"))
            {
                Configurator.ConfigureTableParts(publication, tableParts);
            }

            ConfigureArticles(publication);
        }

        private void ConfigureArticles(Publication publication)
        {
            string fileName = publication.FileName.ToString() + ".1";
            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(fileName);
            if (configObject == null) return; // not found

            int count = configObject.GetInt32(new[] { 1 });
            if (count == 0) return;

            int step = 2;
            for (int i = 1; i <= count; i++)
            {
                Guid uuid = configObject.GetUuid(new[] { i * step });
                AutoPublication setting = (AutoPublication)configObject.GetInt32(new[] { (i * step) + 1 });
                publication.Articles.Add(uuid, setting);
            }
        }
    }
}