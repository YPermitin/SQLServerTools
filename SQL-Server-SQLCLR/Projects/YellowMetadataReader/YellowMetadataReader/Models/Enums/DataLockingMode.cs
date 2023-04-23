namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Enums
{
    /// <summary>
    /// Режим управления блокировкой данных
    /// </summary>
    public enum DataLockingMode
    {
        /// <summary>
        /// Автоматический
        /// </summary>
        Automatic = 0,
        /// <summary>
        /// Управляемый
        /// </summary>
        Managed = 1,
        /// <summary>
        /// Автоматический и управляемый
        /// </summary>
        AutomaticAndManaged = 2
    }
}