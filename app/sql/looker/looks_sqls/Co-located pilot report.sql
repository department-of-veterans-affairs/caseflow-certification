SELECT * FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY z___min_rank) as z___pivot_row_rank, RANK() OVER (PARTITION BY z__pivot_col_rank ORDER BY z___min_rank) as z__pivot_col_ordering FROM (
SELECT *, MIN(z___rank) OVER (PARTITION BY "tasks.created_date","tasks.action") as z___min_rank FROM (
SELECT *, RANK() OVER (ORDER BY CASE WHEN z__pivot_col_rank=1 THEN 1 ELSE 2 END, CASE WHEN z__pivot_col_rank=1 THEN "tasks.count" ELSE NULL END DESC NULLS LAST, "tasks.count" DESC, z__pivot_col_rank, "tasks.created_date", "tasks.action") AS z___rank FROM (
SELECT *, DENSE_RANK() OVER (ORDER BY "tasks.assigned_to_id" NULLS LAST) AS z__pivot_col_rank FROM (
SELECT 
	tasks.assigned_to_id  AS "tasks.assigned_to_id",
	DATE(tasks.created_at ) AS "tasks.created_date",
	tasks.action  AS "tasks.action",
	COUNT(DISTINCT tasks.id ) AS "tasks.count"
FROM public.tasks  AS tasks

WHERE 
	(tasks.type = 'ColocatedTask')
GROUP BY 1,2,3) ww
) bb WHERE z__pivot_col_rank <= 16384
) aa
) xx
) zz
 WHERE z___pivot_row_rank <= 500 OR z__pivot_col_ordering = 1 ORDER BY z___pivot_row_rank