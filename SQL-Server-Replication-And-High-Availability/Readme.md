# Репликация данных и механизмы высокой доступности и отказоустойчивости

SQL Server предоставляет различные технологии по органзиации репликации баз данных и обеспечение высокой доступности и отказоустойчивости. 

[В официальной документации](https://docs.microsoft.com/ru-ru/sql/relational-databases/replication/sql-server-replication?view=sql-server-ver15) достаточно подробно расписаны все возможности в части репликации данных. Там же можно найти информацию о [типах репликации данных](https://docs.microsoft.com/ru-ru/sql/relational-databases/replication/types-of-replication?view=sql-server-ver15).

Кроме классических технологий репликации, для создания копий баз данных могут применять такие методы как [доставка логов транзакций (log shippin)](https://docs.microsoft.com/ru-ru/sql/database-engine/log-shipping/about-log-shipping-sql-server?view=sql-server-ver15), а также создание онлайн-копий баз данных с помощью [групп высокой доступности AlwaysOn](https://docs.microsoft.com/ru-ru/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server?view=sql-server-ver15), о которых уже шла речь [в другом разделе](/SQL-Server-AlwaysOn/Readme.md).

И, конечно же, механизмы [зеркалирования баз данных](https://docs.microsoft.com/ru-ru/sql/database-engine/database-mirroring/database-mirroring-sql-server?view=sql-server-ver15), основное назначение которого - это повышение доступности баз данных.

В этом разделе собрана информация по всем этим технологиям обеспечения высокой доступности SQL Server и механизмам с примерами использования, полезными ссылками и так далее.

* [Группы высокой доступности AlwaysOn](/SQL-Server-AlwaysOn/Readme.md)
* [Доставка журналов транзакций](/Log-SQL-Server-AlwaysOn/Readme.md)
* [Зеркалирование](/SQL-Server-Replication-And-High-Availability/Mirroring/Readme.md)
* [Репликация данных](/SQL-Server-Replication-And-High-Availability/Replication/Readme.md)
  * Репликация транзакций
  * Репликация слиянием
  * Репликация моментальных снимков
  * Одноранговая репликация
  * Двунаправленная репликация
  * Обновляемые подписки

Вот он, мир удивительных путешествий в мире технологий репликации данных, отказоустойчивости и высокой доступности!
