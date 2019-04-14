# Настройка группы доступности AlwaysOn

Рассмотрим простой пример настройки групп доступности AlwaysOn для базы данных. На каждом этапе будет описание настроек и ссылки на дополнительную информацию.

## Перед настройкой

Для примера будем использовать простую базу данных "TestAG", скрипт для создания которой будет выглядеть следующим образом:

```sql
USE [master]
GO
CREATE DATABASE [TestAG]
 CONTAINMENT = NONE
 ON  PRIMARY 
( 
	NAME = N'TestAG', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\TestAG.mdf' , 
	SIZE = 8192KB , 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 65536KB )
 LOG ON 
( 
	NAME = N'TestAG_log', 
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\TestAG_log.ldf' , 
	SIZE = 8192KB , 
	MAXSIZE = 2048GB , 
	FILEGROWTH = 65536KB )
GO

CREATE TABLE [dbo].[SomeObjects](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](max) NULL,
 CONSTRAINT [PK_SomeObjects] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (
	PAD_INDEX = OFF, 
	STATISTICS_NORECOMPUTE = OFF, 
	IGNORE_DUP_KEY = OFF, 
	ALLOW_ROW_LOCKS = ON, 
	ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

USE [master]
GO
ALTER DATABASE [TestAG] SET READ_WRITE 
GO

```

Для использования AlwaysOn у базы должна стоять модель восстановления "Полная" (Full). Изначально база создана на сервере "SQL-AG-1". Далее создадим группу доступности и реплицируем базу на вторую ноду "SQL-AG-2".

## Создаем новую группу

В разработке...
