--TASK 01: TOTAL NUMBER OF ORDERS
SELECT COUNT(*)
FROM orders

--TASK 02: ORDERS BY STATUS
SELECT o.status,
	   COUNT(*) AS order_count
FROM orders o
GROUP BY o.status 

--TASK 03: TOTAL REVENUE
SELECT SUM(o.total_amount) AS total_revenue
FROM orders o

--TASK 04: AVERAGE ORDER VALUE
SELECT AVG(o.total_amount) AS avg_total_amount
FROM orders o

--TASK 05: ORDERS BY YEAR
SELECT EXTRACT(YEAR FROM o.order_date) AS year,
	   COUNT(*) AS orders_count
FROM orders o
GROUP BY year
ORDER BY year ASC

--TASK 06: MONTHLY REVENUE ANALYSIS
SELECT EXTRACT(YEAR FROM o.order_date) AS year,
	   EXTRACT(MONTH FROM o.order_date) AS month,
	   SUM(o.total_amount) AS total_revenue,
	   COUNT(*) AS orders_count
FROM orders o
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY year, month
ORDER BY month ASC

--TASK 07: TOP 10 CUSTOMERS BY REVENUE
SELECT cu.customer_id,
	   cu.customer_name,
	   COUNT(*) AS orders_count,
	   SUM(o.total_amount) AS total_spent,
	   AVG(o.total_amount) AS avg_order_value
FROM customers cu
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed' 
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY cu.customer_id,
		 cu.customer_name 
ORDER BY total_spent DESC
LIMIT 10;

--TASK 08: REVENUE BY REGION 
SELECT re.region_name,
	   COUNT(DISTINCT cu.customer_id) AS active_customers,
	   COUNT(*) AS orders_count,
	   SUM(o.total_amount) AS total_revenue,
	   AVG(o.total_amount) AS avg_order_value
FROM regions re
JOIN customers cu
	ON cu.region_id = re.region_id 
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY re.region_name,
		 re.region_id
ORDER BY total_revenue DESC;
	   
--TASK 09: CUSTOMERS WITH REPEAT PURCHASES
SELECT cu.customer_id,
	   cu.customer_name,
	   COUNT(*) AS orders_count,
	   SUM(o.total_amount) AS total_spent,
	   AVG(o.total_amount) AS avg_order_value
FROM customers cu
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY cu.customer_id,
		 cu.customer_name 
HAVING COUNT(*) >= 2
ORDER BY orders_count DESC,
		 total_spent DESC;

--TASK 10: CUSTOMER REVENUE SEGMENTATION
SELECT cu.customer_id,
	   cu.customer_name,
	   COUNT(*) AS orders_count,
	   SUM(o.total_amount) AS total_spent,
	   CASE
	   	WHEN SUM(o.total_amount) < 100000 THEN 'Low'
	   	WHEN SUM(o.total_amount) < 500000 THEN 'Medium'
	   	ELSE 'High'
	   END AS customer_segment
FROM customers cu
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY cu.customer_id,
		 cu.customer_name 
ORDER BY total_spent DESC;
	  
--TASK 11: PRODUCT SALES PERFORMANCE
SELECT p.product_id,
	   p.product_name,
	   SUM(ot.quantity) AS units_sold,
	   COUNT(DISTINCT o.order_id) AS orders_count,
	   SUM(ot.quantity * ot.unit_price) AS gross_sales
FROM products p
JOIN order_items ot
	ON p.product_id = ot.product_id
JOIN orders o
	ON ot.order_id = o.order_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2024-01-01'
		AND o.order_date < DATE '2025-01-01'
GROUP BY p.product_id,
		 p.product_name 
ORDER BY units_sold DESC,
		 gross_sales DESC
LIMIT 15;

--TASK 12: ORDER CANCELLATION ANALYSIS
SELECT month,
	   total_orders,
	   cancelled_orders,
	   ROUND(cancelled_orders * 100.0 / total_orders , 2) AS cancellation_rate
FROM(
	SELECT EXTRACT(MONTH FROM o.order_date) AS month,
	   COUNT(*) AS total_orders,
	   COUNT(CASE
	   	WHEN o.status = 'cancelled' THEN 1
	   END
	   ) AS cancelled_orders
FROM orders o
WHERE o.order_date >= DATE '2024-01-01'
	AND o.order_date < DATE '2025-01-01'
GROUP BY month
) AS orders_stats  
ORDER BY month ASC;

--TASK 13: DELIVERY DELAY ANALYSIS
SELECT
    region_name,
    total_deliveries,
    delayed_deliveries,
    ROUND(
        delayed_deliveries * 100.0 / total_deliveries,
        2
    ) AS delay_rate,
    avg_delay_days
