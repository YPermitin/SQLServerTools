namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Enums
{
    /// <summary>
    /// Уровень чтения информации о метаданных
    /// </summary>
    public enum OpenInfobaseLevel
    {
        /// <summary>
        /// Только базовая информация о конфигурации
        /// </summary>
        ConfigInfoOnly = 0,

        /// <summary>
        /// Полная информация о конфигурации
        /// </summary>
        ConfigFull = 1
    }
}
