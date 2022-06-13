# Отслеживание изменений данных

SQL Server предоставляет [два основных механизма для отслеживания изменения данных](https://docs.microsoft.com/ru-ru/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver15):

* [Change Data Capture](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver15#Capture)
* [Change Tracking](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver15#Tracking)

Оба варианта позволяют приложениям отслеживать изменение данных операций вставки, обновления и удаления (DML), произведенных в пользовательских таблицах.

Раздел содержит примеры скриптов для работы с механизмами отслеживания изменений, а также некоторые особые примеры использования:
    * [Полный контроль над CDC для любых прилоежний](./CDC-Under-Control/Readme.md) - метод управления механизмом CDC для получения более полного контроля над происходящим.

## Полезные ссылки

* [Change Data Capture](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver15#Capture)
* [Change Tracking](https://docs.microsoft.com/en-us/sql/relational-databases/track-changes/track-data-changes-sql-server?view=sql-server-ver15#Tracking)
* [Правдивая история о тестировании SQL Server Change Data Capture](https://vimeo.com/131272382?embedded=true&source=vimeo_logo&owner=6267838)
* [Как мы Change Data Capture делали](https://highload.ru/spring/2021/abstracts/6570)
