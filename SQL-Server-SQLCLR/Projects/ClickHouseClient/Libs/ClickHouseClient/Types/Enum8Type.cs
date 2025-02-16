using System;
using System.Globalization;
using YPermitin.SQLCLR.ClickHouseClient.Formats;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class Enum8Type : EnumType
    {
        public override string Name => "Enum8";

        public override object Read(ExtendedBinaryReader reader) => Lookup(reader.ReadSByte());

        public override void Write(ExtendedBinaryWriter writer, object value)
        {
            var enumIndex = value is string enumStr ? (sbyte)Lookup(enumStr) : Convert.ToSByte(value, CultureInfo.InvariantCulture);
            writer.Write(enumIndex);
        }
    }
}