using YPermitin.SQLCLR.YellowMetadataReader.Factories;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    /// <summary>
    /// Регистр накопления (таблица итогов)
    /// </summary>
    public sealed class AccumulationRegisterTotal : ApplicationObject
    {
    }
    public sealed class AccumulationRegisterTotalPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            PropertyNameLookup.Add("_period", "Период"); // datetime2
            PropertyNameLookup.Add("_recorder", "Регистратор"); // _RecorderRRef binary(16) | _RecorderTRef binary(4) + _RecorderRRef binary(16)
            PropertyNameLookup.Add("_lineno", "НомерЗаписи"); // НомерЗаписи numeric(9,0)
            PropertyNameLookup.Add("_active", "Активность"); // binary(1)
            PropertyNameLookup.Add("_recordkind", "ВидДвижения"); // numeric(1,0) - только регистры остатков
            // _Splitter numeric(10,0) not null - разделитель итогов _AccumRgT85 _AccumRgTn91
        }
    }
}