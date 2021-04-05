SELECT
	se.session_id,
	se.program_name,
	se.client_interface_name,
	con.net_transport,
	se.login_name,
	con.client_net_address,
	con.client_tcp_port
FROM
	sys.dm_exec_sessions AS se INNER JOIN
		sys.dm_exec_connections AS con ON se.session_id = con.session_id
ORDER BY se.program_name
