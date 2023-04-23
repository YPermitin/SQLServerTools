using YPermitin.SQLCLR.YellowMetadataReader.Factories;
using YPermitin.SQLCLR.YellowMetadataReader.Helpers;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class TablePart : ApplicationObject
    {
        public ApplicationObject Owner { get; set; }

        public override string MetadataName
        {
            get
            {
                if (_metadataName == null)
                {
                    string typeNameByToken = GeneralHelper.GetMetadataTypeByToken(Owner.Token);
                    _metadataName = $"{typeNameByToken}.{Owner.Name}.ТабличнаяЧасть.{Name}";
                }

                return _metadataName;
            }
        }
    }
    public sealed class TablePartPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            // все реквизиты обязательные
            PropertyNameLookup.Add("_idrref", "Ссылка"); // _Reference31_IDRRef binary(16)
            PropertyNameLookup.Add("_keyfield", "Ключ"); // binary(4)
            PropertyNameLookup.Add("_lineno", "НомерСтроки"); // _LineNo49 numeric(5,0) - DBNames
        }
    }
}