-- Список объектов с выделением памяти
-- https://docs.microsoft.com/ru-ru/openspecs/sql_server_protocols/ms-ssas/472486af-aa15-48bb-a6ef-b05f0da6f9ab

SELECT
    MemoryID AS [Идентификатор объекта в памяти],
    MemoryName AS [Имя объекта в памяти],
    SPID AS [ID сессии],
    CreationTime AS [Дата создания],
    BaseObjectType AS [Тип объекта],
    MemoryUsed AS [Объем памяти использован],
    MemoryAllocated AS [Объем памяти выделен],
    MemoryAllocBase AS [Объем памяти объекта при инициализации],
    MemoryAllocFromAlloc AS [Объем памяти объекта для содержимого],
    ElementCount AS [Количество элементов в объекте],
    Shrinkable AS [Память может быть освобождена],
    ObjectParentPath AS [Полный пукть к объекту],
    ObjectId AS [Идентификатор объекта],
    Group AS [Имя группы]
FROM $system.discover_memoryusage