# Настройка распределенных групп доступности AlwaysOn

[Распределенные группы доступности](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver15) - это особый тип группы доступности AlwaysOn, который может охватывать сразу несколько отдельных групп доступности. Функционал доступен со SQL Server 2016.

В то время как в классической группе доступности AlwaysOn все узлы находятся в одном отказоустойчивом кластере Windows Server (WSFC) или в Pacemaker (для *.nix), распределенная группа доступности не настраивает свои ресурсы в базовом кластере. Все необходимые ресурсы хранятся непосредственно в SQL Server. Таким образом, распределенные группы доступности могут состоять из групп, находящихся в разных доменах и разных платформах, иметь различные версии Windows и Linux в узлах.

В итоге, мы имеем возможность создавать масштабируемые группы доступности практически любого уровня сложности. Основные цели использования данного механизма: отказоустойчивость, горизонтальное масштабирование, миграция данных на новое оборудование или площадки.

[В официальной документации есть отличный сквозной пример настройки](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/configure-distributed-availability-groups?view=sql-server-ver15&tabs=automatic). Ниже мы рассмотрим процесс настройки в более сжатом виде. Пример позволить понять общий подход к процессу настройки.

- [Что имеем](#что-имеем)
- [Дата-центр №1 (Тюмень)](#дата-центр-№1-тюмень)
    - [Локальная группа доступности](#локальная-группа-доступности-дц№1)
    - [Подготовка распределенной группы доступности](#подготовка-распределенной-группы-доступности-дц№1)
- [Дата-центр №3 (Новосибирск)](#дата-центр-№3-новосибирск)
    - [Локальная группа доступности](#локальная-группа-доступности-дц№3)
    - [Подготовка распределенной группы доступности](#подготовка-распределенной-группы-доступности-дц№3)
- [Соединяем Дата-центр №1 (Тюмень) и Дата-центр №2 (Москва)](#соединяем-дата-центр-№1-тюмень-и-дата-центр-№2-москва)
    - [Локальная группа доступности](#подготовка-локальной-группы-доступности-дц№2-для-базы-тюмени)
    - [Присоединение к распределенной группе доступности](#присоединение-к-распределенной-группе-доступности-дц№1)
- [Соединяем Дата-центр №3 (Новосибирск) и Дата-центр №2 (Москва)](#соединяем-дата-центр-№3-новосибирск-и-дата-центр-№2-москва)
    - [Локальная группа доступности](#подготовка-локальной-группы-доступности-дц№2-для-базы-новосибирска)
    - [Присоединение к распределенной группе доступности](#присоединение-к-распределенной-группе-доступности-дц№3)
- [Мы сделали это!](#мы-сделали-это)

## Что имеем

Допустим, у нас есть пять хостов в различных дата-центрах, которые к тому же географически удалены друг от друга:

* Дата-центр №1 (Тюмень):
    * SRV-SQL-1
    * SRV-SQL-2
* Дата-центр №2 (Москва):
    * SRV-SQL-3
* Дата-центр №3 (Новосибирск):
    * SRV-SQL-4
    * SRV-SQL-5

В ДЦ№1 города Тюмени у нас располагается база данных местного склада в городе Тюмень, при этом основной сервер это SRV-SQL-1, а рядом с ним находится резервная машина SRV-SQL-2 для целей отказоустойчивости и распределения нагрузки (второй сервер доступен для читающих запросов, отчетности и т.д.). 

В ДЦ№3 города Новосибирска также база данных местного склада в городе Новосибирск с основным сервером SRV-SQL-4 и резервным SRV-SQL5. Схема и цели схожи с конфигурацией в ДЦ№1.

Также есть ДЦ№2 в Москве с одним сервером SRV-SQL-3. По плану на этом сервере должны находится копии баз ДЦ№1 и ДЦ№2 с онлайн-синхронизацией данных на сколько это возможно.

Настройку такой конфигурации мы сейчас и рассмотрим. Целевая картина изображена на схеме ниже.

![Запускаем команду установки кластера](media/%D0%A0%D0%B0%D1%81%D0%BF%D1%80%D0%B5%D0%B4%D0%B5%D0%BB%D0%B5%D0%BD%D0%BD%D1%8B%D0%B5%20%D0%B3%D1%80%D1%83%D0%BF%D0%BF%D1%8B%20%D0%B4%D0%BE%D1%81%D1%82%D1%83%D0%BF%D0%BD%D0%BE%D1%81%D1%82%D0%B8/1.%20%D0%A1%D1%85%D0%B5%D0%BC%D0%B0%20%D1%83%D0%B7%D0%BB%D0%BE%D0%B2.png)

И так, поехали!

## Дата-центр №1 (Тюмень)

Опустим процесс настройки WSFC ([об этом читайте в соседних материалах](../Windows%20Server%20Failover%20Cluster/Readme.md)) и сразу перейдем к настройке групп доступности.

### Локальная группа доступности ДЦ№1

На сервере SRV-SQL-1 создадим группу доступности AlwaysOn для базы "Tyumen".

```sql
CREATE AVAILABILITY GROUP [AG-Tyumen]   
FOR DATABASE Tyumen   
REPLICA ON N'SRV-SQL-1' WITH (ENDPOINT_URL = N'TCP://SRV-SQL-1:5022',  
    FAILOVER_MODE = AUTOMATIC,  
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
    BACKUP_PRIORITY = 50,   
    SECONDARY_ROLE(ALLOW_CONNECTIONS = YES),   
    SEEDING_MODE = AUTOMATIC),   
N'SRV-SQL-2' WITH (ENDPOINT_URL = N'TCP://SRV-SQL-2:5022',   
    FAILOVER_MODE = AUTOMATIC,   
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
    BACKUP_PRIORITY = 50,   
    SECONDARY_ROLE(ALLOW_CONNECTIONS = YES),   
    SEEDING_MODE = AUTOMATIC);   
GO
```

В примере используется автоматическое заполнение баз на репликах (SEEDING_MODE = AUTOMATIC). При необходимости изменяйте эту настройку на ручное развертывание (MANUAL). Также под себя настраивайте другие параметры группы доступности.

Затем на SRV-SQL-2 подключаем сервер к группе доступности, при этом разрешаем создавать базу данных, чтобы отработало автоматическое заполнение.

```sql
ALTER AVAILABILITY GROUP [AG-Tyumen] JOIN   
ALTER AVAILABILITY GROUP [AG-Tyumen] GRANT CREATE ANY DATABASE  
GO  
```

Для создания распределенной группы доступности понадобится настроить прослушиватель для локальной группы.

```sql
ALTER AVAILABILITY GROUP [AG-Tyumen]    
    ADD LISTENER 'AG-Tyumen-Listener' ( 
        WITH IP ( ('2001:db88:f0:f00f::cf3c'),('2001:4898:e0:f213::4ce2') ) , 
        PORT = 60173);    
GO  
```

Локальная группа доступности теперь готова.

### Подготовка распределенной группы доступности ДЦ№1

Создадим распределенную группу доступности AlwaysOn на SRV-SQL-1, чтобы потом присоединить к ней реплику на SRV-SQL-3.

```sql
CREATE AVAILABILITY GROUP [AG-Tyumen-Distributed]
   WITH (DISTRIBUTED)   
   AVAILABILITY GROUP ON  
      'AG-Tyumen' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Tyumen-Listener:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      ),   
      'AG-Tyumen-Moscow' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Tyumen-Moscow-Listener:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      );    
GO
```

"AG-Tyumen" - это группа доступности на серверах SRV-SQL-1 и SRV-SQL-2, с настроенным прослушивателем "AG-Tyumen-Listener". 

"AG-Tyumen-Moscow" - это группа доступности на сервере SRV-SQL-3, которую мы создадим ниже. При этом прослушиватель у этой группы будет называться "AG-Tyumen-Moscow-Listener".

Теперь в первом ДЦ у нас настроена локальная группа доступности AlwaysOn, добавлен прослушиватель и подготовлена распределенная группа доступности.

## Дата-центр №3 (Новосибирск)

Аналогично настроим локальную группу доступности и подготовим вторую распределенную группу для дальнейшей настройки.

### Локальная группа доступности ДЦ№3

На сервере SRV-SQL-4 создадим группу доступности AlwaysOn для базы "Novosibirsk".

```sql
CREATE AVAILABILITY GROUP [AG-Novosibirsk]   
FOR DATABASE Novosibirsk   
REPLICA ON N'SRV-SQL-4' WITH (ENDPOINT_URL = N'TCP://SRV-SQL-4:5022',  
    FAILOVER_MODE = AUTOMATIC,  
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
    BACKUP_PRIORITY = 50,   
    SECONDARY_ROLE(ALLOW_CONNECTIONS = YES),   
    SEEDING_MODE = AUTOMATIC),   
N'SRV-SQL-5' WITH (ENDPOINT_URL = N'TCP://SRV-SQL-5:5022',   
    FAILOVER_MODE = AUTOMATIC,   
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
    BACKUP_PRIORITY = 50,   
    SECONDARY_ROLE(ALLOW_CONNECTIONS = YES),   
    SEEDING_MODE = AUTOMATIC);   
GO
```

Меняем настройки группы доступности по необходимости.

Затем на SRV-SQL-5 подключаем сервер к группе доступности, при этом разрешаем создавать базу данных, чтобы отработало автоматическое заполнение.

```sql
ALTER AVAILABILITY GROUP [AG-Novosibirsk] JOIN   
ALTER AVAILABILITY GROUP [AG-Novosibirsk] GRANT CREATE ANY DATABASE  
GO  
```

После добавляем прослушиватель.

```sql
ALTER AVAILABILITY GROUP [AG-Tyumen]    
    ADD LISTENER 'AG-Novosibirsk-Listener' ( 
        WITH IP ( ('2001:db88:f0:f00f::cf3c'),('2001:4898:e0:f213::4ce2') ) , 
        PORT = 60173);    
GO  
```

Далее подготовим вторую распределенную группу доступности.

### Подготовка распределенной группы доступности ДЦ№3

Создадим распределенную группу доступности AlwaysOn на SRV-SQL-4, чтобы потом присоединить к ней реплику на SRV-SQL-3.

```sql
CREATE AVAILABILITY GROUP [AG-Tyumen-Distributed]
   WITH (DISTRIBUTED)   
   AVAILABILITY GROUP ON  
      'AG-Novosibirsk' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Novosibirsk-Listener:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      ),   
      'AG-Novosibirsk-Moscow' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Novosibirsk-Moscow-Listener:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      );    
GO
```

"AG-Novosibirsk" - это группа доступности на серверах SRV-SQL-4 и SRV-SQL-5, с настроенным прослушивателем "AG-Novosibirsk-Listener". 

"AG-Novosibirsk-Moscow" - это группа доступности на сервере SRV-SQL-3, которую мы создадим ниже. При этом прослушиватель у этой группы будет называться "AG-Novosibirsk-Moscow-Listener".

Теперь в третьем ДЦ у нас настроена локальная группа доступности AlwaysOn, добавлен прослушиватель и подготовлена распределенная группа доступности.

## Соединяем Дата-центр №1 (Тюмень) и Дата-центр №2 (Москва)

Настало время присоединить SRV-SQL-3 к распределенной группе доступности "AG-Tyumen-Distributed".

### Подготовка локальной группы доступности ДЦ№2 для базы Тюмени

Сначала создадим локальную группу доступности на SRV-SQL-3, в которой будет только один узел - сам сервер. Группу, как уже было выше в скриптах, назовем "AG-Tyumen-Moscow".

```sql
CREATE AVAILABILITY GROUP [AG-Tyumen-Moscow]
WITH (
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    DB_FAILOVER = OFF,
    DTC_SUPPORT = NONE,
    REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0)
FOR DATABASE [Tyumen]
REPLICA ON N'SRV-SQL-3' WITH (
    ENDPOINT_URL = N'TCP://SRV-SQL-3.yy.corp:5022', 
    FAILOVER_MODE = MANUAL, 
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, 
    SESSION_TIMEOUT = 10, 
    BACKUP_PRIORITY = 50, 
    SEEDING_MODE = MANUAL, 
    PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL), 
    SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
GO
```

Чтобы отработало автоматическое создание базы на SRV-SQL-3 нужно разрешить это для группы доступности.

```sql
ALTER AVAILABILITY GROUP [AG-Tyumen-Moscow] GRANT CREATE ANY DATABASE  
GO  
```

Для примера нет задачи добавлять в эту группу другие узлы, но по факту никто не мешает это сделать в будущем. Добавляем прослушивателя.

```sql
ALTER AVAILABILITY GROUP [AG-Tyumen-Moscow]    
    ADD LISTENER 'AG-Tyumen-Moscow-Listener' ( 
        WITH IP ( ('2001:db88:f0:f00f::cf3c'),('2001:4898:e0:f213::4ce2') ) , 
        PORT = 60173);    
GO  
```

Не забываем указывать свои адреса для прослушивателя. И вообще не стесняемся менять настройки в скриптах при необходимости.

### Присоединение к распределенной группе доступности ДЦ№1

Когда локальная группа доступности на SRV-SQL-3 для базы "Tyumen" готова, остается присоединить ее к распределенной группе доступности "AG-Tyumen-Distributed", которая ранее была создана на SRV-SQL-1.

```sql
CREATE AVAILABILITY GROUP [AG-Tyumen-Distributed]
   WITH (DISTRIBUTED)   
   AVAILABILITY GROUP ON  
      'AG-Tyumen' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Tyumen-Listener:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      ),   
      'AG-Tyumen-Moscow' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Tyumen-Moscow-Listener:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      );    
GO
```

Готово! Так как у нас автоматическое заполнение баз, то через некоторое время на SRV-SQL-3 появится база "Tyumen" в группе доступности "AG-Tyumen-Moscow" с постоянным процессом синхронизации.

## Соединяем Дата-центр №3 (Новосибирск) и Дата-центр №2 (Москва)

Теперь проделаем аналогичные действия для базы с ДЦ№3 Новосибирск.

### Подготовка локальной группы доступности ДЦ№2 для базы Новосибирска

Создаем локальную группу.

```sql
CREATE AVAILABILITY GROUP [AG-Novosibirsk-Moscow]
WITH (
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    DB_FAILOVER = OFF,
    DTC_SUPPORT = NONE,
    REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0)
FOR DATABASE [Novosibirsk]
REPLICA ON N'SRV-SQL-3' WITH (
    ENDPOINT_URL = N'TCP://SRV-SQL-3.yy.corp:5022', 
    FAILOVER_MODE = MANUAL, 
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, 
    SESSION_TIMEOUT = 10, 
    BACKUP_PRIORITY = 50, 
    SEEDING_MODE = MANUAL, 
    PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL), 
    SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
GO
```

Разрешаем автоматическое создание базы.

```sql
ALTER AVAILABILITY GROUP [AG-Novosibirsk-Moscow] GRANT CREATE ANY DATABASE  
GO  
```

Для прослушивателя.

```sql
ALTER AVAILABILITY GROUP [AG-Novosibirsk-Moscow]    
    ADD LISTENER 'AG-Novosibirsk-Moscow-Listener' ( 
        WITH IP ( ('2001:db88:f0:f00f::cf3c'),('2001:4898:e0:f213::4ce2') ) , 
        PORT = 60173);    
GO  
```

Идем к включению в распределенную группу доступности.

### Присоединение к распределенной группе доступности ДЦ№3

И подключаемся к распределенной группе Новосибирска.

```sql
CREATE AVAILABILITY GROUP [AG-Novosibirsk-Distributed]
   WITH (DISTRIBUTED)   
   AVAILABILITY GROUP ON  
      'AG-Novosibirsk' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Novosibirsk-Listener:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      ),   
      'AG-Novosibirsk-Moscow' WITH    
      (   
         LISTENER_URL = 'tcp://AG-Novosibirsk-Moscow-Listener:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   
         SEEDING_MODE = AUTOMATIC   
      );    
GO
```

Готово, через некоторое время база "Novosibirsk" появится на SRV-SQL-3 и будет синхронизироваться с SRV-SQL-4.

## Мы сделали это!

Таким образом, у нас будут настроены локальные реплики в дата-центрах Тюмени и Новосибирска, а с помощью распределенных групп доступности AlwaysOn мы создали реплики на одном сервере в Москве для обеих баз.

## Послесловие

Механизм групп доступности AlwaysOn позволяет создавать реплики базы данных со сложными схемами, удовлетворяя почти все запросы на них. Никто не мешает создать реплики на реплики и так далее.

Поистине мощный механизм масштабирования и отказоустойчивости в умелых руках!

## Полезные ссылки

* [Что собой представляет распределенная группа доступности AlwaysOn](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver15)
* [Настройка распределенной группы доступности AlwaysOn](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/configure-distributed-availability-groups?view=sql-server-ver15&tabs=automatic)