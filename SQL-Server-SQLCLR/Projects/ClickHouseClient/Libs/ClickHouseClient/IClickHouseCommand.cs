using System.Collections.Generic;
using System.Data;
using System.Threading;
using System.Threading.Tasks;
using YPermitin.SQLCLR.ClickHouseClient.ADO.Parameters;
using YPermitin.SQLCLR.ClickHouseClient.ADO.Readers;

namespace YPermitin.SQLCLR.ClickHouseClient
{
    public interface IClickHouseCommand : IDbCommand
    {
        new ClickHouseDbParameter CreateParameter();

        Task<ClickHouseRawResult> ExecuteRawResultAsync(CancellationToken cancellationToken);

        IDictionary<string, object> CustomSettings { get; }
    }
}