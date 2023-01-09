# Группы доступности AlwaysOn

Группы доступности AlwaysOn — это решение для высокой доступности и аварийного восстановления работоспособности базы данных, которые появились в редакции SQL Server 2012. По сути являются альтернативой зеркальному отображению данных (mirroring, зеркалирование).

Рассмотрим основные настройки этой технологии. Для более полной информации следует обратиться к [официальной документации](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/always-on-availability-groups-sql-server?view=sql-server-2017).

- [Основные требования](#основные-требования)
- [Установка и настройка SQL Server](#установка-и-настройка-sql-server)
- [Настройка AlwaysOn](#настройка-alwayson)
- [Настройка распределенных групп доступности AlwaysOn](#настройка-распределенных-групп-доступности-alwayson)
- [Некоторые особенности](#некоторые-особенности)
- [Полезные ссылки](#полезные-ссылки)

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

- Для того, чтобы появилась возможность использования AlwaysOn, нужно включить его использование на уровне инстанса. После изменения настройки потребуется перезапуск службы SQL Server. Сделать ее можно двумя способами:
    * Через диспетчер конфигурации SQL Server
    ![Включение AlwaysOn через диспетчер конфигурации SQL Server](media/Включение%20AlwaysOn%20через%20диспетчер%20конфигурации%20SQL%20Server.PNG)
    * Используя PowerShell
    ```PowerShell
    # Параметр ServerInstance указывает для какого инстанса SQL Server
    # необходимо включить AlwaysOn
    Enable-SqlAlwaysOn -ServerInstance SQL-AG-1
    ```
- Службы SQL Server на всех узлах должны быть запущены от единой доменной учетной записи.

Подробнее о включении AlwaysOn [читать здесь](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/enable-and-disable-always-on-availability-groups-sql-server?view=sql-server-2017), там же можно найти примеры включения.

## Настройка AlwaysOn

Самая подробная информация по настройке групп доступности AlwaysOn находится в [официальной документации](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server?view=sql-server-2017) в разделе ["Практическое руководство"](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/administration-of-an-availability-group-sql-server?view=sql-server-2017).

В этом репозитории Вы можете найти простой поэтапный пример настройки AlwaysOn с описанием настроек на каждом этапе. Находится он [вот здесь](Настройка%20группы%20доступности%20AlwaysOn.md). Эта информация может помочь получить общее представление о создании и настройке групп доступности.

## Настройка распределенных групп доступности AlwaysOn

Развитие технологии создания копий баз данных между разделенными группами AlwaysOn в разных кластерах WSFC или без них, разных платформах и так далее.

Добавляет существенно больше возможностей для органзиаций копий баз данных с распределенной инфраструктурой.

[Сквозной пример настройки и некоторые полезные материалы](./%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0%20%D1%80%D0%B0%D1%81%D0%BF%D1%80%D0%B5%D0%B4%D0%B5%D0%BB%D0%B5%D0%BD%D0%BD%D1%8B%D1%85%20%D0%B3%D1%80%D1%83%D0%BF%D0%BF%20%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%BD%D0%BE%D1%81%D1%82%D0%B8%20AlwaysOn.md) можно посмотреть здесь.

Кроме этого, в инструкции **[Решение распространенных проблем](./%D0%A0%D0%B5%D1%88%D0%B5%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B0%D1%81%D0%BF%D1%80%D0%BE%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B5%D0%BD%D0%BD%D1%8B%D1%85%20%D0%BF%D1%80%D0%BE%D0%B1%D0%BB%D0%B5%D0%BC%20%D1%80%D0%B0%D1%81%D0%BF%D1%80%D0%B5%D0%B4%D0%B5%D0%BB%D0%B5%D0%BD%D0%BD%D1%8B%D1%85%20%D0%B3%D1%80%D1%83%D0%BF%D0%BF%20%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%BD%D0%BE%D1%81%D1%82%D0%B8%20AlwaysOn.md)** решаются типичные проблемы при настройке распределенных групп доступности.

## Некоторые особенности

При работе с технологией AlwaysOn Вы можете встретиться с некоторыми нетривиальными вопросами. В [этом мануале](Некоторые%20особенности%20при%20работе%20с%20AlwaysOn.md) есть описание некоторых ситуаций, вопросов и проблем с описанием и решениями.

Отдельно рассмотрена проблема с [кэшем объектов статистики на репликах AlwaysOn](%D0%98%D1%81%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5%20%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC%D0%BD%D0%BE%D0%B3%D0%BE%20%D0%BA%D1%8D%D1%88%D0%B0%20%D0%BE%D0%B1%D1%8A%D0%B5%D0%BA%D1%82%D0%BE%D0%B2%20%D0%B4%D0%BB%D1%8F%20%D1%80%D0%B5%D0%BF%D0%BB%D0%B8%D0%BA%20AlwaysOn.md).

## Полезные ссылки

- [Группы доступности Always On](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server?view=sql-server-2017)
- [Реализация отказа в MS SQL Server 2017 Standard](https://habr.com/ru/post/342248/)
- [Top 7 Questions about Basic Availability Groups](https://blogs.technet.microsoft.com/msftpietervanhove/2017/03/14/top-5-questions-about-basic-availability-groups/)
- [Настройка MS SQL Server AlwaysOn. Шаг за Шагом](http://www.interface.ru/home.asp?artId=36680)
- [What is SQL Server AlwaysOn?](https://www.mssqltips.com/sqlservertip/4717/what-is-sql-server-alwayson/)