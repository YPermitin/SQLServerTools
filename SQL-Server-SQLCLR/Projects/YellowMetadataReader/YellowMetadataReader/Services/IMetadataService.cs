using System.IO;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    /// <summary>
    /// Интерфейс для чтения метаданных прикладных объектов конфигурации 1С.
    /// Является точкой входа для использования библиотеки и играет роль фасада для всех остальных интерфейсов и парсеров.
    /// Реализует логику многопоточной загрузки объектов конфигурации 1С.
    /// </summary>
    public interface IMetadataService
    {
        ///<summary>Строка подключения к базе данных СУБД</summary>
        string ConnectionString { get; }

        ///<summary>Устанавливает строку подключения к базе данных СУБД</summary>
        ///<param name="connectionString">Строка подключения к базе данных СУБД</param>
        ///<returns>Возвращает ссылку на самого себя</returns>
        IMetadataService UseConnectionString(string connectionString);
        IMetadataService UseDatabaseName(string databaseName);

        ///<summary>Формирует строку подключения к базе данных по параметрам</summary>
        ///<param name="server">Имя или сетевой адрес сервера СУБД</param>
        ///<param name="database">Имя базы данных</param>
        ///<param name="userName">Имя пользователя (если не указано, то используется Windows аутентификация)</param>
        ///<param name="password">Пароль пользователя (используется в случае аутентификации средствами СУБД)</param>
        ///<returns>Возвращает ссылку на самого себя</returns>
        IMetadataService ConfigureConnectionString(string server, string database, string userName, string password);

        InfoBase OpenInfoBase(OpenInfobaseLevel level = OpenInfobaseLevel.ConfigFull);

        ///<summary>Получает файл метаданных в "сыром" (как есть) бинарном виде</summary>
        ///<param name="fileName">Имя файла метаданных: root, DBNames или значение UUID</param>
        ///<returns>Бинарные данные файла метаданных</returns>
        byte[] ReadConfigFile(string fileName);

        ///<summary>Распаковывает файл метаданных по алгоритму deflate и создаёт поток для чтения в формате UTF-8</summary>
        ///<param name="fileData">Бинарные данные файла метаданных</param>
        ///<returns>Поток для чтения файла метаданных в формате UTF-8</returns>
        StreamReader CreateReader(byte[] fileData);
    }
}
