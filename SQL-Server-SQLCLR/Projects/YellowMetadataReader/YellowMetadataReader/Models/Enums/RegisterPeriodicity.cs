namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Enums
{
    public enum RegisterPeriodicity
    {
        None = 0,
        Year = 1,
        Quarter = 2,
        Month = 3,
        Day = 4,
        Second = 5,
        Recorder = 6 // Регистр сведений, подчинённый регистратору, с периодичностью по позиции регистратора
    }
}