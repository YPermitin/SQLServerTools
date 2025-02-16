using System;
using YPermitin.SQLCLR.ClickHouseClient.Formats;
using YPermitin.SQLCLR.ClickHouseClient.Types.Grammar;

namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class DateType : AbstractDateTimeType
    {
        public override string Name { get; }

        public override string ToString() => "Date";

        public override object Read(ExtendedBinaryReader reader) => DateTimeConversions.FromUnixTimeDays(reader.ReadUInt16());

        public override ParameterizedType Parse(SyntaxTreeNode typeName, Func<SyntaxTreeNode, ClickHouseType> parseClickHouseTypeFunc, TypeSettings settings) => throw new NotImplementedException();

        public override void Write(ExtendedBinaryWriter writer, object value)
        {
            writer.Write(Convert.ToUInt16(CoerceToDateTimeOffset(value).ToUnixTimeDays()));
        }
    }
}