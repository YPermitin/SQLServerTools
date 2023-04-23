// ReSharper disable InconsistentNaming
namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    public class SqlFieldInfo
    {
        // ReSharper disable once EmptyConstructor
        public SqlFieldInfo() { }
        public int ORDINAL_POSITION;
        public string COLUMN_NAME;
        public string DATA_TYPE;
        public int CHARACTER_OCTET_LENGTH;
        public int CHARACTER_MAXIMUM_LENGTH;
        public byte NUMERIC_PRECISION;
        public byte NUMERIC_SCALE;
        public bool IS_NULLABLE;
        public override string ToString()
        {
            return COLUMN_NAME + " (" + DATA_TYPE + ")";
        }
    }
}
