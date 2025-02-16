namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class Int256Type : AbstractBigIntegerType
    {
        public override int Size => 32;

        public override string ToString() => "Int256";
    }
}