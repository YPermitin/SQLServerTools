using YPermitin.SQLCLR.YellowMetadataReader.Factories;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class Document : ApplicationObject
    {
        public int NumberLength { get; set; } = 8;
        public NumberType NumberType { get; set; } = NumberType.String;
        public Periodicity Periodicity { get; set; } = Periodicity.None;
    }
    public sealed class DocumentPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_idrref", "Ссылка");
            PropertyNameLookup.Add("_version", "ВерсияДанных");
            PropertyNameLookup.Add("_marked", "ПометкаУдаления");
            PropertyNameLookup.Add("_date_time", "Дата");
            PropertyNameLookup.Add("_number", "Номер"); // необязательный
            PropertyNameLookup.Add("_posted", "Проведён");
        }
    }
}