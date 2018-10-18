-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Скрипт для создания служебной базы данных
-- =============================================================================================================

USE [master]
GO

CREATE DATABASE [ExtendedSettingsFor1C]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'ExtendedSettingsFor1C', FILENAME = N'E:\Bases\ExtendedSettingsFor1C.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'ExtendedSettingsFor1C_log', FILENAME = N'E:\Bases\ExtendedSettingsFor1C_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
