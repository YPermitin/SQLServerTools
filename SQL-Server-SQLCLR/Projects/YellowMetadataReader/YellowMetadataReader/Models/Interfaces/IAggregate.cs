using System.Collections.Generic;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces
{
    public interface IAggregate // only reference types can be aggregates
    {
        ApplicationObject Owner { get; set; }
        List<ApplicationObject> Elements { get; set; }
    }
}