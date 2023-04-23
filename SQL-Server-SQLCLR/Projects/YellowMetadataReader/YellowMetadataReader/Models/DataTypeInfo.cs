// В целях оптимизации в свойстве ReferenceTypeCode класса DataTypeInfo
// не хранятся все допустимые для данного описания коды ссылочных типов.
// В случае составного типа код типа конкретного значения можно получить в базе данных в поле {имя поля}_TRef.
// В случае же сохранения кода типа в базу данных код типа можно получить из свойства ApplicationObject.TypeCode.
// У не составных типов такого поля в базе данных нет, поэтому необходимо сохранить код типа в DataTypeInfo,
// именно по этому значение свойства ReferenceTypeCode класса DataTypeInfo может быть больше ноля.

using System;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    // TODO: rename class to DataTypeSet
    // TODO: think on how to get set of reference types, assigned to this DataTypeSet, on demand

    ///<summary>Класс для описания типов данных свойства объекта метаданных (реквизита, измерения или ресурса)</summary>
    public sealed class DataTypeInfo
    {
        // TODO: add internal flags field "types" so as to use bitwise operations

        ///<summary>Типом значения свойства может быть "Строка" (поддерживает составной тип данных)</summary>
        public bool CanBeString { get; set; } = false;
        public int StringLength { get; set; } = 10;
        public StringKind StringKind { get; set; } = StringKind.Unlimited;
        ///<summary>Типом значения свойства может быть "Булево" (поддерживает составной тип данных)</summary>
        public bool CanBeBoolean { get; set; } = false;
        ///<summary>Типом значения свойства может быть "Число" (поддерживает составной тип данных)</summary>
        public bool CanBeNumeric { get; set; } = false;
        public int NumericScale { get; set; } = 0;
        public int NumericPrecision { get; set; } = 10;
        public NumericKind NumericKind { get; set; } = NumericKind.Unsigned;
        ///<summary>Типом значения свойства может быть "Дата" (поддерживает составной тип данных)</summary>
        public bool CanBeDateTime { get; set; } = false;
        public DateTimePart DateTimePart { get; set; } = DateTimePart.Date;
        ///<summary>Типом значения свойства может быть "Ссылка" (поддерживает составной тип данных)</summary>
        public bool CanBeReference { get; set; } = false;
        ///<summary>Типом значения свойства является byte[8] - версия данных, timestamp, rowversion.Не поддерживает составной тип данных.</summary>
        public bool IsBinary { get; set; } = false;
        ///<summary>Тип значения свойства "УникальныйИдентификатор", binary(16). Не поддерживает составной тип данных.</summary>
        public bool IsUuid { get; set; } = false;
        ///<summary>Тип значения свойства "ХранилищеЗначения", varbinary(max). Не поддерживает составной тип данных.</summary>
        public bool IsValueStorage { get; set; } = false;
        ///<summary>UUID ссылочного типа значения.</summary>
        public Guid ReferenceTypeUuid { get; set; } = Guid.Empty;
        ///<summary>Код ссылочного типа значения. По умолчанию равен 0 - многозначный ссылочный тип (составной тип данных).</summary>
        private int _referenceTypeCode;
        public int ReferenceTypeCode
        {
            set { _referenceTypeCode = value; }
            get
            {
                if (_referenceTypeCode == 0 && ReferenceTypeUuid != Guid.Empty)
                {
                    // TODO: lookup type code by type uuid - it can be reference type, compound type or characteristic
                }
                return _referenceTypeCode;
            }
        }
        ///<summary>Проверяет имеет ли свойство составной тип данных</summary>
        public bool IsMultipleType
        {
            get
            {
                if (IsUuid || IsValueStorage || IsBinary) return false;

                int count = 0;
                if (CanBeString) count++;
                if (CanBeBoolean) count++;
                if (CanBeNumeric) count++;
                if (CanBeDateTime) count++;
                if (CanBeReference) count++;
                if (count > 1) return true;

                if (CanBeReference && ReferenceTypeUuid == Guid.Empty) return true;

                return false;
            }
        }
        public override string ToString()
        {
            if (IsMultipleType) return "Multiple";
            else if (IsUuid) return "Uuid";
            else if (IsBinary) return "Binary";
            else if (IsValueStorage) return "ValueStorage";
            else if (CanBeString) return "String";
            else if (CanBeBoolean) return "Boolean";
            else if (CanBeNumeric) return "Numeric";
            else if (CanBeDateTime) return "DateTime";
            else if (CanBeReference) return "Reference";
            else return "Unknown";
        }
    }
}