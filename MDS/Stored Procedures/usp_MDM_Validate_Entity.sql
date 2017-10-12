
/*
====================================================================================================
-- Create/Alter procedure usp_MDM_Validate_Entity
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
	EXEC dbo.usp_MDM_Validate_Entity 'Credit_Card_Goals', 'Metric_Uploads'

	-- DROP PROCEDURE dbo.usp_MDM_Validate_Entity
====================================================================================================
*/

CREATE PROCEDURE dbo.usp_MDM_Validate_Entity
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
	DECLARE @EntityID INT
	DECLARE @VersionID INT
	DECLARE @UserID INT

	SET @Job_ID = 7
	SET @Job_Shrt_Desc = 'usp_MDM_Validate_Entity'

	--******************************************** BEGIN PROCEDURE ********************************************

	SET @LogString = '**Begin validate of MDS entity ' + @Entity + '.**'
    INSERT  INTO dbo.TALTH_JOB_LOG
    VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

	--************************************** BEGIN VALIDATION ****************************************
	
	--Script Variables
	DECLARE @RC int
	DECLARE @VersionName nvarchar(50)
	DECLARE @LogFlag int
	DECLARE @BatchTag nvarchar(50)
	DECLARE @Sql NVARCHAR(4000)

	SET @VersionName = N'VERSION_1'			--// DO NOT CHANGE
	SET @LogFlag = 1						--// DO NOT CHANGE


	--**************************************** VALIDATE THE MODEL ****************************************


	-- >> Check if Business Rules need to be run. Exit if not needed.

	SELECT @VersionID = mv.ID
	FROM MDS.mdm.tblModelVersion mv
	JOIN MDS.mdm.tblModel m ON mv.Model_ID = m.ID
	WHERE m.Name = @Model
	AND mv.Name = @VersionName

	SELECT @EntityID = e.ID 
	FROM MDS.mdm.tblEntity e 
	JOIN MDS.mdm.tblModel m ON e.Model_ID = m.ID
	WHERE m.Name = @Model
		AND e.Name = @Entity

	SELECT @SubscriptionView = sv.Name  
	FROM MDS.mdm.tblSubscriptionView sv
	JOIN MDS.mdm.tblModel m ON sv.Model_ID = m.ID
	JOIN MDS.mdm.tblEntity e ON sv.Entity_ID = e.ID
	WHERE m.Name = @Model
		AND e.Name = @Entity
	
	SET @Sql = '
	SELECT @RowCount = COUNT(*)' +
	'FROM MDS.mdm.' + @SubscriptionView + ' 
	WHERE ValidationStatus IN (''Awaiting Revalidation'', ''New, Awaiting Validation'')';

	EXEC sp_executesql @Sql, N'@RowCount INTEGER OUTPUT', @RowCount = @RowCount OUTPUT;


    IF @RowCount = 0
        BEGIN
            SELECT  @LogString = 'No records Awaiting Validation in ' + @Entity + '. Exiting';

            INSERT  INTO dbo.TALTH_JOB_LOG
            VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

            RETURN;
        END;

    SELECT  @LogString = 'Starting Validation of ' + @Entity;

    INSERT  INTO dbo.TALTH_JOB_LOG
    VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

	-- >> Run Business Rules on Model
	
	SET @UserID = (
		SELECT ID
		FROM MDS.mdm.tblUser
		WHERE UserName = 'AMERICAS\s-Maestroint');


	EXECUTE MDS.mdm.udpValidateEntity @UserID, @VersionID, @EntityID

	IF @@ERROR > 0
	BEGIN
		SET @LogString = '!!Validation of ' + @Entity + ' failed!!'
		INSERT  INTO dbo.TALTH_JOB_LOG
        VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );

        RAISERROR(@LogString,16,1);
	END

	SELECT  @LogString = 'Validation of ' + @Entity + ' succeeded';

    INSERT  INTO dbo.TALTH_JOB_LOG
    VALUES  ( @Job_ID, @ProcessID, @Job_Shrt_Desc, @LogString, GETDATE() );



	/***************************************************************************
	Profiler trace of running Business Rule on an entity.
	Incorporate if there is time.

	--Confirm Model
	declare @p9 int
	set @p9=11
	declare @p10 uniqueidentifier
	set @p10='B3AA471B-D8D0-4128-B421-166F54455AB9'
	declare @p11 nvarchar(500)
	set @p11=N'Financial_Location_Alt_Hierarchies'
	declare @p12 int
	set @p12=2
	exec mdm.udpObjectInformationLookup @UserID=1,@ObjectMUID='B3AA471B-D8D0-4128-B421-166F54455AB9',@ObjectID=NULL,@ObjectName=N'Financial_Location_Alt_Hierarchies',@ObjectTypeID=1,@ObjectSubTypeID=NULL,@ParentObjectID=NULL,@ParentObjectMUID=NULL,@ID=@p9 output,@MUID=@p10 output,@Name=@p11 output,@PrivilegeID=@p12 output
	select @p9, @p10, @p11, @p12

	--Confirm Version
	declare @p9 int
	set @p9=17
	declare @p10 uniqueidentifier
	set @p10='94EDC864-2FD1-4612-8647-B2FD082C2529'
	declare @p11 nvarchar(500)
	set @p11=N'Version_1'
	declare @p12 int
	set @p12=2
	exec mdm.udpObjectInformationLookup @UserID=1,@ObjectMUID='94EDC864-2FD1-4612-8647-B2FD082C2529',@ObjectID=NULL,@ObjectName=N'Version_1',@ObjectTypeID=4,@ObjectSubTypeID=NULL,@ParentObjectID=11,@ParentObjectMUID=NULL,@ID=@p9 output,@MUID=@p10 output,@Name=@p11 output,@PrivilegeID=@p12 output
	select @p9, @p10, @p11, @p12

	--Confirm Entity
	declare @p9 int
	set @p9=88
	declare @p10 uniqueidentifier
	set @p10='E2A2F69A-4FA2-46AE-9E43-A153DB20FA13'
	declare @p11 nvarchar(500)
	set @p11=N'District'
	declare @p12 int
	set @p12=2
	exec mdm.udpObjectInformationLookup @UserID=1,@ObjectMUID='E2A2F69A-4FA2-46AE-9E43-A153DB20FA13',@ObjectID=NULL,@ObjectName=N'District',@ObjectTypeID=5,@ObjectSubTypeID=NULL,@ParentObjectID=11,@ParentObjectMUID=NULL,@ID=@p9 output,@MUID=@p10 output,@Name=@p11 output,@PrivilegeID=@p12 output
	select @p9, @p10, @p11, @p12

	exec mdm.udpValidationQueueSave @User_ID=1,@Model_ID=12,@Version_ID=19,@Entity_ID=113,@Member_ID=NULL,@MemberType_ID=NULL,@CommitVersion=0

	*******************************************************************************/

RETURN 0
