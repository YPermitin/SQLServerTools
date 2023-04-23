using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    public sealed class ConfigInfo
    {
        /// <summary>
        /// Имя конфигурации
        /// </summary>
        public string Name { get; set; } = string.Empty;
        /// <summary>
        /// Синоним конфигурации
        /// </summary>
        public string Alias { get; set; } = string.Empty;
        /// <summary>
        /// Комментарий
        /// </summary>
        public string Comment { get; set; } = string.Empty;
        /// <summary>
        /// Режим совместимости (версия платформы)
        /// </summary>
        public int Version { get; set; }
        /// <summary>
        /// Версия конфигурации
        /// </summary>
        public string ConfigVersion { get; set; } = string.Empty;
        /// <summary>
        /// Режим использования синхронных вызовов расширений платформы и внешних компонент
        /// </summary>
        public SyncCallsMode SyncCallsMode { get; set; }
        /// <summary>
        /// Режим управления блокировкой данных
        /// </summary>
        public DataLockingMode DataLockingMode { get; set; }
        /// <summary>
        /// Режим использования модальности
        /// </summary>
        public ModalWindowMode ModalWindowMode { get; set; }
        /// <summary>
        /// Режим автонумерации объектов
        /// </summary>
        public AutoNumberingMode AutoNumberingMode { get; set; }
        /// <summary>
        /// Режим совместимости интерфейса
        /// </summary>
        public UiCompatibilityMode UiCompatibilityMode { get; set; }
    }
}