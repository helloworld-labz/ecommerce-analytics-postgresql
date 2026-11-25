/*
===============================================================================
                         E-COMMERCE ANALYTICS
                         QUERY OPTIMIZATION
===============================================================================

Project: E-Commerce Analytics
Database: PostgreSQL

Description:
    Investigation of query performance and PostgreSQL execution plans.
    Experiments with database statistics, query planning and optimization.

Topics:
    1. Database Diagnostics
    2. Extended Statistics
    3. Task 27 - Query Optimization
    4. Task 32 - Query Optimization
    5. Data Distribution Analysis

Tools:
    PostgreSQL | EXPLAIN ANALYZE | Extended Statistics

===============================================================================
*/

-- 1. EXTENDED STATISTICS


-- 1.1 N-DISTINCT STATISTICS
CREATE STATISTICS stats_orders_customer_status
				  (ndistinct)
ON customer_id, status
FROM orders 

ANALYZE orders

-- 1.2 VERIFY EXTENDED STATISTICS
SELECT stxname,
	   stxrelid,
	   stxkind
FROM pg_statistic_ext
WHERE stxname = 'stats_orders_customer_status'

-- 1.3 INSPECT N-DISTINCT STATISTICS
SELECT stxname,
	   stxdndistinct
FROM pg_statistic_ext pse
JOIN pg_statistic_ext_data psed
	ON pse.oid = psed.stxoid
WHERE pse.stxname = 'stats_orders_customer_status'

-- 1.4 ANALYZE GROUP DISTRIBUTION
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.customer_id,
	   o.status,
	   COUNT(*) AS orders_count
FROM orders o
GROUP BY o.customer_id,
		 o.status

-- Compare distinct customer groups 
SELECT customer_id, COUNT(*)
FROM orders
GROUP BY customer_id;

analyze orders;
		 


-- 2. FUNCTIONAL DEPENDENCIES

-- Check distinct value combinations
SELECT COUNT(DISTINCT o.customer_id),
	   COUNT(DISTINCT o.status),
	   COUNT(DISTINCT(o.customer_id, o.status))
FROM orders o

-- Check status distribution per customer
SELECT o.customer_id,
	   COUNT(DISTINCT o.status) AS unique_distinct
FROM orders o
GROUP BY o.customer_id
ORDER BY unique_distinct DESC
LIMIT 10;

-- Create dependency statistics
CREATE STATISTICS stats_orders_customer_status_dep
				 (dependencies)
ON customer_id, status
FROM orders 

ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.customer_id,
	   o.status,
	   COUNT(*) AS orders_count
FROM orders o
GROUP BY o.customer_id,
		 o.status



-- =====================================================
-- 3. QUERY OPTIMIZATION: TASK 27
-- =====================================================

-- 3.1 Initial Query Analysis
EXPLAIN (ANALYZE, BUFFERS)
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

-- 3.2 Index Inspection
SELECT tablename,
	   indexname,
	   indexdef
FROM pg_indexes
WHERE tablename IN('customers', 'orders', 'payments')

-- 3.3 Refresh Table Statistics
ANALYZE customers;
ANALYZE orders;
ANALYZE payments;

-- 3.4 Table Size Inspection
SELECT COUNT(*) AS customers_count
FROM customers

SELECT COUNT(*) AS orders_count
FROM orders

SELECT COUNT(*) AS payments_count
FROM payments

-- 3.5 Payment Status Distribution
SELECT pa.status,
	   COUNT(*) AS payments_count
FROM payments pa
GROUP BY pa.status 
ORDER BY payments_count DESC

-- 3.6 Orders with Successful and Failed Payments
SELECT COUNT(*) AS orders_count
FROM orders o
WHERE EXISTS(
	SELECT 1
	FROM payments pa
	WHERE pa.status = 'completed'
		AND pa.order_id  = o.order_id 
	) AND EXISTS(
		SELECT 1
		FROM payments pa2
		WHERE pa2.status = 'failed'
			AND pa2.order_id = o.order_id
	)

-- 3.7 Payment Status Comparison
SELECT COUNT(DISTINCT pa.order_id) AS unique_orders
FROM payments pa
WHERE pa.status = 'failed'

SELECT COUNT(DISTINCT pa.order_id) AS unique_orders
FROM payments pa
WHERE pa.status = 'completed'

-- 3.8 Filtered Order Analysis
SELECT COUNT(*) AS orders_count
FROM orders o
WHERE o.status IN('completed', 'pending', 'refunded')
	AND EXISTS(
		SELECT 1
		FROM payments pa2
		WHERE pa2.status = 'failed'
			AND pa2.order_id = o.order_id 
			)

-- =====================================================
-- 4. QUERY OPTIMIZATION: TASK 32
-- =====================================================

-- 4.1 Initial Execution Plan Analysis
EXPLAIN (ANALYZE, BUFFERS)
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

-- 4.2 TABLE STATISTICS INSPECTION
-- Check table activity, dead tuples and scan statistics.

