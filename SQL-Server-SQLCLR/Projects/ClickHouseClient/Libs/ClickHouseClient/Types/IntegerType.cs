namespace YPermitin.SQLCLR.ClickHouseClient.Types
{
    internal abstract class IntegerType : ClickHouseType
    {
        public virtual bool Signed => true;
    }
}