FROM (
    SELECT
        re.region_name,
        COUNT(*) AS total_deliveries,
        COUNT(
            CASE
                WHEN d.actual_delivery_date > d.expected_delivery_date
                THEN 1
            END
        ) AS delayed_deliveries,
        ROUND(
            AVG(
                CASE
                    WHEN d.actual_delivery_date > d.expected_delivery_date
                    THEN EXTRACT(
                        EPOCH FROM (
                            d.actual_delivery_date - d.expected_delivery_date
                        )
                    ) / 86400.0
                END
            ),
            2
        ) AS avg_delay_days
    FROM regions re
    JOIN customers cu
        ON re.region_id = cu.region_id
    JOIN orders o
        ON cu.customer_id = o.customer_id
    JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE o.order_date >= DATE '2025-01-01'
      AND o.order_date < DATE '2026-01-01'
      AND d.delivery_status = 'delivered'
      AND d.actual_delivery_date IS NOT NULL
    GROUP BY
        re.region_name,
        re.region_id
) AS regions_deliveries
ORDER BY delay_rate DESC;	

--TASK 14: PRODUCTS WITHOUT STOCK 
SELECT p.product_id,
	   p.product_name,
	   c.category_name,
	   p.price
FROM products p
JOIN categories c
	ON p.category_id = c.category_id 
LEFT JOIN inventory i
	ON p.product_id = i.product_id 
		AND i.stock_quantity > 0
WHERE i.product_id IS NULL
ORDER BY c.category_name,
		 p.price DESC;

--TASK 15: CUSTOMERS WITHOUT SUCCESSFUL PAYMENTS
SELECT cu.customer_id,
	   cu.customer_name,
	   cu.registration_date,
	   re.region_name
FROM customers cu
JOIN regions re
	ON cu.region_id = re.region_id 
WHERE cu.registration_date >= DATE '2024-01-01'
	AND cu.registration_date < DATE '2025-01-01'
		AND NOT EXISTS(
			SELECT 1
			FROM payments pa
			JOIN orders o
				ON pa.order_id = o.order_id
			WHERE pa.status = 'completed'
				AND o.customer_id = cu.customer_id 
)
ORDER BY cu.registration_date ASC;

--TASK 16: SUPPLIERS WITHOUT PRODUCTS SALES
SELECT s.supplier_id,
	   s.company_name,
	   COUNT(DISTINCT(sp.product_id)) AS products_count
FROM suppliers s
JOIN supplier_products sp
	ON s.supplier_id = sp.supplier_id 
WHERE NOT EXISTS(
	SELECT 1
	FROM orders o
	JOIN order_items ot
		ON o.order_id = ot.order_id 
	JOIN supplier_products sp2
		ON ot.product_id = sp2.product_id
	WHERE o.status = 'completed'
		AND o.order_date >= DATE '2024-01-01'
			AND o.order_date < DATE '2025-01-01'
				AND sp2.supplier_id = sp.supplier_id
)
GROUP BY s.supplier_id,
		 s.company_name 
ORDER BY products_count DESC;

--TASK 17: CUSTOMERS ACTIVE IN BOTH YEARS
SELECT cu.customer_id,
	   cu.customer_name,
	   re.region_name
FROM customers cu
JOIN regions re
	ON cu.region_id = re.region_id 
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2024-01-01'
		AND o.order_date < DATE '2025-01-01'

INTERSECT

SELECT cu.customer_id,
	   cu.customer_name,
	   re.region_name
FROM customers cu
JOIN regions re
	ON cu.region_id = re.region_id 
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'

ORDER BY customer_id ASC;

--TASK 18: PAYMENT FAILURE ANALYSIS
SELECT payment_method,
	   total_payments,
	   failed_payments,
	   ROUND(failed_payments * 100.0 / total_payments ,2) AS failure_rate,
	   COALESCE(total_failed_amount, 0) AS total_failed_amount
FROM(
SELECT pa.payment_method,
	   COUNT(pa.payment_id) AS total_payments,
	   COUNT(CASE
	   	WHEN pa.status = 'failed' THEN 1
	   END
	   ) AS failed_payments,
	   SUM(CASE
	   	WHEN pa.status = 'failed' THEN pa.amount
	   	ELSE 0
	   END
	   ) AS total_failed_amount
FROM payments pa
WHERE pa.payment_date >= DATE '2024-01-01'
	AND pa.payment_date < DATE '2025-01-01'
GROUP BY pa.payment_method
)
ORDER BY failure_rate DESC;

