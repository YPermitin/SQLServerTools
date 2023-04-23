using System;
using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Helpers;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    ///<summary>Класс для описания объектов метаданных (справочников, документов, регистров и т.п.)</summary>
    public class ApplicationObject : MetadataObject
    {
        ///<summary>Целочисленный идентификатор объекта метаданных из файла DBNames</summary>
        public int TypeCode { get; set; }
        public string TableName { get; set; }
        public string Token { get; set; }

        private string _fullKey;
        public string FullKey
        {
            get
            {
                if (_fullKey == null)
                {
                    _fullKey = GeneralHelper.GenerateConfigFullObjectKey(Uuid, Token, TypeCode);
                }

                return _fullKey;
            }
        }

        // ReSharper disable once InconsistentNaming
        protected string _metadataName;

        public virtual string MetadataName
        {
            get
            {
                if (_metadataName == null)
                {
                    string typeNameByToken = GeneralHelper.GetMetadataTypeByToken(Token);
                    _metadataName = $"{typeNameByToken}.{Name}";
                }

                return _metadataName;
            }
        }

        public List<MetadataProperty> Properties { get; set; } = new List<MetadataProperty>();
        public List<TablePart> TableParts { get; set; } = new List<TablePart>(); // TODO: not all of the metadata objects have table parts
        public bool IsReferenceType
        {
            get
            {
                Type thisType = GetType();
                return thisType == typeof(Account)
                    || thisType == typeof(Catalog)
                    || thisType == typeof(Document)
                    || thisType == typeof(Enumeration)
                    || thisType == typeof(Publication)
                    || thisType == typeof(Characteristic);
            }
        }

        /// <summary>
        /// Зависимые служебные таблицы
        /// </summary>
        public List<ApplicationObject> NestedObjects { get; set; } = new List<ApplicationObject>();

        public override string ToString()
        {
            return $"{TableName}:{TypeCode}";
        }
    }
}