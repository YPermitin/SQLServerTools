namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Enums
{
    /// <summary>
    /// Вариант использования реквизита справочника или плана видов характеристик для групп и элементов
    /// </summary>
    public enum PropertyUsage
    {
        /// <summary>
        /// Использовать реквизит только для элементов
        /// </summary>
        Item = 0,
        /// <summary>
        /// Использовать реквизит только для групп
        /// </summary>
        Folder = 1,
        /// <summary>
        /// Использовать реквизит для элементов и групп
        /// </summary>
        ItemAndFolder = 2
    }
}