--TASK 19: PRODUCTS NEVER RETURNED
WITH sales_2025 AS(
SELECT p.product_id,
	   p.product_name,
	   c.category_name, 
	   SUM(ot.quantity) AS  units_sold
FROM products p
JOIN categories c
	ON p.category_id = c.category_id 
JOIN order_items ot
	ON p.product_id = ot.product_id 
JOIN orders o
	ON ot.order_id = o.order_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY p.product_id,
	     p.product_name,
	     c.category_name
),
completed_returns AS(
	SELECT  DISTINCT ot.product_id
	FROM returns re
	JOIN order_items ot
		ON re.order_item_id = ot.order_item_id
	WHERE re.return_status = 'completed'
)
SELECT s2.product_id,
	   s2.product_name,
	   s2.category_name,
	   s2.units_sold
FROM sales_2025 s2
WHERE NOT EXISTS(
	SELECT 1
	FROM completed_returns cr
	WHERE cr.product_id = s2.product_id 
)
ORDER BY s2.units_sold DESC
LIMIT 20;

--TASK 20: DISCOUNT USAGE ANALYSIS
SELECT d.discount_code,
	   d.discount_percent,
	   COALESCE(COUNT(DISTINCT od.order_id), 0) AS orders_count,
	   COALESCE(SUM(od.discount_amount), 0) AS total_discount_amount
FROM discounts d 
LEFT JOIN order_discounts od 
	ON d.discount_id = od.discount_id 
GROUP BY d.discount_code,
	     d.discount_percent
ORDER BY total_discount_amount DESC;

--TASK 21: CUSTOMER SPENDING RANK BY REGION 
WITH customers_orders AS(
SELECT re.region_id,
	   re.region_name,
	   cu.customer_id,
	   cu.customer_name,
	   COUNT(o.order_id) AS completed_orders,
	   SUM(o.total_amount) AS total_spent
FROM customers cu
JOIN regions re
	ON cu.region_id = re.region_id 
JOIN orders o
	ON cu.customer_id = o.customer_id 
WHERE o.status = 'completed'
	AND o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
GROUP BY re.region_id,
		 re.region_name,
	     cu.customer_id,
	     cu.customer_name
),
regions_rank AS(
	SELECT co.region_id,
		   co.region_name,
		   co.customer_id,
		   co.customer_name,
		   co.completed_orders,
		   co.total_spent,
		   RANK() OVER(
		   		PARTITION BY co.region_id
		   		ORDER BY co.total_spent DESC
		   		) AS region_rank
	FROM customers_orders co
	WHERE co.completed_orders >= 3
)
SELECT rr.region_name,
	   rr.customer_id,
	   rr.customer_name,
	   rr.completed_orders,
	   rr.total_spent,
	   rr.region_rank
FROM regions_rank rr
WHERE rr.region_rank < 4
ORDER BY rr.region_name,
		 rr.region_rank,
		 rr.customer_id;

--TASK 22: REFUND ANALYSIS BY REGION AND PAYMENT METHOD
SELECT EXTRACT(MONTH FROM pa.payment_date) AS month,
	   re.region_name,
	   pa.payment_method,
	   COUNT(pa.payment_id) AS refund_payments,
	   COUNT(DISTINCT o.order_id) AS refund_orders,
	   SUM(pa.amount) AS refund_sum,
	   AVG(pa.amount) AS avg_amount
FROM payments pa
JOIN orders o
	ON pa.order_id = o.order_id
JOIN customers cu
	ON o.customer_id = cu.customer_id
JOIN regions re
	ON cu.region_id = re.region_id
WHERE pa.status = 'refunded'
	AND pa.payment_date >= DATE '2025-01-01'
		AND pa.payment_date < DATE '2025-07-01'
			AND o.status = 'refunded'
GROUP BY EXTRACT(MONTH FROM pa.payment_date),
		 region_name,
		 payment_method
ORDER BY month,
		 region_name,
		 payment_method;

--TASK 23 REGIONAL SALES PERFOMANCE COMPARSION 
WITH total_spent_2024 AS(
	SELECT re.region_id,
		   re.region_name,
		   EXTRACT(MONTH FROM o.order_date) AS month_2024,
		   SUM(o.total_amount) AS total_spent_2024
	FROM regions re
	JOIN customers cu
		ON re.region_id = cu.region_id
	JOIN orders o
		ON cu.customer_id = o.customer_id 
	WHERE o.status IN('completed', 'refunded')
		AND o.order_date >= DATE '2024-01-01'
			AND o.order_date < DATE '2025-01-01'
	GROUP BY re.region_id,
		     re.region_name,
		     EXTRACT(MONTH FROM o.order_date)
),
total_spent_2025 AS(
	SELECT cu.region_id,
		   EXTRACT(MONTH FROM o.order_date) AS month_2025,
		   SUM(o.total_amount) AS total_spent_2025
	FROM customers cu
	JOIN orders o
		ON cu.customer_id = o.customer_id
	WHERE o.status IN('completed', 'refunded')
		AND o.order_date >= DATE '2025-01-01'
			AND o.order_date < DATE '2026-01-01'
	GROUP BY cu.region_id,
		     EXTRACT(MONTH FROM o.order_date)
)
SELECT ts24.region_name,
	   ts24.month_2024,
	   ts24.total_spent_2024,
	   ts25.month_2025,
	   ts25.total_spent_2025,
	   ts25.total_spent_2025 - ts24.total_spent_2024 AS difference,
	   ROUND( (ts25.total_spent_2025 - ts24.total_spent_2024) * 100.0 / NULLIF(ts24.total_spent_2024, 0), 2) AS percent_change	
