/*
DROP PROCEDURE dbo.usp_MDM_Alert_Staging_Errors
GO
*/

CREATE PROCEDURE dbo.usp_MDM_Alert_Staging_Errors
		 @mailProfile VARCHAR(50),
		 @mailRecipients NVARCHAR(2000),
		 @stgerrors StagingErrors READONLY
AS

BEGIN
BEGIN TRY

	SET NOCOUNT ON;

	DECLARE @tableHTML NVARCHAR(MAX);

	SET @tableHTML =
		N'<html><head>' +
		N'<style>' +
		N'th {font-size:10pt;} ' +
		N'td {font-size:10pt;} ' +
		N'</style>' +
		N'</head>' +
		N'<body>' +
		N'<H2>Maestro Staging Error Details</H2>' +
		N'<table border="1">' +
		N'<tr><th>ID</th><th>ImportType</th><th>ImportStatus_ID</th><th>Batch_ID</th><th>BatchTag</th><th>Code</th><th>Name</th><th>MemberType</th><th>UniqueErrorCode</th><th>ErrorDescription</th><th>AttributeName</th><th>AttributeValue</th></tr>' +
		CAST(( 
			SELECT td = ID ,
					'' ,
				   td = ImportType ,
					'' ,
				   td = ImportStatus_ID ,
					'' ,
				   td = Batch_ID ,
					'' ,
				   td = BatchTag ,
					'' ,
				   td = Code ,
					'' ,
				   td = Name ,
					'' ,
				   td = MemberType ,
					'' ,
				   td = UniqueErrorCode ,
					'' ,
				   td = ErrorDescription ,
					'' ,
				   td = ISNULL(AttributeName, ' ') ,
					'' ,
				   td = ISNULL(AttributeValue, ' ') ,
					'' 
			FROM @stgerrors
			ORDER BY Batch_ID, ID
			FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX)) + N'</table></body></html>';

	IF (SELECT LEN(@tableHTML)) IS NOT NULL
		BEGIN
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @mailProfile , 
			@recipients = @mailRecipients ,
			@importance = 'High' ,
			@subject = 'Maestro Staging Error Details' , 
			@body = @tableHTML ,
			@body_format = 'HTML';
		END
END TRY

BEGIN CATCH
	RAISERROR('Error in sendStagingErrors', 10, 1) WITH NOWAIT;  

	DECLARE	 @ErrSeverity INT = ERROR_SEVERITY()
			,@ErrState INT = ERROR_STATE()
			,@ErrProc NVARCHAR(MAX) = ERROR_PROCEDURE()
			,@ErrLine INT = ERROR_LINE()
			,@ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();

	RAISERROR(N'%s (line %d): %s',	-- Message text w formatting
				@ErrSeverity,		-- Severity
				@ErrState,			-- State
				@ErrProc,			-- First argument (string)
				@ErrLine,			-- Second argument (int)
				@ErrMsg);			-- First argument (string)
              
	RETURN

END CATCH
END
GO