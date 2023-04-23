using System;
using System.Collections.Generic;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public enum AutomaticUsage
    {
        Use = 0,
        DoNotUse = 1
    }
    public enum SharedPropertyUsage
    {
        Auto = 0,
        Use = 1,
        DoNotUse = 2
    }
    public sealed class SharedProperty : MetadataProperty
    {
        public AutomaticUsage AutomaticUsage { get; set; }
        public Dictionary<Guid, SharedPropertyUsage> UsageSettings { get; } = new Dictionary<Guid, SharedPropertyUsage>();
    }
}