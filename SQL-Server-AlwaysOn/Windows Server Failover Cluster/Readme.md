# Отказоустойчивый кластера Windows Server

## Общие сведения

[Отказоустойчивый кластер на базе Windows Server](https://docs.microsoft.com/ru-ru/windows-server/failover-clustering/failover-clustering-overview) (Windows Server Failover Cluster - WSFC) - это решение кластеризации на платформе Microsoft Windows Server, основанное на совместной работе независимых компьютеров с целью повышения масштабируемости и доступности кластерных ролей.

На базе WSFC построены другие продукты и решения Microsoft, а также других вендоров. В том числе и технология [групп высокой доступности AlwaysOn](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server?view=sql-server-2017) для СУБД [SQL Server](https://www.microsoft.com/ru-ru/sql-server/sql-server-2017-editions), которая позволяет значительно повысить доступность баз данных и их масштабируемость за счет репликации базы на несколько инстансов.

Здесь будет информация об очень простой конфигурации WSFC, которая предназначена лишь для общего понимания последовательности действия при настройках. Более подробная информация по [плану развертывания](https://docs.microsoft.com/ru-ru/windows-server/failover-clustering/clustering-requirements) и других нюансах доступна в [официальной документации](https://docs.microsoft.com/ru-ru/windows-server/failover-clustering/failover-clustering-overview).

## Перед тем как начать

Для примера сделаем план для следующей конфигурации:

1. Имеем два сервера:
    - SQL-AG-1
    - SQL-AG-2
2. Оба сервера входят в некоторый домен, например в "YY.loc".
3. Для кворума будем использовать общий сетевой ресурс на некотором сервере "DC", который также находится в домене.

Все примеры сделаны в виртуализированной среде. Сходство с любой реальной инфраструктурой случайно! :)

Все требования рассматривать не будем, Вы можете сделать это самостоятельно в официальной документации.

## Установка, настройка, тестирование

Далее проходим каждый шаг и получаем работающий отказоустойчивый кластер:

1. [Установка WSFC](Установка%20WSFC.md)
2. [Тестирование WSFC](Тестирование%20WSFC.md)
3. [Создание и настройка WSFC](Создание%20и%20настройка%20WSFC.md)

Все готово!

## PowerShell vs. GUI

Почти все примеры с настройками компонентов Windows и SQL Server будут снабжены альтернативными способами настройки с помощью команд PowerShell. Для более подробной информации по синтаксису и использованию административных модулей PS можно обратиться к следующим материалам:

- [Windows Server Failover Cluster](https://docs.microsoft.com/en-us/powershell/module/failoverclusters/?view=win10-ps)
- [SQL Server](https://docs.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps)

## Внимание!

Эта инструкция не является всеобъемлющей документацией. С большой долей вероятности, в Вашем случае настройка будет выглядеть иначе и сложнее.

Информация из этой инструкции дается лишь в демонстрационных целях. Более подробные и достоверные данные следует брать [на сайте Microsoft](https://docs.microsoft.com/ru-ru/windows-server/failover-clustering/failover-clustering-overview).

## Полезные материалы

- [Отказоустойчивая кластеризация в Windows Server](https://docs.microsoft.com/ru-ru/windows-server/failover-clustering/failover-clustering-overview)
- [Что нового в Windows Server 2016 Failover Clustering](https://habr.com/ru/company/microsoft/blog/316928/)
- [Отказоустойчивый кластер Windows Server в Microsoft Azure. Хранилище данных](https://habr.com/ru/company/icl_services/blog/282822/)
