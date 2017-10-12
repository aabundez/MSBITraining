

/*
====================================================================================================
-- Create/Alter procedure usp_MDM_Purge_Entity
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
	EXEC dbo.usp_MDM_Purge_Entity 'Alternate_SubClass'
	EXEC dbo.usp_MDM_Purge_Entity 'SubClass'
	EXEC dbo.usp_MDM_Purge_Entity 'Alternate_Class'
	EXEC dbo.usp_MDM_Purge_Entity 'Class'
	EXEC dbo.usp_MDM_Purge_Entity 'Department'
	EXEC dbo.usp_MDM_Purge_Entity 'Division'
	EXEC dbo.usp_MDM_Purge_Entity 'Brand'
	EXEC dbo.usp_MDM_Purge_Entity 'ParentBrand'

	EXEC dbo.usp_MDM_Purge_Entity @Entity='AttributeVal', @Model='Store_Attributes'

	-- run the following truncate statements to clear normalized tablesDesign
	TRUNCATE TABLE dbo.STG_UNIV_PARENTBRAND
	TRUNCATE TABLE DBO.STG_UNIV_BRAND
	TRUNCATE TABLE dbo.STG_UNIV_DIV
	TRUNCATE TABLE DBO.STG_UNIV_DEPT
	TRUNCATE TABLE DBO.STG_UNIV_CLS
	TRUNCATE TABLE DBO.STG_UNIV_SCLS
====================================================================================================
*/

CREATE PROCEDURE dbo.usp_MDM_Purge_Entity
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
	

	SET @Job_ID = 7
	SET @Job_Shrt_Desc = 'usp_MDM_Purge_Entity'

	--******************************************** BEGIN PROCEDURE ********************************************

	SET @LogString = '**Begin purge of MDS entity ' + @Entity + '.**'
    INSERT  INTO dbo.TALTH_JOB_LOG
    VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

	--************************************** BEGIN PURGE ENTIRE ENTITY ****************************************
	
	--Script Variables
	DECLARE @RC int
	DECLARE @VersionName nvarchar(50)
	DECLARE @LogFlag int
	DECLARE @BatchTag nvarchar(50)
	DECLARE @Sql NVARCHAR(4000)

	SET @VersionName = N'VERSION_1'			--// DO NOT CHANGE
	SET @LogFlag = 1						--// DO NOT CHANGE


	SET @BatchTag = N'Purge_' + @Entity + '_' + CONVERT(VARCHAR(8), GETDATE(), 12) + '_' + REPLACE ( CONVERT(VARCHAR(5), GETDATE(), 114), ':', '')	--// Update. Use unique value


	SELECT @StagingBase = e.StagingBase
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
	
	BEGIN TRY
		-- Reset staging
		SET @Sql = 'TRUNCATE TABLE MDS.stg.' + @StageTable 
		EXEC sp_executesql @Sql


		SET @LogString = 'Truncated staging table for ' + @Entity + ' entity'
		INSERT  INTO dbo.TALTH_JOB_LOG
		VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

	END TRY

	BEGIN CATCH

		SET @LogString = '!!Truncation of staging for ' + @Entity + ' FAILED.'
        SELECT @ErrorString1 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = 'Error Number ' + cast(ERROR_NUMBER() as Varchar(20)) + '; '
        SELECT @LogString = @LogString + 'Error Severity: ' + cast(ERROR_SEVERITY() as Varchar(20))+ '; '
        SELECT @LogString = @LogString + 'Procedure: usp_MDM_Purge_Entity'
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = ERROR_MESSAGE()
        SELECT @ErrorString2 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )
        
		RAISERROR(@LogString,16,1);

		RETURN;

	END CATCH


	-- Populate staging

	BEGIN TRY

		SET @Sql = '
		INSERT INTO MDS.stg.' + @StageTable + '
				( ImportType ,
					ImportStatus_ID ,
					BatchTag ,
					Code 
				)
		SELECT
			4 ,			-- ImportType - tinyint
			0 ,			-- ImportStatus_ID - tinyint
			''' + @BatchTag + ''' , -- BatchTag - nvarchar(50)
			[Code]		-- Code - nvarchar(250)
		FROM MDS.mdm.' + @SubscriptionView
		EXEC sp_executesql @Sql

		SET @RowCount = @@ROWCOUNT

		IF @RowCount > 0
		SET @LogString = 'Batch for ' + @Entity + ' created. BatchTag: ' + @BatchTag
		INSERT  INTO dbo.TALTH_JOB_LOG
		VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

		IF @RowCount = 0
		BEGIN

			SET @LogString = @Entity + ' entity empty. No Batch created. Procedure exiting.'
			INSERT  INTO dbo.TALTH_JOB_LOG
			VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

			RETURN;
		END

	END TRY

	BEGIN CATCH

		--Post log entries
        SET @LogString = '!!Batch creation for ' + @Entity + ' FAILED.'
        SELECT @ErrorString1 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = 'Error Number ' + cast(ERROR_NUMBER() as Varchar(20)) + '; '
        SELECT @LogString = @LogString + 'Error Severity: ' + cast(ERROR_SEVERITY() as Varchar(20))+ '; '
        SELECT @LogString = @LogString + 'Procedure: usp_MDM_Purge_Entity'
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = ERROR_MESSAGE()
        SELECT @ErrorString2 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )
        
		RAISERROR(@LogString,16,1);

		RETURN;

	END CATCH

	-- Execute batch
	BEGIN TRY
			
		SET @Sql = 'EXECUTE MDS.stg.' + @BatchProc + '
			''' + @VersionName + '''
			,' + CONVERT(VARCHAR(5), @LogFlag) + '
			,''' + @BatchTag + ''''
		EXEC sp_executesql @Sql

		SET @LogString = 'Batch completed successfully. BatchTag: ' + @BatchTag
		INSERT  INTO dbo.TALTH_JOB_LOG
		VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

	END TRY

	BEGIN CATCH

		--Post log entries
        SET @LogString = '!!Execution of Batch ' + @BatchTag + ' FAILED.'
        SELECT @ErrorString1 = @LogString
        INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() )

        SELECT @LogString = 'Error Number ' + cast(ERROR_NUMBER() as Varchar(20)) + '; '
        SELECT @LogString = @LogString + 'Error Severity: ' + cast(ERROR_SEVERITY() as Varchar(20))+ '; '
        SELECT @LogString = @LogString + 'Procedure: usp_MDM_Purge_Entity'
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
