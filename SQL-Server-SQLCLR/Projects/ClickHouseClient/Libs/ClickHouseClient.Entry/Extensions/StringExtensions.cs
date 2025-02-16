using System.Data.SqlTypes;

namespace YPermitin.SQLCLR.ClickHouseClient.Entry.Extensions
{
    public static class StringExtensions
    {
        public static SqlChars ToSqlChars(this string value) {
            return new SqlChars(value); 
        }

        public static string ToStringFromSqlChars(this SqlChars sqlString)
        {
            return new string(sqlString.Value);
        }
    }
}
