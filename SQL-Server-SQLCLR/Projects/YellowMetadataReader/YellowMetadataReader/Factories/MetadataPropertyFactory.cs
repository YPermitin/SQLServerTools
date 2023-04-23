using System;
using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;
using YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects;
using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Factories
{
    public abstract class MetadataPropertyFactory : IMetadataPropertyFactory
    {
        public MetadataPropertyFactory()
        {
            // ReSharper disable once VirtualMemberCallInConstructor
            InitializePropertyNameLookup();
        }
        protected abstract void InitializePropertyNameLookup();
        protected Dictionary<string, string> PropertyNameLookup { get; } = new Dictionary<string, string>();
        protected virtual string LookupPropertyName(string fieldName)
        {
            if (PropertyNameLookup.TryGetValue(fieldName.ToLowerInvariant(), out string propertyName))
            {
                return propertyName;
            }
            return string.Empty;
        }

        public string GetPropertyName(SqlFieldInfo field)
        {
            return LookupPropertyName(field.COLUMN_NAME);
        }
        public DatabaseField CreateField(SqlFieldInfo field)
        {
            return new DatabaseField()
            {
                Name = field.COLUMN_NAME,
                TypeName = field.DATA_TYPE,
                Length = field.CHARACTER_MAXIMUM_LENGTH,
                Scale = field.NUMERIC_SCALE,
                Precision = field.NUMERIC_PRECISION,
                IsNullable = field.IS_NULLABLE,
                Purpose = (field.DATA_TYPE == "timestamp"
                        || field.COLUMN_NAME == "_version"
                        || field.COLUMN_NAME == "_Version")
                            ? FieldPurpose.Version
                            : FieldPurpose.Value
            };
        }
        public MetadataProperty CreateProperty(ApplicationObject owner, string name, SqlFieldInfo field)
        {
            MetadataProperty property = new MetadataProperty()
            {
                Name = name,
                DbName = field.COLUMN_NAME,
                FileName = Guid.Empty,
                Purpose = PropertyPurpose.System
            };
            SetupPropertyType(owner, property, field);
            return property;
        }
        private void SetupPropertyType(ApplicationObject owner, MetadataProperty property, SqlFieldInfo field)
        {
            // TODO: учесть именования типов PostgreSQL, например (mchar, mvarchar)

            if (field.DATA_TYPE == "nvarchar")
            {
                property.PropertyType.CanBeString = true;
            }
            else if (field.DATA_TYPE == "numeric")
            {
                property.PropertyType.CanBeNumeric = true;
            }
            else if (field.DATA_TYPE == "timestamp")
            {
                property.PropertyType.IsBinary = true;
            }
            else if (field.DATA_TYPE == "binary")
            {
                if (field.CHARACTER_MAXIMUM_LENGTH == 1)
                {
                    property.PropertyType.CanBeBoolean = true;
                }
                else if (field.CHARACTER_MAXIMUM_LENGTH == 16)
                {
                    if (field.COLUMN_NAME.ToLowerInvariant().TrimStart('_') == "idrref")
                    {
                        property.PropertyType.IsUuid = true;
                    }
                    else
                    {
                        property.PropertyType.CanBeReference = true;
                        if (owner is TablePart)
                        {
                            property.PropertyType.ReferenceTypeCode = ((TablePart)owner).Owner.TypeCode;
                        }
                        else
                        {
                            property.PropertyType.ReferenceTypeCode = owner.TypeCode;
                        }
                    }
                }
            }
        }
    }
}