SELECT relname,
       n_live_tup,
       n_dead_tup,
       last_analyze,
       last_autoanalyze,
       seq_scan,
       idx_scan
FROM pg_stat_user_tables
WHERE relname = 'orders';


-- 4.3 COLUMN STATISTICS ANALYSIS
-- Inspect the distribution of customer_id values.

SELECT attname,
       n_distinct,
       null_frac,
       most_common_vals,
       most_common_freqs,
       histogram_bounds
FROM pg_stats
WHERE tablename = 'orders'
  AND attname = 'customer_id';


-- 4.4 CUSTOMER ORDER DISTRIBUTION
-- Analyze the distribution of completed orders per customer.

WITH customers_stats AS (
    SELECT o.customer_id,
           COUNT(*) AS orders_count,
           COUNT(*) FILTER (
               WHERE o.status = 'completed'
           ) AS completed_orders
    FROM orders o
    WHERE o.order_date >= DATE '2025-01-01'
      AND o.order_date < DATE '2026-01-01'
    GROUP BY o.customer_id
)
SELECT COUNT(*) AS customer_count,
       COUNT(*) FILTER (
           WHERE completed_orders >= 2
       ) AS clients_with_2_completed_orders,
       COUNT(*) FILTER (
           WHERE completed_orders = 0
       ) AS clients_without_completed_orders,
       COUNT(*) FILTER (
           WHERE completed_orders = 1
       ) AS clients_with_1_completed_order
FROM customers_stats cs;


-- 4.5 DATABASE METADATA INSPECTION
-- Inspect table and column metadata.

SELECT ps.relname,
       ps.reltuples,
       ps.relpages,
       pa.attname,
       pa.attstattarget,
       pa.attnotnull,
       pa.atttypid,
       pa.attlen
FROM pg_attribute pa
JOIN pg_class ps
    ON ps.oid = pa.attrelid
WHERE ps.relname = 'orders'
  AND pa.attname = 'customer_id'
  AND ps.relkind = 'r';


-- Inspect PostgreSQL configuration parameters.

SELECT name,
       setting,
       unit
FROM pg_settings;


-- 4.6 EXTENDED STATISTICS INSPECTION
-- Check existing extended statistics on orders.

SELECT stxname,
       stxrelid,
       stxkeys,
       stxkind
FROM pg_statistic_ext
WHERE stxrelid = 'public.orders'::regclass;


-- Inspect functional dependency statistics.

SELECT statistics_name,
       attnames,
       kinds,
       dependencies
FROM pg_stats_ext
WHERE statistics_name = 'stats_orders_customer_status_dep';


-- 4.7 MATERIALIZED AGGREGATION
-- Store customer-level aggregates in a temporary table.

CREATE TEMP TABLE customer_order_stats AS
SELECT customer_id,
       COUNT(*) AS orders_count,
       COUNT(*) FILTER (
           WHERE status = 'completed'
       ) AS completed_orders
FROM orders
WHERE order_date >= DATE '2025-01-01'
  AND order_date < DATE '2026-01-01'
GROUP BY customer_id;


-- 4.8 FILTER SELECTIVITY ANALYSIS
-- Analyze customer groups and calculate their percentage.

WITH first_with AS (
    SELECT COUNT(customer_id) AS customer_count,

           COUNT(*) FILTER (
               WHERE orders_count >= 3
                 AND completed_orders > 0
           ) AS first_stat,

           COUNT(*) FILTER (
               WHERE orders_count >= 3
                 AND completed_orders = 0
           ) AS second_stat,

           COUNT(*) FILTER (
               WHERE orders_count < 3
                 AND completed_orders > 0
           ) AS third_stat,

           COUNT(*) FILTER (
               WHERE orders_count < 3
                 AND completed_orders = 0
           ) AS four_stat

    FROM customer_order_stats
)
SELECT fw.customer_count,
       fw.first_stat,
       (fw.first_stat::numeric /
        NULLIF(fw.customer_count, 0)) * 100.0 AS percent_client
FROM first_with fw;


-- 4.9 MCV STATISTICS EXPERIMENT
-- Inspect column statistics of the temporary table.

SELECT attname,
       n_distinct,
       most_common_vals,
       most_common_freqs,
       histogram_bounds
FROM pg_stats
WHERE tablename = 'customer_order_stats';


-- Create multivariate MCV statistics.

CREATE STATISTICS customer_order_stats_orders_count_completed_orders
    (mcv)
ON orders_count, completed_orders
FROM customer_order_stats;


-- Refresh statistics of the temporary table.

ANALYZE customer_order_stats;


-- Verify the created MCV statistics.

SELECT stxname,
       stxkeys,
       stxkind
FROM pg_statistic_ext
WHERE stxname = 'customer_order_stats_orders_count_completed_orders';


-- Test cardinality estimation after creating MCV statistics.

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id,
       orders_count,
       completed_orders
FROM customer_order_stats
WHERE orders_count >= 3
  AND completed_orders > 0;
	


