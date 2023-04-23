using YPermitin.SQLCLR.YellowMetadataReader.Factories;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class Account : ApplicationObject, IReferenceCode, IDescription
    {
        //public List<TablePart> TableParts { get; set; } = new List<TablePart>();
        public int CodeLength { get; set; }
        public CodeType CodeType { get; set; }
        public int DescriptionLength { get; set; }
    }
    public sealed class AccountPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_idrref", "Ссылка");
            PropertyNameLookup.Add("_version", "ВерсияДанных");
            PropertyNameLookup.Add("_marked", "ПометкаУдаления");
            PropertyNameLookup.Add("_predefinedid", "Предопределённый");
            PropertyNameLookup.Add("_parentidrref", "Родитель");
            PropertyNameLookup.Add("_code", "Код");
            PropertyNameLookup.Add("_description", "Наименование");
            PropertyNameLookup.Add("_orderfield", "Порядок");
            PropertyNameLookup.Add("_kind", "Тип");
            PropertyNameLookup.Add("_offbalance", "Забалансовый");
        }
    }
}