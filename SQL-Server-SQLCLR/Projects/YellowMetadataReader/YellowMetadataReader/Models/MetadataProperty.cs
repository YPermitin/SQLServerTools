using System.Collections.Generic;
using System.Linq;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    /// <summary>Класс для описания свойств объекта метаданных
    ///     (реквизитов, измерений и ресурсов)
    /// </summary>
    public class MetadataProperty : MetadataObject
    {
        ///<summary>Основа имени поля в таблице СУБД (может быть дополнено постфиксами в зависимости от типа данных свойства)</summary>
        public string DbName { get; set; } = string.Empty;
        ///<summary>Коллекция для описания полей таблицы СУБД свойства объекта метаданных</summary>
        public List<DatabaseField> Fields { get; set; } = new List<DatabaseField>();
        ///<summary>Логический смысл свойства. Подробнее смотри перечисление <see cref="PropertyPurpose"/>.</summary>
        public PropertyPurpose Purpose { get; set; } = PropertyPurpose.Property;
        ///<summary>Описание типов данных <see cref="DataTypeInfo"/>, которые могут использоваться для значений свойства.</summary>
        public DataTypeInfo PropertyType { get; set; } = new DataTypeInfo();
        /// <summary>Вариант использования реквизита для групп и элементов</summary>
        public PropertyUsage PropertyUsage { get; set; } = PropertyUsage.Item;
        public bool IsPrimaryKey()
        {
            return (Fields != null
                && Fields.Count > 0
                && Fields.Where(f => f.IsPrimaryKey).FirstOrDefault() != null);
        }
        public override string ToString() { return Name; }
    }
}