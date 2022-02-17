select
	name,
	is_cdc_enabled
from sys.databases
where is_cdc_enabled = 1