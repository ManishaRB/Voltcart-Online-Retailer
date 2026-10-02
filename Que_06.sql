/*6. The catalogue team needs to see everything under a part of the tree. Using a
recursive query, list all categories in the subtree rooted at 'Computers' at any depth, with
how deep each sits and a readable path from Computers. Required output: category_id,
category_name, depth_level, category_path.*/

-- Using a recursive CTE, list all categories under the Computers category at any depth, 
-- including their depth level and full category path.


WITH base_query AS(
	SELECT 
		category_id,
		category_name,
		parent_category_id,
		0 AS depth_level,
		CAST(category_name AS VARCHAR(MAX)) AS category_path
	FROM dim_category
	WHERE category_name = 'Computers'

UNION ALL

SELECT 
	p.category_id,
	p.category_name,
	p.parent_category_id,
	bq.depth_level + 1 AS depth_level,
	CAST(bq.category_path + ' > ' + p.category_name 
	AS VARCHAR(MAX)) AS category_path
FROM dim_category AS p
JOIN base_query AS bq
	ON p.parent_category_id = bq.category_id
)
SELECT 
	category_id,
	category_name,
	depth_level,
	category_path
FROM base_query
OPTION (MAXRECURSION 200);