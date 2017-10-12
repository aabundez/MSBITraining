--Sample code comes from [mdm].[udpStagingClear]

DECLARE @Batch_ID INT = 18461
			
DELETE FROM mdm.tblStgMember WHERE Batch_ID = @Batch_ID;
DELETE FROM mdm.tblStgMemberAttribute WHERE Batch_ID = @Batch_ID;
DELETE FROM mdm.tblStgRelationship WHERE Batch_ID = @Batch_ID;
DELETE FROM mdm.tblStgBatch WHERE ID = @Batch_ID;

DELETE FROM mdm.tblStgErrorDetail WHERE Batch_ID = @Batch_ID;