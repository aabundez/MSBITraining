USE MDS
GO

SELECT 
	e.Name,
	br.Priority,
	br.Name,
	br.RuleConditionText,
	br.RuleActionText,
	br.Status_ID
FROM mdm.tblBRBusinessRule br
JOIN mdm.tblEntity e ON br.Foreign_ID = e.ID
JOIN mdm.tblModel m ON e.Model_ID = m.ID
WHERE m.Name = 'Merchandise_Alt_Hierarchies_v2'
	--AND br.Status_ID = 1
ORDER BY e.Name, br.Priority

-- Status = 1; Active
-- Status_ID = 2; Excluded
-- Status_ID = 3; Activation Pending
-- Status_ID = 5; Exclusion Pending
-- Status_ID = 6; Deletion Pending
