# YellowMetadataReader

Расширение SQLCLR для SQL Server с различными функциями для работы с информационными базами платформы 1С:Предприятие 8.x+. Базовый функционал расширения SQLCLR позволяет:

* Получить список баз 1С на SQL Server.
* Получить список таблиц базы 1С с расшифровкой имен в терминах прикладного решения платформы 1С.
* Получить список таблиц базы 1С с полями с расшифровкой имен в терминах прикладного решения платформы 1С.
* Получить список перечислений информационной базы 1С с расшифровкой их значений и порядка.
* Расшифровать внутренний формат данных 1С, хранящийся в двоичных данных, в читаемую (на сколько это возможно) строку.

Подробнее о возможностях и установки SQLCLR-расширения ниже.

## Собранное решение

Собранную DLL для установки расширения SQLCLR можно скачать в разделе [релизы](https://github.com/YPermitin/SQLServerTools/releases).

## Обратная связь и новости

Вопросы, предложения и любую другую информацию [отправляйте на электронную почту](mailto:i.need.ypermitin@yandex.ru).

Новости по проектам или новым материалам в [Telegram-канале](https://t.me/TinyDevVault).

## Благодарности

SQLCLR расширение **YellowMetadataReader** базируется на решении [Жичкина Дмитрия](https://github.com/zhichkin) - [dajet-metadata](https://github.com/zhichkin/dajet-metadata), которое изначально создавалось для чтения метаданных платформы 1С:Предприятие 8 напрямую из базы данных. Исходная версия поддерживает работу с SQL Server и PostgreSQL.

Выражаю огромную благодарность автору за его труды под [открытой лицензией](https://github.com/zhichkin/dajet-metadata/blob/main/LICENSE) и несгибаемую волю в намерении раскопать все что можно по работе "желтой" платформы.

Вопросы автору DeJet можете задать в [Telegram-канале](https://t.me/dajet_studio).

### Отличие от исходной разработки

Решение [dajet-metadata](https://github.com/zhichkin/dajet-metadata) было адаптировано под более узкие задачи:

* Переведено на платформу .NET Framework 4.8, т.к. SQLCLR базируется на работе именно этой среды выполнения CLR.
* Убрана поддержка PostgreSQL.
* Добавлено чтение некоторых служебных таблиц платформы 1С и распознавание их свойств (например, таблицы итогов регистров накопления, некоторые доп. поля для перечислений и констант и др.).

При этом сохранена в целом архитектура при работе с метаданными платформы 1С.

## Функциональность

В текущей версии добавлен модуль **EntryMetadata** со следующими функциями.

### GetInfobases

Получения списка баз, которые относятся к базам платформы 1С. Для каждой базы отображается информация о конфигурации и дате последнего обновления информационной базы из конфигуратора. Пример вывода функции для одной из баз 1С на сервере.

```sql
SELECT * FROM [dbo].[fn_GetInfobases]()
```

| InfobaseName | ConfigVersion | ConfigAlias                                                                    | ConfigName                         | ConfigUiCompatibilityMode | PlatformVersion | InfobaseLastUpdate      |
|--------------|---------------|--------------------------------------------------------------------------------|------------------------------------|---------------------------|-----------------|-------------------------|
| BSL-ORIG     | 3.1.7.34      | Демонстрационная конфигурация "Библиотека стандартных подсистем", редакция 3.1 | БиблиотекаСтандартныхПодсистемДемо | TaxiAllowVersion82        | 80314           | 2022-06-13 19:09:36.000 |

При этом базы, не относящиеся к платформе 1С, в списке не отображаются. Может использоваться для поиска в скриптах баз 1С по имени конфигурации или версии, например, в скриптах обслуживания.

### GetInfobaseTables

Получение списка таблиц информационной базы в терминах прикладного решения. Позволяет получить список таблиц информционной базы 1С с маппингом имени таблицы SQL с именем таблицы в терминах прикладного решения. Пример вывода ниже.

```sql
SELECT * FROM [dbo].[fn_GetInfobaseTables]('BSL-ORIG')
```

| TableSQL     | Table1C                                              |
|--------------|------------------------------------------------------|
| _Acc3930     | ПланСчетов._ДемоОсновной                             |
| _AccRg3942   | РегистрБухгалтерии._ДемоОсновной                     |
| _AccumRg505  | РегистрНакопления._ДемоОстаткиТоваровВМестахХранения |
| _AccumRg1265 | РегистрНакопления._ДемоОборотыПоСчетамНаОплату       |
| _Reference12 | Справочник._ДемоВидыНоменклатуры                     |

Может использоваться как для скриптов обслуживания, так и для анализа базы данных в понятных терминах прикладного решения (например, занятого места по таблицам и так далее).

### InfobaseTablesWithFields

Получение списка таблиц с полями информационной базы в терминах прикладного решения. Позволяет получить список таблиц информционной базы 1С с маппингом имени таблицы SQL с именем таблицы в терминах прикладного решения, при этом для каждой таблицы выводится список полей в терминах SQL-базы и прикладного решения. Пример вывода ниже.

```sql
SELECT * FROM [dbo].[fn_GetInfobaseTablesWithFields]('BSL-ORIG')
```

| TableSQL | Table1C                  | FieldSQL      | Field1C          |
|----------|--------------------------|---------------|------------------|
| _Acc3930 | ПланСчетов._ДемоОсновной | _IDRRef       | Ссылка           |
| _Acc3930 | ПланСчетов._ДемоОсновной | _Version      | ВерсияДанных     |
| _Acc3930 | ПланСчетов._ДемоОсновной | _Marked       | ПометкаУдаления  |
| _Acc3930 | ПланСчетов._ДемоОсновной | _PredefinedID | Предопределённый |
| _Acc3930 | ПланСчетов._ДемоОсновной | _ParentIDRRef | Родитель         |
| _Acc3930 | ПланСчетов._ДемоОсновной | _Code         | Код              |

Может использоваться как для скриптов обслуживания, так и для анализа базы данных в понятных терминах прикладного решения (например, занятого места по таблицам и так далее).

### GetInfobasesEnumerations

Получения списка перечислений информационной базы с их значениями в терминах прикладного решения. По умолчанию названия значений перечислений в базе данных в явном виде не хранятся. Данный методв позволяет получить к этой информации доступ без использования самой платформы 1С. Пример вывода ниже.

```sql
SELECT * FROM dbo.[fn_GetInfobasesEnumerations]('BSL-ORIG')
ORDER BY Enumeration, ValueOrder
```

| TableSQL  | Enumeration                                 | ValueId                              | ValueName | ValueAlias                           | ValueOrder |
|-----------|---------------------------------------------|--------------------------------------|-----------|--------------------------------------|------------|
| _Enum3932 | Перечисление._ДемоВидыПлатежейВБюджет       | a03d3535-090a-46f5-a411-3567c8c12bc1 | Налог     | Налог (взносы): начислено / уплачено | 0          |
| _Enum5120 | Перечисление._ДемоПолФизическогоЛица        | 5545798f-72dc-4630-a5ba-88039f4bfe3c | Мужской   | Мужской                              | 0          |
| _Enum5120 | Перечисление._ДемоПолФизическогоЛица        | f293ac4b-91ed-4c97-90b3-bfe98c983a0f | Женский   | Женский                              | 1          |
| _Enum5406 | Перечисление._ДемоСовместимостьНоменклатуры | b1d3d9e3-c33a-4a3c-acf5-9fa42c4f8718 | Полная    | Полная                               | 0          |
| _Enum5406 | Перечисление._ДемоСовместимостьНоменклатуры | 2f47632e-c9cf-4c99-ab40-37960b23b582 | Частичная | Частичная                            | 1          |

Может использоваться как для скриптов обслуживания, так и для анализа базы данных в понятных терминах прикладного решения (например, занятого места по таблицам и так далее). При определенных ограничениях может использоваться в целях построения хранилищ даннных и построения интеграций.

### InternalFormatData

Сервисная функция для преобразования двоичных данных внутреннего формата платформы 1С к читаемым (на сколько это возможно) строкам. Например, плафторма 1С хранит множество системных данных в базе в виде собственного формата. Данная функция позволит их прочитать в какой-то внятной форме.

```sql
SELECT [FileName]
	  ,[SQLServerMaintenance].dbo.fn_ParseInternalString(BinaryData) AS [FileDataAsString]
  FROM [BSL-ORIG].[dbo].[Params]
  WHERE FileName = 'DBNames'
```

| FileName | FileDataAsString |
| -------- | ---------------- |
| DBNames | <очень длинная строка, фрагмент ниже> |

```
{9063,
{5728,
{00000000-0000-0000-0000-000000000000,"SystemSettings",1},
{00000000-0000-0000-0000-000000000000,"CommonSettings",2},
{00000000-0000-0000-0000-000000000000,"RepSettings",3},
{00000000-0000-0000-0000-000000000000,"RepVarSettings",4},
...продолжение следует... |
```

В основном используется внутри компоненты SQLCLR для разбора метаданных конфигурации, но можно использовать и вручную для диагностики работы сложных моментов.

## Окружение для разработки

Для окружение разработчика необходимы:

* [.NET Framework 4.8 SDK](https://support.microsoft.com/ru-ru/topic/microsoft-net-framework-4-8-автономный-установщик-для-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0)
* [.NET 6 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)
* [Visual Studio 2022](https://visualstudio.microsoft.com/ru/vs/)
* [Microsoft SQL Server 2012+](https://www.microsoft.com/ru-ru/sql-server/sql-server-downloads)
* [Плафторма 1С 8.2 и новее](https://v8.1c.ru/platforma/).

## Состав проекта

Проекты и библиотеки в составе решения:

* **Apps** - различные приложения

	* **YellowMetadataReader.CLI** - пример приложения для работы с библиотекой.

* **Libs** - библиотеки и вспомогательные проекты.

	* **YellowMetadataReader** - проект библиотеки для расширения SQLCLR.

## Установка

Для установки необходимо выполнить несколько шагов:

1. Собрать проект **YellowMetadataReader** в режиме **Release**.
2. Полученную DLL **YellowMetadataReader.dll** скопировать на сервер, где установлен экземпляр SQL Server. Пусть для примера путь к DLL на сервере будет **"C:\Share\SQLCLR\YellowMetadataReader.dll"**.
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

5. Если ранее расширение SQLCLR устанавливалось, то удалим все зарегистрированные функции и саму сборку перед повторной установкой.

```sql
DROP FUNCTION IF EXISTS [dbo].[fn_GetInfobases];
DROP FUNCTION IF EXISTS [dbo].[fn_GetInfobaseTables];
DROP FUNCTION IF EXISTS [dbo].[fn_GetInfobaseTablesWithFields];
DROP FUNCTION IF EXISTS [dbo].[fn_ParseInternalString];
DROP FUNCTION IF EXISTS [dbo].[fn_GetInfobasesEnumerations];
DROP ASSEMBLY IF EXISTS [YPermitin.SQLCLR.YellowMetadataReader];
```

6. Далее добавим сборку SQLCLR в базу **SQLServerMaintenance**.

```sql
USE [SQLServerMaintenance]
GO

CREATE ASSEMBLY [YPermitin.SQLCLR.YellowMetadataReader]
	FROM 'C:\Share\SQLCLR\YellowMetadataReader.dll'
	WITH PERMISSION_SET = UNSAFE;
GO
```

6. Теперь добавим все функции расширения, которые были описаны выше.

```sql
CREATE FUNCTION [dbo].[fn_GetInfobases]()  
RETURNS TABLE (
	InfobaseName nvarchar(255),
	ConfigVersion nvarchar(250),
	ConfigAlias nvarchar(250),
	ConfigName nvarchar(250),
	ConfigUiCompatibilityMode nvarchar(50),
	PlatformVersion nvarchar(50),
	InfobaseLastUpdate datetime null
)
AS   
EXTERNAL NAME [YPermitin.SQLCLR.YellowMetadataReader].[YPermitin.SQLCLR.YellowMetadataReader.EntryMetadata].[GetInfobases];  
GO  

CREATE FUNCTION [dbo].[fn_GetInfobaseTables](@databaseName nvarchar(255))  
RETURNS TABLE (
	TableSQL nvarchar(512),
	Table1C nvarchar(512)
)
AS   
EXTERNAL NAME [YPermitin.SQLCLR.YellowMetadataReader].[YPermitin.SQLCLR.YellowMetadataReader.EntryMetadata].[GetInfobaseTables];  
GO  

CREATE FUNCTION [dbo].[fn_GetInfobaseTablesWithFields](@databaseName nvarchar(255))  
RETURNS TABLE (
	TableSQL nvarchar(512),
	Table1C nvarchar(512),
	FieldSQL nvarchar(512),
	Field1C nvarchar(512)
)
AS   
EXTERNAL NAME [YPermitin.SQLCLR.YellowMetadataReader].[YPermitin.SQLCLR.YellowMetadataReader.EntryMetadata].[GetInfobaseTablesWithFields];  
GO  

CREATE FUNCTION [dbo].[fn_GetInfobasesEnumerations](@databaseName nvarchar(255))  
RETURNS TABLE (
	TableSQL nvarchar(512),
	Enumeration nvarchar(512),
	ValueId nvarchar(512),	
	ValueName nvarchar(512),
	ValueAlias nvarchar(512),
	ValueOrder int
)
AS   
EXTERNAL NAME [YPermitin.SQLCLR.YellowMetadataReader].[YPermitin.SQLCLR.YellowMetadataReader.EntryMetadata].[GetInfobasesEnumerations];  
GO  

CREATE FUNCTION [dbo].[fn_ParseInternalString](@data [varbinary](max))
RETURNS nvarchar(max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [YPermitin.SQLCLR.YellowMetadataReader].[YPermitin.SQLCLR.YellowMetadataReader.EntryMetadata].[ParseInternalString];  
GO
```

7. Все готово для использования.

```sql
USE [SQLServerMaintenance]
GO

SELECT * FROM [dbo].[fn_GetInfobases] ()
GO

-- BSL-ORIG - имя тестовой баз данных.
SELECT * FROM [dbo].[fn_GetInfobaseTables]('BSL-ORIG')
GO

SELECT * FROM [dbo].[fn_GetInfobaseTablesWithFields]('BSL-ORIG')
GO

SELECT * FROM dbo.[fn_GetInfobasesEnumerations]('BSL-ORIG')
ORDER BY Enumeration, ValueOrder
GO
```

Подробнее о настройках и разработке расширений SQLCLR можно найти материалы [здесь](../../).


