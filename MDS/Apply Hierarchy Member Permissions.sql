USE MDS
GO

/* GET NAME OF MODEL
SELECT * FROM mdm.tblModel
*/

DECLARE @Model_ID INT;
SELECT @Model_ID = ID FROM mdm.tblModel WHERE [Name] = N'Merchandise_Alt_Hierarchies';
EXEC [mdm].[udpSecurityMemberProcessRebuildModel] @Model_ID=@Model_ID, @ProcessNow=1;
GO

