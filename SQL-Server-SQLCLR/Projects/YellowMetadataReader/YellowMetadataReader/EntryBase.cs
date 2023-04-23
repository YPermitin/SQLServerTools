namespace YPermitin.SQLCLR.YellowMetadataReader
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
    }
}
