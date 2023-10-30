# SQL Server - базовая настройка

Пример базовой настройки образа SQL Server для запуска через Docker Compose.

## Перед запуском

Перед запуском может понадобиться настроить права на каталоги.

```bash
mkdir -p fs
chgrp -R 0 fs
chmod -R g=u fs
chown -R 10001:0 fs
```

## Как запустить

При установленном Docker Engine и Docker Compose достаточно выполнить команду:

```bash
docker-compose up -d
```

Команду выполнять в каталоге с файлом docker-compose.yml. В результате будут созданы подкаталог fs с файлами конфигурации сервера SQL Server.