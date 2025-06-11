CREATE FUNCTION [dbo].[fn_ConvertBinary1CIdToUniqueidentifier] 
(
	@uuidAsBinary binary(16)
)
RETURNS uniqueidentifier
AS
BEGIN
	DECLARE @uuid1C binary(16) = CAST(REVERSE(SUBSTRING(@uuidAsBinary, 9, 8)) AS binary(8)) + SUBSTRING(@uuidAsBinary, 1, 8);

	RETURN CAST(@uuid1C AS uniqueidentifier);
END