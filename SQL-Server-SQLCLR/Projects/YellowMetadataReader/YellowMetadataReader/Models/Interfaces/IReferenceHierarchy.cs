using YPermitin.SQLCLR.YellowMetadataReader.Models.Enums;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models.Interfaces
{
    public interface IReferenceHierarchy
    {
        bool IsHierarchical { get; set; }
        HierarchyType HierarchyType { get; set; }
    }
}