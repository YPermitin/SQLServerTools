using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    public sealed class DatabaseField
    {
        public DatabaseField() { }
        public DatabaseField(string name, string typeName, int length)
        {
            Name = name;
            Length = length;
            TypeName = typeName;
        }
        public DatabaseField(string name, string typeName, int length, int precision, int scale) : this(name, typeName, length)
        {
            Scale = scale;
            Precision = precision;
        }
        public string Name { get; set; }
        public FieldPurpose Purpose { get; set; } = FieldPurpose.Value;
        public string TypeName { get; set; }
        public int Length { get; set; }
        public int Precision { get; set; }
        public int Scale { get; set; }
        public bool IsNullable { get; set; }
        public int KeyOrdinal { get; set; }
        public bool IsPrimaryKey { get; set; }
        public override string ToString() { return Name; }
    }
}