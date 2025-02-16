using NodaTime;

namespace YPermitin.SQLCLR.ClickHouseClient
{
    // удалено record struct
    internal record TypeSettings(bool useBigDecimal, string timezone)
    {
        public static string DefaultTimezone = DateTimeZoneProviders.Tzdb.GetSystemDefault().Id;

        public static TypeSettings Default => new TypeSettings(true, DefaultTimezone);
    }
}