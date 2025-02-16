using YPermitin.SQLCLR.ClickHouseClient.Formats;
using YPermitin.SQLCLR.ClickHouseClient.Types;

namespace YPermitin.SQLCLR.ClickHouseClient.Copy.Serializer
{
    internal interface IRowSerializer
    {
        void Serialize(object[] row, ClickHouseType[] types, ExtendedBinaryWriter writer);
    }
}