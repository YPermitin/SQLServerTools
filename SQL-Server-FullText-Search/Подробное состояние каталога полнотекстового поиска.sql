SELECT
	[cat].[name] AS [Каталог полнотекстового поиска],
    FULLTEXTCATALOGPROPERTY(cat.name,'ItemCount') AS [Всего элементов],
    CASE FULLTEXTCATALOGPROPERTY(cat.name,'MergeStatus')
		WHEN 1 THEN 'Активно'
		WHEN 0 THEN 'Не активно'
		ELSE 'Неизвестно'
	END AS [Слияние],
	-- Возвраст в секундах с 1990-01-01
    FULLTEXTCATALOGPROPERTY(cat.name,'PopulateCompletionAge') AS [Возрат каталога],
    CASE FULLTEXTCATALOGPROPERTY(cat.name,'PopulateStatus')
		WHEN 0 THEN 'Ожидание'
        WHEN 1 THEN 'Выполняется полное заполнение'
        WHEN 2 THEN 'Остановлен'
        WHEN 3 THEN 'Замедление'
        WHEN 4 THEN 'Восстанавливается'
        WHEN 5 THEN 'Отключен'
        WHEN 6 THEN 'Выполняется частичное заполнение'
        WHEN 7 THEN 'Построение индекса'
        WHEN 8 THEN 'Диск заполнен. Остановлен'
        WHEN 9 THEN 'Отслеживание изменений' 
		ELSE 'Неизвестно'
	END AS [PopulateStatus],
    CASE FULLTEXTCATALOGPROPERTY(cat.name,'ImportStatus')
		WHEN 1 THEN 'Да'
		WHEN 0 THEN 'Нет'
		ELSE 'Неизвестно'
	END AS [Импортирован]
FROM sys.fulltext_catalogs AS cat
