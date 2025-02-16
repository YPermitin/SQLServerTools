namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class MultiPolygonType : ArrayType
    {
        public MultiPolygonType()
        {
            UnderlyingType = new PolygonType();
        }

        public override string ToString() => "MultiPolygon";
    }
}