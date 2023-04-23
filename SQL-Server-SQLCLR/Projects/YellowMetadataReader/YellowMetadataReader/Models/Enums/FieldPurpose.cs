namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Enums
{
    public enum FieldPurpose
    {
        /// <summary>Value of the property (default).</summary>
        Value,
        /// <summary>Helps to locate fields having [boolean, string, number, binary, datetime, object] types</summary>
        Discriminator,
        /// <summary>Boolean value.</summary>
        Boolean,
        /// <summary>String value.</summary>
        String,
        /// <summary>Numeric value.</summary>
        Numeric,
        /// <summary>Binary value (bytes array).</summary>
        Binary,
        /// <summary>Date and time value.</summary>
        DateTime,
        /// <summary>Reference type primary key value.</summary>
        Object,
        /// <summary>Type code of the reference type (class discriminator).</summary>
        TypeCode,
        /// <summary>Record's version (timestamp|rowversion).</summary>
        Version,
        /// <summary>Ordinal key value for ordered sets of records.</summary>
        Ordinal
    }
}