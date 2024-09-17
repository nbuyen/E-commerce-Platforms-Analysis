
-- 0. Quantity sold out by Platform
SELECT platform, SUM(quantity) AS quantity
FROM dbo.Dataset$
GROUP BY platform

-- 1. Sales performance(*) of each Platform in May 2024 ( Revenue, Order, Item Sold, AOV (Average Order Value), ASP (Average Selling Price))
-- (*) The performance should exclude canceled, returned and failed order status.
SELECT 
    platform,
    SUM(quantity * unit_price) AS Revenue,
    COUNT(DISTINCT order_number) AS Orders,
    SUM(quantity) AS Items_Sold,
    SUM(quantity * unit_price) / COUNT(DISTINCT order_number) AS AOV,
    SUM(quantity * unit_price) / SUM(quantity) AS ASP
FROM 
    dbo.Dataset$
WHERE 
    order_created_date BETWEEN '2024-05-01' AND '2024-05-31'
    AND Order_status NOT IN ('canceled', 'returned', 'failed')
GROUP BY 
    platform

-- 2. Top 5 revenue contributed Product SKU in May 2024
SELECT TOP 5
    [Product SKU],
    SUM(quantity * unit_price) AS Revenue
FROM 
    dbo.Dataset$
WHERE 
    order_created_date BETWEEN '2024-05-01' AND '2024-05-31'
    AND Order_status NOT IN ('canceled', 'returned', 'failed')
GROUP BY 
    [Product SKU]
ORDER BY 
    Revenue DESC

-- 3. The first date that each Product SKU has been sold
SELECT 
    [Product SKU],
    CONVERT(DATE, MIN(order_created_date)) AS First_Sold_Date
FROM 
    dbo.Dataset$
GROUP BY 
    [Product SKU]
ORDER BY 
    First_Sold_Date

-- 4. Seller Promotion Ratio (Seller Promotion/ Revenue) of each Product category.
SELECT 
    category.Category,
    ROUND(SUM(data.seller_promo) / SUM(data.quantity * data.unit_price),3) AS Seller_Promotion_Ratio
FROM 
    dbo.Dataset$ data
JOIN 
    dbo.Category$ category ON data.[Product SKU] = category.[Product SKU]
GROUP BY 
    category.Category

-- 5. Which Product SKU has the highest cancellation ratio in June 2024? And what is the main reason for cancellation of that product?
WITH Cancellation AS (
    SELECT 
        [Product SKU],
        COUNT(*) AS Total_Orders,
        SUM(CASE WHEN Order_status = 'cancelled' THEN 1 ELSE 0 END) AS Cancelled_Orders
    FROM 
        dbo.Dataset$
    WHERE 
        order_created_date BETWEEN '2024-06-01' AND '2024-06-30'
    GROUP BY 
        [Product SKU]
),
Most_Cancelled_Product AS (
    SELECT TOP 1
        [Product SKU],
        CAST(Cancelled_Orders AS FLOAT) / Total_Orders AS CancellationRatio
    FROM 
        Cancellation
    WHERE 
        Total_Orders > 0
    ORDER BY 
        CancellationRatio DESC
)
SELECT 
    p.[Product SKU],
    data.cancelled_reason
FROM 
    Most_Cancelled_Product p
JOIN 
    dbo.Dataset$ data ON p.[Product SKU] = data.[Product SKU]
WHERE 
    data.order_created_date BETWEEN '2024-06-01' AND '2024-06-30'
    AND data.Order_status = 'cancelled'
GROUP BY 
    p.[Product SKU], data.cancelled_reason

-- 6. 
WITH Late_Delivery AS (
    SELECT 
        Platform,
        COUNT(*) AS Total_Orders,
        SUM(CASE WHEN DATEDIFF(day, order_created_date, delivery_date) >= 3 THEN 1 ELSE 0 END) AS Late_Delivery
    FROM 
        dbo.Dataset$
    WHERE 
        Platform IN ('Shopee', 'Lazada')
    GROUP BY 
        Platform
)
SELECT 
    Platform,
    Total_Orders,
    Late_Delivery,
    CAST(Late_Delivery AS FLOAT) / Total_Orders * 100 AS Percentage_Late_Delivery_Orders
FROM 
    Late_Delivery
