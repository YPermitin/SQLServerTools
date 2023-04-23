using System;
using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Factories;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class Enumeration : ApplicationObject
    {
        public List<EnumValue> Values { get; set; } = new List<EnumValue>();
    }
    public sealed class EnumValue
    {
        public Guid Uuid { get; set; } = Guid.Empty;
        public string Name { get; set; } = string.Empty;
        public string Alias { get; set; } = string.Empty;
        public int OrderNumber { get; set; } = 0;
    }
    public sealed class EnumerationPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_idrref", "Ссылка");
            PropertyNameLookup.Add("_enumorder", "Порядок");
        }
    }
}