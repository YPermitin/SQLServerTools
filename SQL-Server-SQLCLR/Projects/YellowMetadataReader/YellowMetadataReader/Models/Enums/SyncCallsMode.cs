namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Enums
{
    /// <summary>
    /// Режим использования синхронных вызовов расширений платформы и внешних компонент
    /// </summary>
    public enum SyncCallsMode
    {
        /// <summary>
        /// Использовать
        /// </summary>
        Use = 0,
        /// <summary>
        /// Использовать с предупреждениями
        /// </summary>
        UseWithAlert = 1,
        /// <summary>
        /// Не использовать
        /// </summary>
        DoNotUse = 2
    }
}