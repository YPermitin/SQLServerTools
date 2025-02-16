using System;

namespace YPermitin.SQLCLR.ClickHouseClient.Utility
{
    [AttributeUsage(AttributeTargets.Field)]
    internal class SinceVersionAttribute : Attribute
    {
        public SinceVersionAttribute(string version) => Version = Version.Parse(version);

        public Version Version { get; }
    }
}