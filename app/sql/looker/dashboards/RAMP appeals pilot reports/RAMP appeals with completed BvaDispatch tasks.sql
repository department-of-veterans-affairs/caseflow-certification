SELECT 
	appeals.veteran_file_number  AS "appeals.veteran_file_number",
	assigned_to_user.css_id  AS "assigned_to_user.css_id",
	appeals.docket_type  AS "appeals.docket_type",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	request_issues.disposition  AS "request_issues.disposition",
	remand_reasons.code  AS "remand_reasons.code",
	COUNT(DISTINCT request_issues.id ) AS "request_issues.appeal_request_issue_count"
FROM public.tasks  AS tasks
LEFT JOIN public.appeals  AS appeals ON tasks.appeal_id = appeals.id AND tasks.appeal_type = 'Appeal'
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.request_issues  AS request_issues ON tasks.appeal_id = request_issues.decision_review_id
LEFT JOIN public.remand_reasons  AS remand_reasons ON request_issues.id = remand_reasons.request_issue_id

WHERE (((CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END) = '3_completed')) AND (tasks.type = 'BvaDispatchTask') AND (assigned_to_user.css_id <> 'VSCBPIET' OR assigned_to_user.css_id IS NULL)
GROUP BY 1,2,3,4,5,6
ORDER BY 4 DESC
LIMIT 500