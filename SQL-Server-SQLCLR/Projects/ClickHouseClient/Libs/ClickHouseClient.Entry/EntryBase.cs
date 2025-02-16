using System.Data.SqlClient;

namespace YPermitin.SQLCLR.ClickHouseClient.Entry
{
    public abstract class EntryBase
    {
        /// <summary>
        /// Строка подключения к SQL Server.
        /// 
        /// По умолчанию используется контекстное соединение,
        /// из под которого выполнен вызов функции или процедуры со стороны SQL Server.
        /// </summary>
        public static string ConnectionString { get; set; }
            = "context connection=true";

        /// <summary>
        /// Соединение SQL Server для целей отладки.
        ///
        /// При использовании расширения непосредственно на SQL Server не используется.
        /// </summary>
        public static SqlConnection DebugConnection { get; set; }
    }
}
