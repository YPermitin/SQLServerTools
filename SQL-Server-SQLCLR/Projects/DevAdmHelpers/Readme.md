# DevAdmHelpers

Расширение SQLCLR для SQL Server с различными функциями для разработчиков и администраторов.

## Собранное решение

Собранную DLL для установки расширения SQLCLR можно скачать в разделе [релизы](https://github.com/YPermitin/SQLServerTools/releases).

## Обратная связь и новости

Вопросы, предложения и любую другую информацию [отправляйте на электронную почту](mailto:i.need.ypermitin@yandex.ru).

Новости по проектам или новым материалам в [Telegram-канале](https://t.me/TinyDevVault).

## Функциональность

В текущей версии добавлен модуль **EntryDiagnostic** с функциями:

* **GetSystemInfo** - получение системной информации о текущем контексте процесса SQL Server. Пример вывода:

| Name         | Value           | Description                                                        |
|--------------|-----------------|--------------------------------------------------------------------|
| VersionCLR   | 4.0.30319.42000 | Описание версии CLR                                                |
| OSUserName   | ypermitin       | Имя пользователя операционной системы, от которого запущен процесс |
| OSDomainName | YY              | Имя сетевого домена, связанное с текущим пользователем             |
| MachineName  | SRV-SQL-1       | Имя NetBIOS данного компьютера                                     |

* **GetEnvironmentVariables** - список переменных окружения с их значениями, которые доступны процессу SQL Server. Пример вывода:

| Name                            | Value                                                                                                                                                                                                                                           |
|---------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| COMPUTERNAME                    | SRV-SQL-1                                                                                                                                                                                                                                       |
| POWERSHELL_DISTRIBUTION_CHANNEL | MSI:Windows Server 2019 Standard                                                                                                                                                                                                                |
| PUBLIC                          | C:\Users\Public                                                                                                                                                                                                                                 |
| LOCALAPPDATA                    | C:\Users\ypermitin.YY\AppData\Local                                                                                                                                                                                                             |
| PSModulePath                    | %ProgramFiles%\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules;C:\Program Files (x86)\Microsoft SQL Server\150\Tools\PowerShell\Modules\;C:\Program Files (x86)\Microsoft SQL Server\110\Tools\PowerShell\Modules\ |
| PROCESSOR_ARCHITECTURE          | AMD64                                                                                                                                                                                                                                           |

## Окружение для разработки

Для окружение разработчика необходимы:

* [.NET Framework 4.8 SDK](https://support.microsoft.com/ru-ru/topic/microsoft-net-framework-4-8-автономный-установщик-для-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0)
* [.NET 6 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)
* [Visual Studio 2022](https://visualstudio.microsoft.com/ru/vs/)
* [Microsoft SQL Server 2012+](https://www.microsoft.com/ru-ru/sql-server/sql-server-downloads)

## Состав проекта

Проекты и библиотеки в составе решения:

* **Libs** - библиотеки и вспомогательные проекты.

	* **DevAdmHelpers** - проект библиотеки для расширения SQLCLR.

* **Tests** - модульные тесты и связанные проверки.

	* **DevAdmHelpers.Tests** - проект тестов для библиотеки DevAdmHelpers.

## Установка

Для установки нужно выполнить несколько шагов:

1. Собрать проект **DevAdmHelpers** в режиме **Release**.
2. Полученную DLL **DevAdmHelpers.dll** скопировать на сервер, где установлен экземпляр SQL Server. Пусть для примера путь к DLL на сервере будет **"C:\Share\SQLCLR\DevAdmHelpers.dll"**.
3. Выбрать базу для установки. Например, пусть она называется **SQLServerMaintenance**.

4. [Включим интеграцию с CLR](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/clr-integration-enabling?view=sql-server-ver16). Для упрощения настройки опустим некоторые аспекты безопасности и разрешим установку неподписанных расширений.

```sql
EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO  
ALTER DATABASE SQLServerMaintenance SET TRUSTWORTHY ON;
GO
```

Также разрешим текущему пользователю доступ к внешним ресурсам. Например, это пользователь **YY\ypermitin**.

```sql
use [master]; GRANT EXTERNAL ACCESS ASSEMBLY TO [YY\ypermitin];
```

5. Далее добавим сборку SQLCLR в базу **SQLServerMaintenance**.

```sql
USE [SQLServerMaintenance]
GO

CREATE ASSEMBLY [YPermitin.DevAdmHelpers.SQLCLR]
	FROM 'C:\Share\SQLCLR\DevAdmHelpers.dll'
	WITH PERMISSION_SET = UNSAFE;
GO
```

6. Теперь добавим две функции, чтобы обращаться к методам сборки из TSQL.

```sql
CREATE FUNCTION [dbo].[fn_GetSystemInfo]()  
RETURNS TABLE (
	[Name] nvarchar(512),
	[Value] nvarchar(4000),
	[Description] nvarchar(4000)
)
AS   
EXTERNAL NAME [YPermitin.DevAdmHelpers.SQLCLR].[YPermitin.SQLCLR.DevAdmHelpers.EntryDiagnostic].[GetSystemInfo];
GO

CREATE FUNCTION [dbo].[fn_GetEnvironmentVariables]()  
RETURNS TABLE (
	[Name] nvarchar(512),
	[Value] nvarchar(4000)
)
AS   
EXTERNAL NAME [YPermitin.DevAdmHelpers.SQLCLR].[YPermitin.SQLCLR.DevAdmHelpers.EntryDiagnostic].[GetEnvironmentVariables];
GO
```

7. Все готово для использования.

```sql
USE [SQLServerMaintenance]
GO

SELECT
	[Name],
	[Value],
	[Description]
FROM [dbo].[fn_GetSystemInfo]()
GO

SELECT
	[Name],
	[Value]
FROM [dbo].[fn_GetEnvironmentVariables]()
GO
```

Подробнее о настройках и разработке расширений SQLCLR можно найти материалы [здесь](../../).