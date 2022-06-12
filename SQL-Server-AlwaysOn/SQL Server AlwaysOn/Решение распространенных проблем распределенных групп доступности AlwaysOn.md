# Разбор частых проблем и вопросов при настройке распределенных групп доступности AlwaysOn

Есть вопрос - будет ответ :)

## Нет связи между серверами

Все узлы распределенной группы доступности настроены, прослушиватели созданы, брэндмауэр в порядке, но синхноризация все равно не работает. В этом случае нужно на каждом сервере проверить прослушивается ли порт для HADR. Обычно это 5022. В PowerShell наберите:

```pwsh
Get-NetTCPConnection | Where-Object { $_.LocalPort -eq 5022 }
```

Так мы увидим есть ли прослушиватель для этого порта.

| LocalAddress | LocalPort | RemoteAddress | RemotePort | State | AppliedSetting | OwningProcess |
| --- | --- | --- | --- | --- | --- | --- |
| :: | 5022 | :: | 0 | Listen | | 54388 |
10.2.1.1 | 5022 | 10.2.1.2 | 65365 | Established Datacenter | | 54388 |
0.0.0.0 | 5022 | 0.0.0.0 | 0 | Listen | | 54388 |

Если такой информации нет, то, скорее всего, Вам нужно на стороне SQL Server настроить точку подключения. Например, так:

```sql
CREATE ENDPOINT [Hadr_endpoint]
    STATE=STARTED
    AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
    FOR DATA_MIRRORING (ROLE = ALL, AUTHENTICATION = WINDOWS NEGOTIATE
, ENCRYPTION = REQUIRED ALGORITHM AES)
GO
```

После проблема должна быть решена. Проверить наличие точки подключения можно в SSMS по пути: Server Objects -> Endpoints -> Database Mirroring. В этой категории обычно присутствует точка подлючения с именем "Hadr_endpoint".

## У серверов нет доступа друг к другу

Сеть настроена, но доступа все равно нет? В логах SQL Server можно увидеть такое сообщение:

```
Database Mirroring login attempt by user 'yy\sqlserveraccount.' failed with error: 'Connection handshake failed. The login 'yy\sqlserveraccount' does not have CONNECT permission on the endpoint. State 84.'.  [CLIENT: 10.2.1.2]
```

Это значит, что учетная запись yy\sqlserveraccount, от имени которой запущен SQL Server, не имеет доступ к другому узлу распределенной группы доступности. Достаточно добавить доступ для этой учетной записи на всех необходимых сервера СУБД и проблема будет устранена.
