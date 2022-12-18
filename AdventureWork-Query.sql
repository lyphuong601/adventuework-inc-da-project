# Fast, simple data exploration
# Total revenue, total profit for each product each year
WITH sales AS (
	(SELECT * FROM AdventureWork.sales_2017)
	UNION ALL
	(SELECT * FROM AdventureWork.sales_2016)
	UNION ALL
	(SELECT * FROM AdventureWork.sales_2015)
)

SELECT p.ProductName,
	SUM(OrderQuantity) AS TotalQuantity,
	ROUND(p.ProductPrice * sale.OrderQuantity, 2) AS TotalRevenue,
	ROUND(sale.OrderQuantity *(p.ProductPrice - p.ProductCost), 2) AS TotalProfit
FROM (
		SELECT ProductKey, SUM(OrderQuantity) AS OrderQuantity
		FROM sales
		GROUP BY ProductKey
	) sale
LEFT JOIN AdventureWork.products p ON p.ProductKey = sale.ProductKey
GROUP BY ProductName,
	TotalRevenue,
	TotalProfit
ORDER BY TotalProfit DESC;

# Find the customer with the highest total quantity order in 2016
SELECT sale.CustomerKey, c.FirstName, c.LastName, SUM(OrderQuantity) AS TotalQuantity
FROM AdventureWork.sales_2016 sale
LEFT JOIN AdventureWork.customers c ON c.CustomerKey = sale.ProductKey
GROUP BY CustomerKey, FirstName, LastName
HAVING SUM(OrderQuantity) = (
		SELECT MAX(OrderQuantity)
		FROM (SELECT CustomerKey, SUM(OrderQuantity) AS OrderQuantity
				FROM AdventureWork.sales_2016
				GROUP BY CustomerKey
			) b
	);

# Create View sales summary: Top 3 product sales by sales territory in 2017
DROP VIEW IF EXISTS AdventureWork.sales_summary;
CREATE VIEW AdventureWork.sales_summary AS (
	SELECT st.Country, st.Region, p.ProductName, sale_rank.OrderQuantity
	FROM (SELECT *, RANK () OVER (PARTITION BY TerritoryKey ORDER BY OrderQuantity DESC) AS rnk
			FROM (SELECT TerritoryKey, ProductKey, SUM(OrderQuantity) AS OrderQuantity
					FROM AdventureWork.sales_2017
					GROUP BY TerritoryKey, ProductKey
				) sale
		) sale_rank
	LEFT JOIN AdventureWork.products p ON p.ProductKey = sale_rank.ProductKey
	LEFT JOIN AdventureWork.sale_territories st ON st.SalesTerritoryKey = sale_rank.TerritoryKey
	WHERE rnk <= 3
);

# return rate of each product line in each territory
WITH sales AS (
	(SELECT * FROM AdventureWork.sales_2017)
	UNION ALL
	(SELECT * FROM AdventureWork.sales_2016)
	UNION ALL
	(SELECT * FROM AdventureWork.sales_2015)
),
T2 AS (
	SELECT sreturn.TerritoryKey, sreturn.ProductKey, sreturn.ReturnQuantity, sales.OrderQuantity
	FROM (SELECT TerritoryKey, ProductKey, SUM(ReturnQuantity) AS ReturnQuantity
			FROM AdventureWork.sale_returns
			GROUP BY 1, 2
		) sreturn
		LEFT JOIN (SELECT TerritoryKey, ProductKey, SUM(OrderQuantity) AS OrderQuantity
					FROM sales
					GROUP BY 1, 2
		) sales 
		ON sales.ProductKey = sreturn.ProductKey AND sales.TerritoryKey = sreturn.TerritoryKey
)
SELECT p.ProductName, st.Region, st.Country, ROUND((ReturnQuantity * 100) / OrderQuantity, 2) AS ReturnRate
FROM T2
LEFT JOIN AdventureWork.products p ON T2.ProductKey = p.ProductKey
LEFT JOIN AdventureWork.sale_territories st ON st.SalesTerritoryKey = T2.TerritoryKey
ORDER BY st.Region
