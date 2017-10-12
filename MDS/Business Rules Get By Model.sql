USE MDS
GO

SELECT 
	e.Name,
	br.Priority,
	br.Name,
	br.RuleConditionText,
	br.RuleActionText
FROM mdm.tblBRBusinessRule br
JOIN mdm.tblEntity e ON br.Foreign_ID = e.ID
JOIN mdm.tblModel m ON e.Model_ID = m.ID
WHERE m.Name = 'Merchandise_Alt_Hierarchies'
	AND br.Status_ID = 1
ORDER BY e.Name, br.Priority
