using YPermitin.SQLCLR.DevAdmHelpers;

namespace DevAdmHelpers.Tests
{
    public class EntryDiagnosticTest
    {
        [Fact]
        public void GetSystemInfoTest()
        {
            var systemInfoItems = EntryDiagnostic.GetSystemInfo();
            
            Assert.NotEmpty(systemInfoItems);
        }

        [Fact]
        public void GetEnvironmentVariablesTest()
        {
            var environmentVariables = EntryDiagnostic.GetEnvironmentVariables();

            Assert.NotEmpty(environmentVariables);
        }
    }
}