using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace YPermitin.SQLCLR.DevAdmHelpers
{
    public sealed class EntryDiagnostic : EntryBase
    {
        #region SystemInfo
        
        [SqlFunction(
            FillRowMethodName = "GetSystemInfoFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetSystemInfo()
        {
            List<SystemInfoItem> systemInfo = new List<SystemInfoItem>
            {
                new SystemInfoItem(
                    "VersionCLR", 
                    Environment.Version.ToString(),
                    "Описание версии CLR"),
                new SystemInfoItem(
                    "OSUserName", 
                    Environment.UserName,
                    "Имя пользователя операционной системы, от которого запущен процесс"),
                new SystemInfoItem(
                    "OSDomainName", 
                    Environment.UserDomainName,
                    "Имя сетевого домена, связанное с текущим пользователем"),
                new SystemInfoItem(
                    "UserInteractive", 
                    Environment.UserInteractive.ToString(),
                    "Признак работы в режиме взаимодействия с пользователем"),
                new SystemInfoItem(
                    "SystemDirectory", 
                    Environment.SystemDirectory,
                    "Полный путь к системному каталогу"),
                new SystemInfoItem(
                    "CurrentDirectory", 
                    Environment.CurrentDirectory,
                    "Полный путь к текущему рабочему каталогу"),
                new SystemInfoItem(
                    "CommandLine", 
                    Environment.CommandLine,
                    "Командная строка для текущего процесса"),
                new SystemInfoItem(
                    "MachineName", 
                    Environment.MachineName,
                    "Имя NetBIOS данного компьютера"),
                new SystemInfoItem(
                    "StackTrace", 
                    Environment.StackTrace,
                    "Текущие сведения о трассировке стэка"),
                new SystemInfoItem(
                    "OSVersion", 
                    Environment.OSVersion.ToString(),
                    "Информация о версии операционной системы"),
                new SystemInfoItem(
                    "CurrentManagedThreadId", 
                    Environment.CurrentManagedThreadId.ToString(),
                    "Идентификатор текущего управляемого потока"),
                new SystemInfoItem(
                    "HasShutdownStarted", 
                    Environment.HasShutdownStarted.ToString(),
                    "Признак завершения выгрузки текущего домена приложения или завершения среды CLR"),
                new SystemInfoItem(
                    "Is64BitOperatingSystem", 
                    Environment.Is64BitOperatingSystem.ToString(),
                    "Признак текущей операционной системы 64-разрядной"),
                new SystemInfoItem(
                    "Is64BitProcess", 
                    Environment.Is64BitProcess.ToString(),
                    "Текущий процесс является 64-битным"),
                new SystemInfoItem(
                    "ProcessorCount", 
                    Environment.ProcessorCount.ToString(),
                    "Количество процессоров"),
                new SystemInfoItem(
                    "SystemPageSize", 
                    Environment.SystemPageSize.ToString(),
                    "Количество байтов на странице памяти операционной системы"),
                new SystemInfoItem(
                    "TickCount", 
                    Environment.TickCount.ToString(),
                    "Время с момента загрузки операционной системы (в миллисекундах)"),
                new SystemInfoItem(
                    "WorkingSet", 
                    Environment.WorkingSet.ToString(),
                    "Объем физической памяти, сопоставленный текущему процессу")
            };
            
            return systemInfo;
        }
        public static void GetSystemInfoFillRow(object source, out SqlChars name, out SqlChars value, out SqlChars description)
        {
            var sourceObject = (SystemInfoItem)source;
            name = new SqlChars(sourceObject.Name);
            value = new SqlChars(sourceObject.Value);
            description= new SqlChars(sourceObject.Description);
        }
        public class SystemInfoItem
        {
            public string Name { get; set; }
            public string Value { get; set; }
            public string Description { get; set; }

            public SystemInfoItem(string name, string value, string description)
            {
                Name = name;
                Value = value;
                Description = description;
            }

            public override string ToString()
            {
                return $"{Name}:{Value}";
            }
        }

        #endregion

        #region Environment

        [SqlFunction(
                    FillRowMethodName = "GetEnvironmentVariablesFillRow",
                    SystemDataAccess = SystemDataAccessKind.Read,
                    DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetEnvironmentVariables()
        {
            var environmentVariables = Environment.GetEnvironmentVariables();

            var output = new List<EnvironmentVariableItem>();
            foreach (DictionaryEntry environmentVariable in environmentVariables)
            {
                output.Add(new EnvironmentVariableItem(
                    environmentVariable.Key.ToString(),
                    environmentVariable.Value.ToString()));
            }

            return output;
        }
        public static void GetEnvironmentVariablesFillRow(object source, out SqlChars name, out SqlChars value)
        {
            var sourceObject = (EnvironmentVariableItem)source;
            name = new SqlChars(sourceObject.Name);
            value = new SqlChars(sourceObject.Value);
        }
        public class EnvironmentVariableItem
        {
            public string Name { get; set; }
            public string Value { get; set; }
            public string Description { get; set; }

            public EnvironmentVariableItem(string name, string value)
            {
                Name = name;
                Value = value;
            }

            public override string ToString()
            {
                return $"{Name}:{Value}";
            }
        }


        #endregion
    }
}
