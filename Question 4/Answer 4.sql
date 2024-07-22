Question 4

Given:

ORDER: table containing client order information as below (one client can have any number of order)
ORDER_DELIVERY: table containing order delivery information

PostgreSQL

--Query 1: Count number of unique client order and number of orders by order month.
SELECT 
    TO_CHAR(Date_Order, 'YYYY-MM') AS order_month,
    COUNT(DISTINCT Client_ID) AS unique_clients,
    COUNT(*) AS total_orders
FROM "ORDER"
GROUP BY TO_CHAR(Date_Order, 'YYYY-MM')
ORDER BY order_month;

--Query 2: Get list of client who have more than 10 orders in this year.

SELECT
    Client_ID,
    COUNT(*) AS total_orders
FROM "ORDER"
WHERE EXTRACT(YEAR FROM Date_Order) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY Client_ID
HAVING COUNT(*) > 10;

--Query 3: From the above list of client: get information of first and second last order of client (Order date, good type, and amount)


WITH ClientsWithManyOrders AS (
    SELECT Client_ID
    FROM "ORDER"
    WHERE EXTRACT(YEAR FROM Date_Order) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY Client_ID
    HAVING COUNT(*) > 10
),
OrderInfo AS (
    SELECT 
        o.Client_ID,
        FIRST_VALUE(o.Date_Order) OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order) AS first_order_date,
        FIRST_VALUE(o.Good_Type) OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order) AS first_order_type,
        FIRST_VALUE(o.Good_Amount) OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order) AS first_order_amount,
        NTH_VALUE(o.Date_Order, 2) OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order DESC) AS second_last_order_date,
        NTH_VALUE(o.Good_Type, 2) OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order DESC) AS second_last_order_type,
        NTH_VALUE(o.Good_Amount, 2) OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order DESC) AS second_last_order_amount,
        ROW_NUMBER() OVER (PARTITION BY o.Client_ID ORDER BY o.Date_Order) AS rn
    FROM "ORDER" o
    JOIN ClientsWithManyOrders c ON o.Client_ID = c.Client_ID
)

SELECT 
    Client_ID,
    first_order_date,
    first_order_type,
    first_order_amount,
    second_last_order_date,
    second_last_order_type,
    second_last_order_amount
FROM OrderInfo
WHERE rn = 1;

--Query 4: Calculate total good amount and Count number of Order which were delivered in Sep.2019

SELECT 
    SUM(o.Good_Amount) AS total_good_amount,
    COUNT(DISTINCT od.Order_ID) AS delivered_orders
FROM "ORDER" o
JOIN ORDER_DELIVERY od ON o.Order_ID = od.Order_ID
WHERE 
    EXTRACT(YEAR FROM od.Date_Delivery) = 2019 
    AND EXTRACT(MONTH FROM od.Date_Delivery) = 9;

--Query 5: Assuming your 2 tables contain a huge amount of data and each join will take about 30 hours, while you need to do daily report, what is your solution?

1.Phân vùng bảng (Table Partitioning):
    + Chia bảng lớn thành các phân vùng nhỏ hơn dựa trên một tiêu chí, thường là ngày tháng.
    + Cải thiện hiệu suất truy vấn bằng cách chỉ quét các phân vùng cần thiết.

CREATE TABLE orders_partitioned (
    Order_ID INT,
    Date_Order DATE,
    Good_Type VARCHAR(50),
    Good_Amount DECIMAL(10,2),
    Client_ID INT
) PARTITION BY RANGE (Date_Order);

CREATE TABLE orders_y2019 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

CREATE TABLE orders_y2020 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

2. Materialized Views:

CREATE MATERIALIZED VIEW monthly_order_summary AS
SELECT 
    TO_CHAR(Date_Order, 'YYYY-MM') AS order_month,
    COUNT(DISTINCT Client_ID) AS unique_clients,
    COUNT(*) AS total_orders
FROM 
    "ORDER"
GROUP BY 
    TO_CHAR(Date_Order, 'YYYY-MM');

-- Refresh the materialized view
REFRESH MATERIALIZED VIEW monthly_order_summary;

3. Indexes

CREATE INDEX idx_order_date ON "ORDER" (Date_Order);
CREATE INDEX idx_client_id ON "ORDER" (Client_ID);

Những phương pháp này, kết hợp với việc tối ưu hóa phần cứng và cấu hình PostgreSQL, có thể giúp xử lý dữ liệu lớn hiệu quả hơn và đáp ứng yêu cầu báo cáo hàng ngày.
