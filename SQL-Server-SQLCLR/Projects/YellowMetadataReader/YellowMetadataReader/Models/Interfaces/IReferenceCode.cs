using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces
{
    public interface IReferenceCode
    {
        int CodeLength { get; set; }
        CodeType CodeType { get; set; }
    }
}