namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal class Int128Type : AbstractBigIntegerType
    {
        public override int Size => 16;

        public override string ToString() => "Int128";
    }
}