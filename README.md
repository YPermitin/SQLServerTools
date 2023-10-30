# SQL Server Tools

Инструменты обслуживания и разработки для Microsoft SQL Server, а также другие интересности.

## Инфо о репозитории

Репозиторий содержит полезные скрипты для анализа, разработки и обслуживания информационных систем на Microsoft SQL Server.

Материалы по другим темам Вы можете найти на сайте [ypermitin.github.io](https://ypermitin.github.io/), а новости по проектам или новым материалам в [Telegram-канале](https://t.me/TinyDevVault).

| № | Раздел | Описание |
| - | ------ | -------- |
| 1 | [Common-Info](SQL-Server-Common-Info) | Cкрипты общего назначения для просмотра состояния и настроек инстанса и др |
| 2 | [Data-Model-Info](SQL-Server-Data-Model-Info) | Просмотр модели данных и других связанных объектов |
| 3 | [Databases-Info](SQL-Server-Databases-Info) | Информация о базах данных |
| 4 | [Statistics](SQL-Server-Statistics) | Информация о статистиках, вопросах производительности и их анализе |
| 5 | [Indexes](SQL-Server-Indexes) | Информация об индексах, вопросах производительности и их анализе |
| 6 | [File-Groups](SQL-Server-File-Groups) | Информация о файловых группах |
| 7 | [Partitioned-Tables-and-Indexes](SQL-Server-Partitioned-Tables-and-Indexes) | Секционирование таблиц и индексов |
| 8 | [Perfomance](SQL-Server-Perfomance) | Производительность и оптимизация запросов, настроек сервера и поиск узких мест  |
| 9 | [Backup](SQL-Server-Backup) | Резервное копирование и восстановление данных |
| 10 | [Maintenance](SQL-Server-Maintenance) | Обслуживание баз данных и сервера |
| 11 | [1С-Extended-Settings](1С-Extended-Database-Settings-Maintenance) | Инструмент для поддержки произвольных индексов, изменение существующих объектов, сжатия таблиц и индексов, файловых групп и прочего для баз 1С:Предприятия |
| 12 | [BCP](SQL-Server-BCP) | Работа с утилитой Bulk Insert Programm (BCP) |
| 13 | [Bulk-Operations](SQL-Server-Bulk-Operations/) | Раздел с полезной информацией об операциях массовой модицикации данных |
| 14 | [AlwaysOn](SQL-Server-AlwaysOn) | О работе с группами высокой доступности AlwaysOn, настройке WSFC и др. |
| 15 | [Diagnostics](SQL-Server-Diagnostics) | Диагностика работы SQL Server |
| 16 | [FullText-Search](SQL-Server-FullText-Search) | Полнотекстовый поиск и все что с ним связано |
| 17 | [TempDB](SQL-Server-TempDB) | Все что связано с TempDB и временными таблицами |
| 18 | [Monitoring](SQL-Server-Monitoring) | Мониторинг стабильности и производительности |
| 19 | [Internals](SQL-Server-Internals) | Информация о внутренностях работы СУБД |
| 20 | [SSAS](SQL-Server-Analysis-Services) | Подраздел об [SQL Server Analysis Services](https://docs.microsoft.com/ru-ru/analysis-services/analysis-services-overview?view=asallproducts-allversions) |
| 21 | [PowerShell](SQL-Server-And-PowerShell) | Работа со SQL Server из PowerShell |
| 22 | [Linux](SQL-Server-On-Linux) | Работа со SQL Server под Linux |
| 23 | [Integration](SQL-Server-Integration) | Информация о средствах интеграции SQL Server с другими системами и наоборот. |
| 24 | [Jobs](SQL-Server-Jobs) | Информация о заданиях и их настройке. |
| 25 | [Trace-Flags](SQL-Server-Trace-Flags) | Флаги трассировки. |
| 26 | [Replication-And-High-Availability](SQL-Server-Replication-And-High-Availability) | Информация о механизмах репликации данных, высокой доступности и отказоустойчивости. |
| 27 | [Track-Data-Changes](SQL-Server-Track-Data-Changes) | Механизмы отслеживания изменения данных. |
| 28 | [Security](SQL-Server-Security) | Безопасность, управление доступом и связанные темы. |
| 29 | [SQLCLR](SQL-Server-SQLCLR) | Материалы по созданию расширений для SQL Server на базе SQLCLR. |
| 30 | [Docker](SQL-Server-Docker) | SQL Server и Docker |

## Полезные ссылки

* [MS SQL Server](https://docs.microsoft.com/ru-ru/sql/) - вся оффициальная информация о СУБД MS SQL Server
* [Tigertoolbox](https://github.com/Microsoft/tigertoolbox) - репозиторий с полезными инструментами от Tiger Team ([MSSQL Tiger Team](https://blogs.msdn.microsoft.com/sql_server_team/))
* [SQL-Server-First-Responder-Kit](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit) - скрипты и другая полезная информация от великого и ужасного (в хорошем смысле!) [Brent Ozar](https://github.com/BrentOzar) и [его команды](https://github.com/BrentOzarULTD)
* [Exploring Your SQL Server Databases with T-SQL](https://www.red-gate.com/simple-talk/sql/database-administration/exploring-your-sql-server-databases-with-t-sql/) - статья о исследование сервера MS SQL Server с помощью T-SQL ([Scott Swanberg](https://www.red-gate.com/simple-talk/author/scott-swanberg/))
* [Утки, Таиланд и T-SQL… или что может подстерегать программистов при работе с SQL Server?](https://habrahabr.ru/post/315142/) 
 -- все что нужно знать о странностях MS SQL Server ([Sergey Syrovatchenko](https://habrahabr.ru/users/AlanDenton/))
* [Useful links, scripts, tools and best practice for Microsoft SQL Server Database](https://github.com/ktaranov/sqlserver-kit) - полезные материалы из разряда "best practice" для MS SQL Server ([Konstantin
Ktaranov](https://github.com/ktaranov))
* [Статистика ожиданий SQL Server'а или пожалуйста, скажите мне, где болит](https://habrahabr.ru/post/216309/) -- Интересная информация об ожиданиях MS SQL Server ([Алексей Бородин](https://habrahabr.ru/users/minamoto/))
* [Улучшения tempdb в SQL Server 2016](http://sqlcom.ru/dba-tools/tempdb-in-sql-server-2016/) - Информация по оптимизации базы TempDB и мониторинга проблем с ней ([Зайцев Дмитрий](http://sqlcom.ru/author/sqlcom/))
* [Оптимизация временной БД (tempdb)](https://minyurov.com/2016/07/24/mssql-tempdb-opt/) - Дополнительные сведения по оптимизации базы TempDB ([Сергей Минюров](https://minyurov.com/author/minyurov/))
* [Стандарт оформления T-SQL](https://github.com/lestatkim/opensql/blob/master/tsql_standart.md) - Оформление кода T-SQL ([Lestat Kim](https://github.com/lestatkim))
* [Утилиты для MS SQL Server DBA](https://github.com/jobgemws/Projects-MS-SQL-Server-DBA) - Утилиты для DBA MS SQL Server ([Evgeniy Gribkov](https://github.com/jobgemws))
* [Данные JSON в SQL Server 2016/2017](https://docs.microsoft.com/ru-ru/sql/relational-databases/json/json-data-sql-server) - Работа с JSON в MS SQL Server
* [Создаем свои индексы для баз 1С. Со своей структурой и настройками!](https://ypermitin.github.io/sqlserver/2018/11/18/Создаем-свои-индексы-для-баз-1С.-Со-своей-структурой-и-настройками!.html) - Статья об использовании собственных индексов в информационных базах 1С:Предприятие 8.x. ([Permitin Yury](https://github.com/YPermitin))
* [Файловые группы MS SQL Server и 1С:Предприятие 8.x](https://ypermitin.github.io/FileGroupsAnd1C) - Описание примера использования файловых групп в информационой базе 1С:Предприятия 8.x ([Permitin Yury](https://github.com/YPermitin))
* [Секционирование таблиц и индексов в мире 1С](https://ypermitin.github.io/sqlserver/2019/02/10/Секционирование-таблиц-и-индексов-в-мире-1С.html) - Использование секционирования для баз 1С, сложности и подводные камни. ([Permitin Yury](https://github.com/YPermitin))
* [Cannot insert duplicate key. Кто виноват и что делать](https://infostart.ru/public/1010017/) - Информация по ошибке дублирования записи в уникальном индексе в контексте платформы 1С:Предприяние. ([Permitin Yury](https://github.com/YPermitin))
* [Быстрее чем INSERT! BULK-операции и примеры использования](https://ypermitin.github.io/sqlserver/2019/03/09/Быстрее-чем-INSERT!-BULK-операции-и-примеры-использования.html) - Использование BULK-операций в контексте платформы 1С:Предприятие и не только. ([Permitin Yury](https://github.com/YPermitin))
* [Как разбить базу на файлы и не сойти с ума](https://infostart.ru/public/1039011/) - Описание разбиения базы данных на отдельные файлы с помощью файловых групп и нюансы для баз 1С. ([Permitin Yury](https://github.com/YPermitin))
* [Самый быстрый шринк на Диком Западе](https://infostart.ru/public/1031815/) - о шринке баз данных и связанная полезная информация.
* [Самые распространенные заблуждения об индексах в мире 1С](https://infostart.ru/public/1158005/) - о самых распространенных ошибках при работе с индексами в контексте платформы 1С.
* [Копия базы 1С для отчетов. Как работать с репликой только для чтения](https://ypermitin.github.io/sqlserver/2019/04/22/Копия-базы-1С-для-отчетов.-Или-как-выжить-с-тяжелой-отчетностью.html) - использование "read-only" реплик для платформы 1С.
* [Копия базы 1С для отчетов. Как работать с репликой только для чтения](https://ypermitin.github.io/sqlserver/2022/04/30/Копия-базы-1С-для-отчетов.-Как-работать-с-репликой-только-для-чтения.html) - как использовать "read-only" реплики для плафтормы 1С, детальный разбор и пример использования.

* [MS SQL Server+1C Telegram Channel](https://t.me/mssqlplus1c) - Телеграмм канал по использованию Microsoft SQL Server и 1С. 

## Информация о производительности:

* [Мониторинг Microsoft SQL Server «на коленке»](https://habrahabr.ru/post/317426/) - пример решения, когда мониторинг SQL Server'а нужно настроить еще вчера. ([IndiraGandhi](https://habrahabr.ru/users/IndiraGandhi/))
* [Высокая нагрузка дисковой подсистемы на сервере СУБД MS SQL Server](https://its.1c.ru/db/metod8dev#content:5813:hdoc)
* [Высокая нагрузка на CPU MS SQL Server](https://its.1c.ru/db/metod8dev/content/5861/hdoc)
* [Running SQL Server on Machines with More Than 8 CPUs per NUMA Node May Need Trace Flag 8048](https://blogs.msdn.microsoft.com/psssql/2015/03/02/running-sql-server-on-machines-with-more-than-8-cpus-per-numa-node-may-need-trace-flag-8048/) - оптимизация SQL Server при наличии более 8 логических процессоров.

## Блог [Paul S. Randal](https://www.sqlskills.com/blogs/paul/)

* [Advanced SQL Server performance tuning](https://www.sqlskills.com/blogs/paul/advanced-performance-troubleshooting-waits-latches-spinlocks/)
* [A SQL Server DBA myth a day: (12/30) tempdb should always have one data file per processor core](https://www.sqlskills.com/blogs/paul/a-sql-server-dba-myth-a-day-1230-tempdb-should-always-have-one-data-file-per-processor-core/)
* [Inside The Storage Engine: GAM, SGAM, PFS and other allocation maps](https://www.sqlskills.com/blogs/paul/inside-the-storage-engine-gam-sgam-pfs-and-other-allocation-maps/)
* [Inside the Storage Engine: Using DBCC PAGE and DBCC IND to find out if page splits ever roll back](https://www.sqlskills.com/blogs/paul/inside-the-storage-engine-using-dbcc-page-and-dbcc-ind-to-find-out-if-page-splits-ever-roll-back/)

## Отказ от ответственности

Все содержимое репозитория предоставляется "AS-IS". Автор не несет ответственности за использование предоставленного материала.

## Другое

SQL Server хорошо, но также интересны и другие СУБД. Вот, например, [информация о PostgreSQL](https://github.com/YPermitin/PGTools).
