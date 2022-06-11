-- Author: Olivier Vadiavaloo

-- Video Game Sales Dataset
-- Source: https://www.kaggle.com/datasets/gregorut/videogamesales

SELECT *
FROM VideoGameSales..vgsales


-- (1)
-- Find the total number of copies sold in Europe by platform. 
-- Order results in descending order of total sales in Europe.
SELECT [Platform], ROUND(SUM(EU_Sales), 2) AS [Copies sold in Europe]
FROM VideoGameSales..vgsales
GROUP BY [Platform]
ORDER BY 2 DESC


-- (2)
-- For each year, find the top-selling video game globally and the platform
-- on which it sold that number of copies.
-- Order results chronologically.
WITH max_by_year AS (
	SELECT [Year], MAX(vg2.[Global_Sales]) AS [Max_Sales]
	FROM VideoGameSales..vgsales vg2
	GROUP BY [Year]
)
SELECT vg1.[Year], 
	   vg1.[Name] AS [Top-Selling Video Game], 
	   vg1.[Platform], 
	   vg1.[Global_Sales] AS [Copies sold in millions]
FROM VideoGameSales..vgsales vg1 INNER JOIN
	 max_by_year mby ON 
	 mby.[Year] = vg1.[Year] AND
	 mby.[Max_Sales] = vg1.[Global_Sales]
ORDER BY vg1.[Year]


-- (3)
-- Find the publishers of the top 10 best-selling games of all time.
-- Order the results by number of copies sold.
-- This query is not really needed since we have a Rank field.
-- However, it is a good exercise as in most cases datasets with this
-- type of data do not contain a Rank field.
SELECT TOP(10) [Name] AS [Game],
	   [Publisher],
	   [Global_Sales] AS [Copies Sold in millions]
FROM VideoGameSales..vgsales
ORDER BY 3 DESC


-- (4)
-- Find the top 10 genres in terms of worldwide sales in the 21st century.
-- Order results by sales starting with the largest one.
SELECT TOP(10) [Genre],
	   ROUND(SUM(Global_Sales), 2) AS [Copies Sold in millions]
FROM VideoGameSales..vgsales
WHERE [Year] >= 2000
GROUP BY [Genre]
ORDER BY 2 DESC


-- (5)
-- Find the number of copies sold every recorded year for each genre.
-- The genres must be columns.
DECLARE @answer NVARCHAR(MAX), @sql NVARCHAR(MAX);
SET @answer = (
	SELECT STRING_AGG('['+t1.[Genre]+']', ',')
	FROM (
		SELECT DISTINCT CONVERT(NVARCHAR(MAX), [Genre]) AS [Genre]
		FROM VideoGameSales..vgsales
	) t1
);

SET @sql = 'SELECT *
	FROM (
		SELECT [Genre],
			   CONVERT(DECIMAL(9, 1), [Global_Sales]) AS [Global_Sales],
			   [Year]
		FROM VideoGameSales..vgsales
	) base
	PIVOT (
		SUM([Global_Sales])
		FOR Genre IN (
			' + @answer + '
		)
	) [pivot_t]
	WHERE [Year] IS NOT NULL
	ORDER BY [Year]';

EXEC(@sql);


-- (6)
-- Find the region(s) with the most sales for each year in
-- the 21st century.
-- Order the results chronologically.
WITH sum_by_region AS (
	SELECT [Year],
		   CONVERT(DECIMAL(9,1), SUM(NA_Sales)) AS [Total_NA_Sales],
		   CONVERT(DECIMAL(9,1), SUM(EU_Sales)) AS [Total_EU_Sales],
		   CONVERT(DECIMAL(9,1), SUM(JP_Sales)) AS [Total_JP_Sales],
		   CONVERT(DECIMAL(9,1), SUM(Other_Sales)) AS [Total_Other_Sales]
	FROM VideoGameSales..vgsales
	GROUP BY [Year]
	HAVING [Year] >= 2000
),
cross_apply AS (
	SELECT sbr.[Year], t.[Region], t.[Sales]
	FROM sum_by_region sbr
	CROSS APPLY (
		VALUES 
			('North America', sbr.[Total_NA_Sales]),
			('Europe', sbr.[Total_EU_Sales]),
			('Japan', sbr.[Total_JP_Sales]),
			('Other Region', sbr.[Total_Other_Sales])
	) t([Region], [Sales])
)
SELECT ca1.[Year], 
	   ca1.[Region] AS [Region with most sales], 
	   ca1.[Sales] AS [Copies Sold in millions]
FROM cross_apply ca1
WHERE ca1.[Sales] = (
	SELECT MAX(ca2.[Sales])
	FROM cross_apply ca2
	WHERE ca1.[Year] = ca2.[Year]
)
ORDER BY 1


-- (7)
-- For each platform, find the top-selling game genre
-- in the 21st century.
WITH sales_plat_gen AS (
	SELECT [Platform],
		   [Genre],
		   ROUND(SUM(Global_Sales), 2) AS [Global_Sales]
	FROM VideoGameSales..vgsales
	WHERE [Year] >= 2000
	GROUP BY [Platform], [Genre]
),
max_by_platform AS (
	SELECT spg2.[Platform], MAX(spg2.[Global_Sales]) AS [Max_Sales]
	FROM sales_plat_gen spg2
	GROUP BY spg2.[Platform]
)
SELECT spg1.[Platform],
	   spg1.[Genre] AS [Top-Selling Genre],
	   spg1.[Global_Sales] AS [Copies Sold in million]
FROM sales_plat_gen spg1 INNER JOIN
	 max_by_platform mbp ON
	 mbp.[Platform] = spg1.[Platform] AND
	 mbp.[Max_Sales] = spg1.[Global_Sales]


-- (8)
-- Find 10 the platform with the most sales worldwide for each 
-- year in the 21st century.
WITH sales_plat_yr AS (
	SELECT [Year], [Platform],
		   ROUND(SUM([Global_Sales]), 2) AS [Total_Sales]
	FROM VideoGameSales..vgsales
	WHERE [Year] >= 2000
	GROUP BY [Year], [Platform]
),
max_by_year AS (
	SELECT [Year], MAX([Total_Sales]) AS [Total_Sales]
	FROM sales_plat_yr
	GROUP BY [Year]
)
SELECT spy.[Year], spy.[Platform] AS [Top-Selling Platform],
	   spy.[Total_Sales] AS [Copies Sold in millions]
FROM sales_plat_yr spy INNER JOIN
	 max_by_year mby ON
	 mby.[Year] = spy.[Year] AND
	 mby.[Total_Sales] = spy.[Total_Sales]
ORDER BY 1

