using System.IO;

namespace YPermitin.SQLCLR.ClickHouseClient.Copy.Serializer
{
    internal interface IBatchSerializer
    {
        void Serialize(Batch batch, Stream stream);
    }
}