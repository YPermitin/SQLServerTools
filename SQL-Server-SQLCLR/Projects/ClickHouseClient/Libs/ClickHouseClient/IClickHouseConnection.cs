using System.Data;
using YPermitin.SQLCLR.ClickHouseClient.ADO;

namespace YPermitin.SQLCLR.ClickHouseClient
{
    public interface IClickHouseConnection : IDbConnection
    {
        new ClickHouseCommand CreateCommand();
    }
}