using System;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    public abstract class MetadataObject : IComparable
    {
        ///<summary>Внутренний идентификатор объекта метаданных</summary>
        public Guid Uuid { get; set; } = Guid.Empty;
        ///<summary>Идентификатор файла объекта метаданных в таблице Config и DBNames</summary>
        public Guid FileName { get; set; } = Guid.Empty;
        ///<summary>Имя объекта метаданных</summary>
        public string Name { get; set; } = string.Empty;
        ///<summary>Синоним объекта метаданных</summary>
        public string Alias { get; set; } = string.Empty;
        
        // TODO: add Comment property ?

        public int CompareTo(object other)
        {
            return CompareTo((MetadataObject)other);
        }
        public int CompareTo(MetadataObject other)
        {
            if (other == null) return 1; // this instance is bigger than other
            return String.Compare(Name, other.Name, StringComparison.Ordinal);
        }
        public override string ToString() { return $"{GetType().Name}.{Name}"; }
    }
}