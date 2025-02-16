using System;

namespace YPermitin.SQLCLR.ClickHouseClient.Copy.Serializer
{
    public class ClickHouseBulkCopySerializationException : Exception
    {
        public ClickHouseBulkCopySerializationException(object[] row, Exception innerException)
            : base("Error when serializing data", innerException)
        {
            Row = row;
        }

        /// <summary>
        /// Gets row at which exception happened
        /// </summary>
        public object[] Row { get; }
    }
}