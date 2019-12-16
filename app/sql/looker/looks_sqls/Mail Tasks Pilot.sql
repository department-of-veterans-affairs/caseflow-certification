SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "tasks.created_date","tasks.status","tasks.instructions","assigned_to_organization.name","tasks.assigned_to_type","assigned_to_user.roles","tasks.type") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "tasks.count" ELSE NULL END DESC NULLS LAST, "tasks.count" DESC, z__pivot_col_rank, "tasks.created_date", "tasks.status", "tasks.instructions", "assigned_to_organization.name", "tasks.assigned_to_type", "assigned_to_user.roles", "tasks.type") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "tasks.assigned_to_id" NULLS LAST, "assigned_to_user.full_name" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	tasks.assigned_to_id  AS "tasks.assigned_to_id",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	DATE(tasks.created_at ) AS "tasks.created_date",
	CASE tasks.status
          WHEN 'assigned' THEN '1_assigned'
          WHEN 'in_progress' THEN '2_viewed'
          WHEN 'on_hold' THEN '3_on_hold'
          WHEN 'completed' THEN '3_completed'
          ELSE tasks.status
         END
         AS "tasks.status",
	tasks.instructions  AS "tasks.instructions",
	assigned_to_organization.name  AS "assigned_to_organization.name",
	tasks.assigned_to_type  AS "tasks.assigned_to_type",
	assigned_to_user.roles  AS "assigned_to_user.roles",
	tasks.type  AS "tasks.type",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE 
	(tasks.type  IN ('EvidenceOrArgumentMailTask', 'ClearAndUnmistakeableErrorMailTask', 'HearingRelatedMailTask'))
GROUP BY 1,2,3,4,5,6,7,8,9) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank

-- sql for creating the total and/or determining pivot columns
SELECT 
	tasks.assigned_to_id  AS "tasks.assigned_to_id",
	assigned_to_user.full_name  AS "assigned_to_user.full_name",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks
LEFT JOIN public.users  AS assigned_to_user ON tasks.assigned_to_type = 'User' AND tasks.assigned_to_id = assigned_to_user.id 
LEFT JOIN public.organizations  AS assigned_to_organization ON tasks.assigned_to_type IN ('Organization', 'Vso') AND tasks.assigned_to_id = assigned_to_organization.id 

WHERE 
	(tasks.type  IN ('EvidenceOrArgumentMailTask', 'ClearAndUnmistakeableErrorMailTask', 'HearingRelatedMailTask'))
GROUP BY 1,2
ORDER BY 1 ,2 
LIMIT 50