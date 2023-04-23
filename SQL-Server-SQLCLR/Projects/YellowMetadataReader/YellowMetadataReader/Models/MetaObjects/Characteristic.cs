using System;
using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Factories;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class Characteristic : ApplicationObject, IReferenceCode, IDescription, IReferenceHierarchy, IPredefinedValues
    {
        ///<summary>
        ///Идентификатор характеристики, описания типов значений.
        ///Используется как тип значения "Характеристика" в реквизитах других объектов метаданных.
        ///</summary>
        public Guid TypeUuid { get; set; } = Guid.Empty;
        public DataTypeInfo TypeInfo { get; set; }
        public int CodeLength { get; set; } = 9;
        public CodeType CodeType { get; set; } = CodeType.String;
        public int DescriptionLength { get; set; } = 25;
        public bool IsHierarchical { get; set; } = false;
        public HierarchyType HierarchyType { get; set; } = HierarchyType.Groups;
        public List<PredefinedValue> PredefinedValues { get; set; } = new List<PredefinedValue>();
    }
    public sealed class CharacteristicPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_idrref", "Ссылка");
            PropertyNameLookup.Add("_version", "ВерсияДанных");
            PropertyNameLookup.Add("_marked", "ПометкаУдаления");
            PropertyNameLookup.Add("_predefinedid", "Предопределённый");
            PropertyNameLookup.Add("_parentidrref", "Родитель"); // необязательный
            PropertyNameLookup.Add("_folder", "ЭтоГруппа"); // необязательный
            PropertyNameLookup.Add("_code", "Код"); // необязательный
            PropertyNameLookup.Add("_description", "Наименование"); // необязательный
            PropertyNameLookup.Add("_type", "ТипЗначения");
        }
    }
}