FROM total_spent_2024 ts24
FULL JOIN  total_spent_2025 ts25
	ON ts24.region_id = ts25.region_id
	AND ts24.month_2024 = ts25.month_2025
ORDER BY ts25.region_id,
		 month_2024,
		 month_2025;

--TASK 24: SUPPLIER PRODUCT PORTFOLIO ANALYSIS
SELECT supplier_id,
	   company_name,
	   total_products,
	   sold_products,
	   total_products - sold_products AS unsold_products,
	   ROUND(
	   		sold_products * 100.0 / total_products,2) AS sold_products_share
FROM(
SELECT su.supplier_id,
	   su.company_name,
	   COUNT(DISTINCT sp.product_id) total_products,
	   COUNT(DISTINCT CASE
	   	WHEN o.status = 'completed'
	   		AND o.order_date >= DATE '2025-01-01'
	   			AND o.order_date < DATE '2026-01-01'
	   	THEN sp.product_id
	   END
	   ) AS sold_products
FROM suppliers su
LEFT JOIN supplier_products sp
	ON su.supplier_id = sp.supplier_id 
LEFT JOIN products p
	ON sp.product_id = p.product_id 
LEFT JOIN order_items ot
	ON p.product_id = ot.product_id 
LEFT JOIN orders o
	ON ot.order_id = o.order_id 
GROUP BY su.supplier_id,
	     su.company_name
) AS supplier_stats
WHERE total_products - sold_products >= 3
	AND total_products >= 10
ORDER BY unsold_products DESC,
		 company_name;

--TASK 25: WAREHOUSE_STOCK_ANALYSIS
SELECT w.warehouse_name,
	   p.product_name,
	   i.stock_quantity,
	   AVG(i.stock_quantity) OVER(
	   		PARTITION BY w.warehouse_id
	   		) AS avg_stock,
	   LAG(i.stock_quantity) OVER(
	   		PARTITION BY w.warehouse_id
	   		ORDER BY stock_quantity DESC
	   		) previous_stock,
	   stock_quantity - LAG(i.stock_quantity) OVER(
	   		PARTITION BY w.warehouse_id
	   		ORDER BY stock_quantity DESC
	   		) stock_difference,
	   SUM(i.stock_quantity) OVER(
	   		PARTITION BY w.warehouse_id
	   		ORDER BY i.stock_quantity DESC
	   		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	   		) AS cumulative_stock
FROM warehouses w 
JOIN inventory i 
	ON w.warehouse_id = i.warehouse_id 
JOIN products p
	ON i.product_id = p.product_id 
WHERE i.stock_quantity > 0


--TASK 26: CATEGORY CONTRIBUTION TO REVENUE
WITH category_sells AS(
SELECT c.category_id,
	   c.category_name,
	   SUM(ot.quantity) AS units_sold,
	   SUM(ot.quantity * ot.unit_price) AS gross_sales
FROM categories c
LEFT JOIN products p
	ON c.category_id = p.category_id 
LEFT JOIN order_items ot
	ON p.product_id = ot.product_id 
LEFT JOIN orders o
	ON ot.order_id = o.order_id 
	AND o.status = 'completed'
		AND o.order_date >= DATE '2025-01-01'
			AND o.order_date < DATE '2026-01-01'
GROUP BY c.category_id,
		 c.category_name
),
category_percent AS(
	SELECT cs.category_id,
		   cs.category_name,
		   cs.units_sold,
		   cs.gross_sales,
		   SUM(cs.gross_sales) OVER() AS total_sales,
		   AVG(cs.gross_sales) OVER() AS avg_category_sales
		   
	FROM category_sells cs
)
SELECT cp.category_name,
	   cp.units_sold,
	   cp.gross_sales,
	   cp.gross_sales / cp.total_sales * 100.0 AS sales_share,
	   cp.gross_sales - cp.avg_category_sales AS difference_from_avg
FROM category_percent cp
ORDER BY cp.gross_sales DESC

--TASK 27: ORDER ITEMS WITH UNUSUAL PRICES
SELECT o.order_id,
	   cu.customer_id,
	   cu.customer_name,
	   o.status,
	   COUNT(pa.payment_id) AS payments_count,
	   COUNT(CASE
	   	WHEN pa.status = 'failed'
	   	THEN 1
	   END
	   ) AS failed_payments,
	   SUM(pa.amount) AS total_payment_amount,
	   AVG(pa.amount) AS avg_payment_amount,
	   COUNT(DISTINCT pa.payment_method) AS payment_method_count
