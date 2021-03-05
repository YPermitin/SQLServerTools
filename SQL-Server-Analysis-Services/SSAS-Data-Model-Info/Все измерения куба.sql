-- Все измерения куба

SELECT [CATALOG_NAME] as [DATABASE],
CUBE_NAME AS [CUBE],DIMENSION_CAPTION AS [DIMENSION]
 FROM $system.MDSchema_Dimensions
WHERE CUBE_NAME  = '<Имя куба>' -- Измените отбор здесь
AND DIMENSION_CAPTION <> 'Measures'
ORDER BY DIMENSION_CAPTION