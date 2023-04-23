using YPermitin.SQLCLR.YellowMetadataReader.Factories;
using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.MetaObjects
{
    public sealed class InformationRegister : ApplicationObject
    {
        public bool UseRecorder { get; set; }
        public RegisterPeriodicity Periodicity { get; set; } = RegisterPeriodicity.None;
    }
    public sealed class InformationRegisterPropertyFactory : MetadataPropertyFactory
    {
        protected override void InitializePropertyNameLookup()
        {
            // периодический регистр сведений
            PropertyNameLookup.Add("_period", "Период"); // необязательный datetime2
            // подчинённый регистратору
            PropertyNameLookup.Add("_recorderrref", "Регистратор"); // необязательный binary(16)
            PropertyNameLookup.Add("_recordertref", "Регистратор"); // необязательный binary(4)
            PropertyNameLookup.Add("_lineno", "НомерЗаписи"); // необязательный numeric(9,0)
            PropertyNameLookup.Add("_active", "Активность"); // необязательный binary(1)
        }
    }
}