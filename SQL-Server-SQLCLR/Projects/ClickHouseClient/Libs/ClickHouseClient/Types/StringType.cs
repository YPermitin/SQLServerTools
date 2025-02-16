using System;
using System.Globalization;
using YPermitin.SQLCLR.ClickHouseClient.Formats;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class StringType : ClickHouseType
    {
        public override Type FrameworkType => typeof(string);

        public override object Read(ExtendedBinaryReader reader) => reader.ReadString();

        public override string ToString() => "String";

        public override void Write(ExtendedBinaryWriter writer, object value) => writer.Write(Convert.ToString(value, CultureInfo.InvariantCulture));
    }
}