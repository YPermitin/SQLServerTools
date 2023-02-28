SELECT 
	-- Идентификатор соединения
	session_id,
	-- Размер транзакции в файле лога транзакций
	database_transaction_log_bytes_reserved
  FROM sys.dm_tran_database_transactions AS tdt 
  INNER JOIN sys.dm_tran_session_transactions AS tst 
  ON tdt.transaction_id = tst.transaction_id 
  WHERE database_id = db_id('tempdb')
order by database_transaction_log_bytes_reserved desc