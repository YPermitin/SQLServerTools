using YPermitin.SQLCLR.YellowMetadataReader;

namespace YellowMetadataReader.CLI
{
    internal class Program
    {
        static void Main()
        {
            EntryBase.ConnectionString = "server=localhost;database=master;trusted_connection=true;";

            var infobases = EntryMetadata.GetInfobases();
            foreach (var infobase in infobases)
            {
                EntryMetadata.GetInfobasesFillRow(infobase,
                    out _, 
                    out _, 
                    out _, 
                    out _,
                    out _, 
                    out _, out _);
            }
        }
    }
}
