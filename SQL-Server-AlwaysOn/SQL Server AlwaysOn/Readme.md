# Группы доступности AlwaysOn

Группы доступности AlwaysOn — это решение для высокой доступности и аварийного восстановления работоспособности базы данных, которые появились в редакции SQL Server 2012. По сути являются альтернативой зеркальному отображению данных (mirroring, зеркалирование).

Рассмотрим основные настройки этой технологии. Для более полной информации следует обратиться к [официальной документации](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/always-on-availability-groups-sql-server?view=sql-server-2017).

## Основные требования

Для использования AlwaysOn нужно как минимум соответствовать следующим требованиям:
- SQL Server 2012 и выше редакции Enterprise Edition. Также функционал доступен для Standard Edition, но с ограничениями:
    * Максимум 2 реплики (первичная и вторичная)
    * Нет доступа на чтение для второй реплики
    * Только одна база в каждой группе доступности.
- Операционная система Windows Server 2012 и выше.
- Настроенный отказоустойчивый кластер Windows (WSFC).

[Простая пошаговая инструкция](../Windows%20Server%20Failover%20Cluster) по настройке отказоустойчивого кластера Windows в этом репозитории, а также другая полезная по кластеризации.

Но и это еще не все. Рекомендую ознакомиться с официальной документации, там более [детальная информация](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/prereqs-restrictions-recommendations-always-on-availability?view=sql-server-2017).

## Установка и настройка SQL Server

Сам процесс установки инстанса SQL Server на всех нодах кластера Windows тривиален. Главное установить компонент "Database Engine". Поэтому особо этот процесс описывать не будем, однако всегда можно узнать [все необходимое на сайте Microsoft](https://docs.microsoft.com/ru-ru/sql/database-engine/install-windows/install-sql-server?view=sql-server-2017).

Но все же есть пару моментов, о которых нужно упомянуть:
- На все узлы кластера, которые будут использоваться для группы доступности AlwaysOn, необходимо установить *изолированный экземпляр SQL Server*.

![Что установить на узлах WSFC для AlwaysOn](media/Установка%20инстанса%20(не%20кластер%20SQL).PNG)

- Для того, чтобы появилась возможность использования AlwaysOn, нужно включить его использование на уровне инстанса. Это можно сделать двумя способами:
    * Через диспетчер конфигурации SQL Server
    ![Включение AlwaysOn через диспетчер конфигурации SQL Server](media/Включение%20AlwaysOn%20через%20диспетчер%20конфигурации%20SQL%20Server.PNG)
    * Используя PowerShell
    ```PowerShell
    # Параметр ServerInstance указывает для какого инстанса SQL Server
    # необходимо включить AlwaysOn
    Enable-SqlAlwaysOn -ServerInstance SQL-AG-1
    ```
После изменения настройки потребуется перезапуск службы SQL Server.

Подробнее о включении AlwaysOn [читать здесь](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/enable-and-disable-always-on-availability-groups-sql-server?view=sql-server-2017), там же можно найти примеры включения.

## Настройка AlwaysOn

В разработке...

## Некоторые особенности

В разработке...

## Полезные ссылки

- [Группы доступности Always On](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server?view=sql-server-2017)
- [Реализация отказа в MS SQL Server 2017 Standard](https://habr.com/ru/post/342248/)
- [Top 7 Questions about Basic Availability Groups](https://blogs.technet.microsoft.com/msftpietervanhove/2017/03/14/top-5-questions-about-basic-availability-groups/)
- [Настройка MS SQL Server AlwaysOn. Шаг за Шагом](http://www.interface.ru/home.asp?artId=36680)
- [What is SQL Server AlwaysOn?](https://www.mssqltips.com/sqlservertip/4717/what-is-sql-server-alwayson/)