FROM customers cu
JOIN orders o
	ON cu.customer_id = o.customer_id 
JOIN payments pa
	ON o.order_id = pa.order_id 
WHERE o.status IN('completed','pending','refunded')
	AND EXISTS(
		SELECT 1
		FROM payments pa2
		WHERE pa2.status = 'failed'
			AND pa2.order_id = o.order_id 
	) AND EXISTS(
		SELECT 1
		FROM payments pa3
		WHERE pa3.status = 'completed'
			AND pa3.order_id = o.order_id 
	)
GROUP BY o.order_id,
	     cu.customer_id,
	     cu.customer_name,
	     o.status
HAVING COUNT(pa.payment_id) >= 3
	AND SUM(pa.amount) > o.total_amount
		AND AVG(pa.amount) >= 1000
ORDER BY payments_count DESC,
		 total_payment_amount DESC;

--TASK 28: PRODUCT DEMAND & INVENTORY ANALYSIS
WITH units_solds AS(
	SELECT p.product_id,
		   p.product_name,
		   c.category_name,
		   SUM(CASE 
		   	WHEN o.order_date >= DATE '2025-01-01'
		   		AND o.order_date < DATE '2025-04-01'
		   	THEN ot.quantity
		   	ELSE 0
		   END
		   ) AS q1_units_sold,
		   SUM(CASE 
		   	WHEN o.order_date >= DATE '2025-04-01'
		   		AND o.order_date < DATE '2025-07-01'
		   		THEN ot.quantity
		   		ELSE 0
		   END
		   ) AS q2_units_sold
	FROM products p
	JOIN order_items ot
		ON p.product_id = ot.product_id 
	JOIN orders o
		ON ot.order_id = o.order_id 
	JOIN categories c
		ON p.category_id = c.category_id 
	WHERE o.status = 'completed'
	GROUP BY p.product_id,
			 p.product_name,
			 c.category_name
),
second_with AS(
	SELECT i.product_id,
		   SUM(i.stock_quantity) AS total_stock
	FROM inventory i
	GROUP BY i.product_id 
),
third_with AS(
	SELECT sp.product_id,
	       COUNT(DISTINCT sp.supplier_id) AS suppliers_count
	FROM supplier_products sp 
	GROUP BY sp.product_id
)
SELECT us.product_id,
	   us.product_name,
	   us.category_name,
	   us.q1_units_sold,
	   us.q2_units_sold,
	   (us.q2_units_sold - us.q1_units_sold) * 100.0 / NULLIF(us.q1_units_sold, 0)  AS sales_growth_percent,
	   sw.total_stock,
	   tw.suppliers_count,
	   us.q2_units_sold - sw.total_stock AS stock_defecit
FROM units_solds us
JOIN second_with sw
	ON us.product_id = sw.product_id
JOIN third_with tw
	ON sw.product_id = tw.product_id
WHERE tw.suppliers_count >= 2
	AND sw.total_stock < us.q2_units_sold
		AND us.q1_units_sold > 0
			AND us.q2_units_sold > 0
				AND ((us.q2_units_sold - us.q1_units_sold) / NULLIF(us.q1_units_sold, 0) * 100.0) >= 20
ORDER BY sales_growth_percent DESC,
		 stock_defecit DESC;

--TASK 29: SUPPLIER PRODUCT CATALOG
WITH suppliers_product AS(
SELECT p.product_id,
	   p.product_name,
	   c.category_id,
	   c.category_name,
	   COUNT(DISTINCT s.supplier_id) AS suppliers_count,
	   string_agg(DISTINCT s.company_name, ', ') AS supplier_names
FROM products p
JOIN categories c
	ON p.category_id = c.category_id 
JOIN supplier_products sp 
	ON p.product_id = sp.product_id 
JOIN suppliers s 
	ON sp.supplier_id = s.supplier_id 
GROUP BY p.product_id,
	   p.product_name,
	   c.category_id,
	   c.category_name
),
second_with AS(
	SELECT ot.product_id,
		   COUNT(DISTINCT o.order_id) AS orders_count,
		   MAX(o.order_date) AS last_order_date
	FROM order_items ot
	LEFT JOIN orders o
		ON ot.order_id = o.order_id
		AND o.order_date >= DATE '2025-01-01'
			AND o.order_date < DATE '2026-01-01'
				AND o.status IN('completed', 'pending')
	GROUP BY ot.product_id
)
SELECT sp.product_id,
	   sp.product_name,
	   sp.category_name,
	   sp.suppliers_count,
	   sp.supplier_names,
	   COALESCE(sw.orders_count, 0) AS orders_count,
	   sw.last_order_date
