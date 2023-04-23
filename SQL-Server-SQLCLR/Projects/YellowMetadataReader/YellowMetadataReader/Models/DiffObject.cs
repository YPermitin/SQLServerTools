using System.Collections.Generic;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    public enum DiffKind { None, Insert, Update, Delete }
    public sealed class DiffObject
    {
        public string Path { get; set; }
        public DiffKind DiffKind { get; set; }
        public object SourceValue { get; set; }
        public object TargetValue { get; set; }
        public List<DiffObject> DiffObjects { get; } = new List<DiffObject>();
    }
}