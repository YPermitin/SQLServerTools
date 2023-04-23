using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces
{
    public interface IPredefinedValues
    {
        List<PredefinedValue> PredefinedValues { get; set; }
    }
}