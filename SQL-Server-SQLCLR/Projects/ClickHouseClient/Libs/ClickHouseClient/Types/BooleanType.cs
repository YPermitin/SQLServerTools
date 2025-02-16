using System;
using YPermitin.SQLCLR.ClickHouseClient.Formats;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class BooleanType : ClickHouseType
    {
        public override Type FrameworkType => typeof(bool);

        public override object Read(ExtendedBinaryReader reader) => reader.ReadBoolean();

        public override string ToString() => "Bool";

        public override void Write(ExtendedBinaryWriter writer, object value) => writer.Write((bool)value);
    }
}