

/*
====================================================================================================
-- Create/Alter procedure usp_MDM_Member_Reactivate_Inactives
-- Author: Angel Abundez - DesignMind
y
-- Import Types:
-- Staging of MDS imports need an ImportType specified. Here is a list of the available values. More info
-- can be found at https://msdn.microsoft.com/en-us/library/ee633854(v=sql.110).aspx.
--
-- 0: Create new members. Replace existing MDS data with staged data.
-- 1: Create new members only. Updates to existing MDS data fail.
-- 2: Create new members. Replace existing MDS data with staged data.
-- 3: Deactivate members. If used as a DBA, deactivation will fail.
-- 4: Permanently delete members. If used as a DBA, deletion will fail.
-- 5: Deactivate members. If used as a DBA, related values will be set to NULL.
-- 6: Permanently delete members. If used as a DBA, related values will be set to NULL
--
-- TEST:
	-- run the following procs in this order to completely purge VERSION_1 of UMRCL

	EXEC dbo.usp_MDM_Member_Reactivate_Inactives @Entity='AttributesName', @Model='Store_Attributes'
	
	--DROP PROCEDURE dbo.usp_MDM_Member_Reactivate_Inactives
====================================================================================================
*/

CREATE PROCEDURE dbo.usp_MDM_Member_Reactivate_Inactives
	@Entity VARCHAR(250),
	@Model VARCHAR(250),
	@ProcessID INT = -1
AS
	--Declare error and logging variables
	DECLARE @LogString VARCHAR(120)
	DECLARE @Job_ID INT
	DECLARE @Job_Shrt_Desc VARCHAR(250)
	DECLARE @ErrorString1 VARCHAR(250)
	DECLARE @ErrorString2 VARCHAR(250)
	DECLARE @RowCount INT
	DECLARE @StagingBase VARCHAR(500)
	DECLARE @StageTable VARCHAR(500)
	DECLARE @SubscriptionView VARCHAR(500)
	DECLARE @BatchProc VARCHAR(500)
	DECLARE @EntityTable VARCHAR(250)
	

	SET @Job_ID = 7
	SET @Job_Shrt_Desc = 'usp_MDM_Member_Reactivate_Inactives'

	--******************************************** BEGIN PROCEDURE ********************************************

	SET @LogString = '**Begin reactivation of inactive members in MDS entity ' + @Entity + '.**'
    INSERT  INTO dbo.TALTH_JOB_LOG
    VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

	--************************************** BEGIN REACTIVATION OF INACTIVE MEMBERS IN ENTITY ****************************************
	
	--Script Variables
	DECLARE @RC int
	DECLARE @VersionName nvarchar(50)
	DECLARE @LogFlag int
	DECLARE @BatchTag nvarchar(50)
	DECLARE @Sql NVARCHAR(4000)

	SET @VersionName = N'VERSION_1'			--// DO NOT CHANGE
	SET @LogFlag = 1						--// DO NOT CHANGE



	SELECT @StagingBase = e.StagingBase,
		@EntityTable = e.EntityTable
	FROM MDS.mdm.tblEntity e 
	JOIN MDS.mdm.tblModel m ON e.Model_ID = m.ID
	WHERE m.Name = @Model
		AND e.Name = @Entity


	SET @StageTable = @StagingBase + '_Leaf'
	SET @BatchProc = 'udp_' + @StagingBase + '_Leaf'


	SELECT @SubscriptionView = sv.Name  
	FROM MDS.mdm.tblSubscriptionView sv
	JOIN MDS.mdm.tblModel m ON sv.Model_ID = m.ID
	JOIN MDS.mdm.tblEntity e ON sv.Entity_ID = e.ID
	WHERE m.Name = @Model
		AND e.Name = @Entity
	

	-- Reactivate inactive members in Entity Table

	BEGIN TRY

		SET @Sql = 'UPDATE MDS.mdm.' + @EntityTable + ' SET Status_ID = 1 WHERE Status_ID = 2' 
		EXEC sp_executesql @Sql

		SET @RowCount = @@ROWCOUNT

		IF @RowCount > 0
		SET @LogString = CAST(@RowCount AS VARCHAR(8)) + ' members have been reactivated in entity ' + @Entity
		INSERT  INTO dbo.TALTH_JOB_LOG
		VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

		IF @RowCount = 0
		BEGIN

			SET @LogString = @Entity + ' does not contain any inactive members. Procedure exiting.'
			INSERT  INTO dbo.TALTH_JOB_LOG
			VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

			RETURN;
		END

	END TRY

	BEGIN CATCH

		--Post log entries
        SET @LogString = '!!Update to entity table ' + @EntityTable + ' for entity ' + @Entity + ' FAILED.'
        SELECT @ErrorString1 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = 'Error Number ' + cast(ERROR_NUMBER() as Varchar(20)) + '; '
        SELECT @LogString = @LogString + 'Error Severity: ' + cast(ERROR_SEVERITY() as Varchar(20))+ '; '
        SELECT @LogString = @LogString + 'Procedure: usp_MDM_Member_Reactivate_Inactives'
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = ERROR_MESSAGE()
        SELECT @ErrorString2 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )
        
		RAISERROR(@LogString,16,1);

		RETURN;

	END CATCH

	

RETURN 0
