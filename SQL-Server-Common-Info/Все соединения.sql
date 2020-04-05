DECLARE @AllConnections TABLE(
    SPID INT,
    Status VARCHAR(MAX),
    LOGIN VARCHAR(MAX),
    HostName VARCHAR(MAX),
    BlkBy VARCHAR(MAX),
    DBName VARCHAR(MAX),
    Command VARCHAR(MAX),
    CPUTime INT,
    DiskIO INT,
    LastBatch VARCHAR(MAX),
    ProgramName VARCHAR(MAX),
    SPID_1 INT,
    REQUESTID INT
)

INSERT INTO @AllConnections EXEC sp_who2

SELECT * FROM @AllConnections