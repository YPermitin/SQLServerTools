using YPermitin.SQLCLR.YellowMetadataReader.Factories;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class AccountingRegister : ApplicationObject
    {

    }
    public sealed class AccountingRegisterPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_period", "Период");
            PropertyNameLookup.Add("_recorder", "Регистратор");
            // TODO: добавить остальные свойства
        }
    }
}