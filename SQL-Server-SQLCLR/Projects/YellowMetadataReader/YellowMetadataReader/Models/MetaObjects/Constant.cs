using YPermitin.SQLCLR.YellowMetadataReader.Factories;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class Constant : ApplicationObject
    {

    }
    public sealed class ConstantPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_recordkey", "КлючЗаписи"); // binary(1)
        }
    }
}