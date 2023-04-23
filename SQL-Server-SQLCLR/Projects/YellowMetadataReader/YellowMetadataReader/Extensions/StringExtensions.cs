namespace YPermitin.SQLCLR.YellowMetadataReader.Extensions
{
    public static class StringExtensions
    {
        public static string RemoveFirstUnderlineSymbol(this string source)
        {
            if (source.Length == 0)
                return source;

            if (source[0] == '_')
            {
                return source.Substring(1, source.Length - 1);
            }

            return source;
        }
    }
}
