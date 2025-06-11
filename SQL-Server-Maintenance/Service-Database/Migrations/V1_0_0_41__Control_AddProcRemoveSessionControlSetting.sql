CREATE PROCEDURE [dbo].[sp_RemoveSessionControlSetting]
	@spid int = null
AS
BEGIN
	SET NOCOUNT ON;

	if(@spid is null)
	BEGIN
		SELECT @spid = @@SPID
	END

    DELETE FROM [dbo].[SessionControlSettings]
	WHERE [SPID] = @spid;
END