FROM suppliers_product sp 
LEFT JOIN second_with sw
	ON sp.product_id = sw.product_id 
WHERE sp.suppliers_count >= 2
ORDER BY suppliers_count DESC,
		 product_name ASC;

--TASK 30: CUSTOMER PAYMENT HISTORY 
SELECT cu.customer_id,
	   cu.customer_name,
	   COUNT(DISTINCT o.order_id) AS orders_with_payments,
	   COUNT(pa.payment_id) AS payments_counts,
	   COUNT(CASE
	   	WHEN pa.status = 'completed'
	   	THEN 1
	   END
	   ) AS successful_payments,
	   COUNT(CASE
	   	WHEN pa.status = 'failed'
	   	THEN 1
	   END
	   ) AS failed_payments,
	   SUM(CASE
	   	WHEN pa.status = 'completed'
	   	THEN pa.amount
	   	ELSE 0
	   END
	   ) AS successful_payment_amount,
	   MAX(pa.payment_date) AS last_payment_date,
	   COUNT(DISTINCT pa.payment_method) AS payment_methods_count
FROM customers cu
JOIN orders o
	ON cu.customer_id = o.customer_id 
JOIN payments pa
	ON o.order_id = pa.order_id
WHERE pa.payment_date >= DATE '2025-01-01'
	AND pa.payment_date < DATE '2025-07-01'
GROUP BY cu.customer_id,
	     cu.customer_name
HAVING COUNT(CASE
	   	WHEN pa.status = 'completed'
	   	THEN 1
	   END
	   ) > 0
	   AND 
	   COUNT(CASE
	   	WHEN pa.status = 'failed'
	   	THEN 1
	   END
	   ) > 0
	   AND COUNT(pa.payment_id) >= 4
ORDER BY failed_payments DESC,
		 last_payment_date DESC;

--TASK 31: DELIVERY STATUS CONSISTENCY ANALYSIS
SELECT o.order_id,
	   cu.customer_id,
	   cu.customer_name,
	   re.region_name,
	   o.status,
	   de.delivery_status,
	   de.shipped_at,
	   de.actual_delivery_date,
	   CASE
    WHEN de.actual_delivery_date IS NOT NULL
         AND de.shipped_at IS NOT NULL
         AND de.actual_delivery_date < de.shipped_at
    THEN 'Invalid Date Sequence'
    WHEN de.delivery_status = 'delivered'
         AND de.actual_delivery_date IS NULL
    THEN 'Missing Delivery Date'
    WHEN de.delivery_status = 'failed'
         AND de.actual_delivery_date IS NOT NULL
    THEN 'Unexpected Delivery Date'
    WHEN de.delivery_status = 'pending'
         AND de.shipped_at IS NOT NULL
    THEN 'Unexpected Shipment Date'
		END AS issue_type 			
FROM orders o
JOIN customers cu
	ON o.customer_id = cu.customer_id 
JOIN regions re
	ON cu.region_id = re.region_id 
JOIN deliveries de
	ON o.order_id = de.order_id
WHERE
    (de.actual_delivery_date IS NOT NULL
     AND de.shipped_at IS NOT NULL
     AND de.actual_delivery_date < de.shipped_at)

    OR (de.delivery_status = 'delivered'
        AND de.actual_delivery_date IS NULL)

    OR (de.delivery_status = 'failed'
        AND de.actual_delivery_date IS NOT NULL)

    OR (de.delivery_status = 'pending'
        AND de.shipped_at IS NOT NULL)
ORDER BY re.region_name,
		 o.order_id ASC;
	
