# SQLCLR

SQL Server позволяет расширять собственные возможности за счет создания расширений с интеграцией со средой CLR. Среда CLR является основй платформы .NET предоставляет среду выполнения для управляемого кода. Таким образом, мжоно разрабатывать в управляемом коде хранимые процедуры, триггеры, пользовательские функции и типы.

Основные причины использования SQLCLR:

* Увеличение производительности некоторых операций.
* Добавление возможностей, которых нет в штатных механизмах SQL Server.

В целом, SQLCLR не является регулярным решением и его использование должно быть хорошо обосновано.

## Полезные ссылки

Материалы по теме.

* [Знакомство с интеграцией CLR в SQL Server](https://learn.microsoft.com/ru-ru/dotnet/framework/data/adonet/sql/introduction-to-sql-server-clr-integration) - официальная документация для начала работы со SQLCLR.
* [Использование SQLCLR для увеличения производительности](https://habr.com/ru/articles/88396/) - небольшой пример использования SQLCLR для оптимизации производитлеьности.
* [Getting started with SQL Server CLR functions](https://www.sqlshack.com/getting-started-with-sql-server-clr-functions/) - простой пример создания собственного расширения SQLCLR и его регистрации в SQL Server.
* [SQLCLR vs. T-SQL - Performance Comparison](https://www.c-sharpcorner.com/UploadFile/babu_2082/sqlclr-vs-t-sql-performance-comparison/) - небольшое сравнение производительности T-SQL и SQLCLR для объяснения когда и что лучше использовать.
* [SQL Server CLR Introduction](https://www.mssqltips.com/sqlservertip/7016/sql-clr-introduction/) - простая вводная в SQLCLR.
* Серия статей про SQLCLR на [sqlservercentral.com](https://www.sqlservercentral.com):

  * [Stairway to SQLCLR Level 1: What is SQLCLR?](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-1-what-is-sqlclr)
  * [Stairway to SQLCLR Level 2: Sample Stored Procedure and Function](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-2-sample-stored-procedure-and-function)
  * [Stairway to SQLCLR Level 3: Security (General and SAFE Assemblies)](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-3-security-general-and-safe-assemblies)
  * [Stairway to SQLCLR Level 4: Security (EXTERNAL and UNSAFE Assemblies)](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-4-security-external-and-unsafe-assemblies)
  * [Stairway to SQLCLR Level 5: Development (Using .NET within SQL Server)](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-5-development-using-net-within-sql-server)
  * [Stairway to SQLCLR Level 6: Development Tools Intro](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-6-development-tools-intro)
  * [Stairway to SQLCLR Level 7: Development and Security](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-7-development-and-security)
  * [Stairway to SQLCLR Level 8: Using Visual Studio to Work around SSDT](https://www.sqlservercentral.com/steps/stairway-to-sqlclr-level-8-using-visual-studio-to-work-around-ssdt)

* [SQL CLR Data Types and Performance](https://www.sqlservercentral.com/articles/sql-clr-data-types-and-performance)
* [HTTP Requests Using SQLCLR](https://www.sqlservercentral.com/articles/http-requests-using-sqlclr)