--TASK 32: CUSTOMER PERFORMANCE & BEHAVIOR ANALYSIS
WITH customers_stats AS(
	SELECT cu.customer_id,
		   cu.customer_name,
		   re.region_name
	FROM customers cu
	JOIN regions re
		ON cu.region_id = re.region_id 
),
order_stats AS (
	SELECT o.customer_id,
		   COUNT(*) AS orders_count,
		   COUNT(*) FILTER (
		   		WHERE o.status = 'completed'
		   		) AS completed_orders,
		   COUNT(*) FILTER (
		   		WHERE o.status = 'pending'
		   		) AS pending_orders,
		   COUNT(*) FILTER (
		   		WHERE o.status = 'refunded'
		   		) AS refunded_orders,
		   SUM(o.total_amount) FILTER (
		   		WHERE o.status = 'completed'
		   		) AS total_completed_amount,
		   AVG(o.total_amount) FILTER (
		   		WHERE o.status = 'completed'
		   		) AS avg_completed_amount
	FROM orders o
	WHERE o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
	GROUP BY o.customer_id
),
payments_stats AS(
	SELECT o.customer_id,
		   COUNT(*) AS payments_count,
		   COUNT(CASE
		   	WHEN pa.status = 'completed'
		   	THEN 1
		   END
		   ) AS successful_payments,
		   COUNT(CASE
		   	WHEN pa.status = 'failed'
		   	THEN 1
		   END
		   ) AS failed_payments,
		   SUM(CASE
		   	WHEN pa.status = 'completed'
		   	THEN pa.amount
		   	ELSE 0
		   END
		   ) AS successful_payment_amount,
		   COUNT(DISTINCT pa.payment_method) AS payment_methods_count
	FROM payments pa
	JOIN orders o
		ON pa.order_id = o.order_id
	WHERE o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
	GROUP BY o.customer_id
),
deliveries_stats AS(
	SELECT o.customer_id,
		   COUNT(*) FILTER (
		   WHERE de.delivery_status = 'delivered'
		   ) AS delivered_count,
		   COUNT(*) FILTER (
		   WHERE de.delivery_status = 'failed'
		   ) AS failed_count,
		   COUNT(CASE
		   	WHEN de.actual_delivery_date > expected_delivery_date 
		   	THEN 1
		   END
		   ) AS late_deliveries,
		   ROUND(
	   		AVG(
	   		CASE
	   			WHEN de.actual_delivery_date > de.expected_delivery_date
	   			THEN EXTRACT(
	   				EPOCH FROM(
	   				de.actual_delivery_date - de.expected_delivery_date
	   				)
	   			) / 86400.0
	   		END
	   		), 2
	   		) AS avg_delay_days
	FROM deliveries de
	JOIN orders o
		ON de.order_id = o.order_id
	WHERE o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
	GROUP BY o.customer_id
),
purchase_dynamics AS(
	SELECT o.customer_id,
		   o.order_id,
		   o.total_amount,
		   o.order_date,
		   ROW_NUMBER() OVER(
		   		PARTITION BY o.customer_id
		   		ORDER BY o.order_date DESC,
		   				 o.order_id DESC
		   		) AS rn
	FROM orders o
	WHERE o.order_date >= DATE '2025-01-01'
		AND o.order_date < DATE '2026-01-01'
),
purchase_summary AS(
	SELECT pd.customer_id,
		   MAX(CASE
		   	WHEN pd.rn = 1
		   	THEN pd.order_id
		   END
		   ) AS latest_order_id,
		   MAX(CASE
		   	WHEN pd.rn = 1
		   	THEN pd.total_amount
		   END
		   ) AS latest_order_amount,
		   MAX(CASE
		   	WHEN pd.rn = 2
		   	THEN pd.total_amount
		   END
		   ) AS previous_order_amount
		   
	FROM purchase_dynamics pd
	GROUP BY pd.customer_id
)
SELECT cs.customer_id,
	   cs.customer_name,
	   cs.region_name,
	   os.orders_count,
	   os.completed_orders,
	   os.pending_orders,
	   os.refunded_orders,
	   os.total_completed_amount,
	   os.avg_completed_amount,
	   ps.payments_count,
	   ps.successful_payments,
	   ps.failed_payments,
	   ps.successful_payment_amount,
	   ps.payment_methods_count,
	   ds.delivered_count,
	   ds.failed_count,
	   COALESCE(ds.late_deliveries,0) AS late_deliveries,
	   ds.avg_delay_days,
	   pu.latest_order_id,
	   pu.latest_order_amount,
	   pu.previous_order_amount,
	   pu.latest_order_amount - pu.previous_order_amount AS order_amount_difference,
	   RANK() OVER(
	   		ORDER BY os.total_completed_amount DESC
	   		) AS customer_rank
FROM customers_stats cs
JOIN order_stats os
	ON cs.customer_id = os.customer_id
JOIN payments_stats ps
	ON os.customer_id = ps.customer_id
LEFT JOIN deliveries_stats ds
	ON ps.customer_id = ds.customer_id
JOIN purchase_summary pu
	ON cs.customer_id = pu.customer_id
WHERE os.orders_count >= 3
	AND os.completed_orders > 0
		AND ps.failed_payments > 0
ORDER BY customer_rank ASC;
	   
	   
--TASK 33: E-COMMERCE BUSINESS PERFORMANCE ANALYSIS
WITH sales_stats AS(
	SELECT p.product_id,
		   p.product_name,
		   c.category_name,
		   c.category_id,
		   SUM(ot.quantity) AS quantity_sales_count,
		   SUM(ot.quantity * ot.unit_price) AS total_revenue,
		   SUM(ot.quantity * ot.unit_price) / SUM(ot.quantity) AS quantity_avg_sum
	FROM products p
	JOIN categories c
		ON p.category_id = c.category_id 
	JOIN order_items ot
		ON p.product_id = ot.product_id 
	JOIN orders o
		ON ot.order_id = o.order_id
	WHERE o.status = 'completed'
		AND o.order_date >= DATE '2025-01-01'
			AND o.order_date < DATE '2026-01-01'
	GROUP BY p.product_id,
		     p.product_name,
		     c.category_name,
		     c.category_id
),
return_stats AS(
	SELECT ot.product_id,
		   SUM(re.return_quantity) FILTER(
		   		WHERE re.return_status = 'completed'
		   		) AS returns_count,
		   COUNT(*) FILTER(
		   		WHERE re.return_status = 'completed'
		   		) AS completed_returns
	FROM returns re
	JOIN order_items ot
		ON re.order_item_id = ot.order_item_id 
	JOIN orders o
		ON ot.order_id = o.order_id 
	WHERE o.status = 'completed'
		AND o.order_date >= DATE '2025-01-01'
			AND o.order_date < DATE '2026-01-01'
	GROUP BY ot.product_id
),
inventory_stocks AS(
	SELECT i.product_id,
		   SUM(i.stock_quantity) AS total_stock,
		   COUNT(DISTINCT wa.warehouse_id) AS unique_warehouses
	FROM inventory i
	JOIN warehouses wa
		ON i.warehouse_id = wa.warehouse_id
	GROUP BY i.product_id
),
supplier_analyze AS(
	SELECT sp.product_id,
		   COUNT(DISTINCT s.supplier_id) AS unique_suppliers,
		   STRING_AGG(DISTINCT s.company_name, ', '
		   			  ORDER BY s.company_name
		   			  ) AS supplier_names
	FROM suppliers s
	JOIN supplier_products sp
		ON s.supplier_id = sp.supplier_id
	GROUP BY sp.product_id
),
category_analyze AS(
	SELECT ss.product_id,
		   ss.category_id,
		   ss.quantity_sales_count,
		   ss.total_revenue,
		   SUM(ss.total_revenue) OVER(
		   		PARTITION BY ss.category_id
		   		) AS category_revenue,
		   SUM(ss.quantity_sales_count) OVER(
		   		PARTITION BY ss.category_id
		   		) AS category_units_sold,
		   COUNT(ss.product_id) OVER(
		   		PARTITION BY ss.category_id
		   		) AS category_products_count,
		   RANK() OVER(
		   		PARTITION BY ss.category_id
		   		ORDER BY ss.total_revenue DESC
		   		) AS category_rank
	FROM sales_stats ss
),
client_analysis AS(
	SELECT ot.product_id,
		   COUNT(DISTINCT o.customer_id) AS unique_customers,
		   COUNT(DISTINCT o.order_id) AS orders_count
	FROM orders o
	JOIN order_items ot
		ON o.order_id = ot.order_id
	WHERE o.status = 'completed'	
		AND o.order_date >= DATE '2025-01-01'
			AND o.order_date < DATE '2026-01-01'
	GROUP BY ot.product_id
),
final_metrics AS(
	SELECT ss.product_id,
	ss.product_name,
	ss.category_name,
	ss.quantity_sales_count,
	ss.total_revenue,
	ss.quantity_avg_sum,
	COALESCE(rs.returns_count, 0) AS returns_count,
	COALESCE(rs.completed_returns, 0) AS completed_returns,
	rs.returns_count * 100.0 / ss.quantity_sales_count AS return_rate,
	COALESCE(ik.total_stock, 0) AS total_stock,
	COALESCE(ik.unique_warehouses, 0) AS unique_warehouses,
	ss.quantity_sales_count - ik.total_stock AS stock_deficit,
	sa.unique_suppliers,
	sa.supplier_names,
	ca.category_revenue,
	ca.category_units_sold,
	ca.category_products_count,
	ss.total_revenue / NULLIF(ca.category_revenue, 0) * 100.0  AS category_revenue_share,
	ca.category_rank,
	cs.unique_customers,
	cs.orders_count
	FROM sales_stats ss
LEFT JOIN return_stats rs
    ON ss.product_id = rs.product_id
LEFT JOIN inventory_stocks ik
    ON ss.product_id = ik.product_id
LEFT JOIN supplier_analyze sa
    ON ss.product_id = sa.product_id
JOIN category_analyze ca
    ON ss.product_id = ca.product_id
JOIN client_analysis cs
    ON ss.product_id = cs.product_id
)
SELECT *,
	   CASE
	   	WHEN fm.return_rate >= 10.0 THEN 'High Return Risk'
	   	WHEN fm.total_stock < fm.quantity_sales_count * 0.25 THEN 'Stock Shortage Risk'
	   	WHEN fm.category_revenue_share >= 15
	   		AND fm.return_rate < 5
	   	THEN 'Business Opportunity'
	   	ELSE 'Stable'
	   END AS business_status
FROM final_metrics fm








	   
	   	
	




	   




