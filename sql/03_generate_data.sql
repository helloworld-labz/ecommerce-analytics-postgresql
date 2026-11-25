--
INSERT INTO customers(
	customer_name,
	email,
	registration_date,
	phone,
	region_id
)
SELECT 
	  'Customer_' || n,
	  'customer' || n || '@example.com',
	  TIMESTAMP '2024-01-01'
	  	+ random() * INTERVAL '730 days',
	  '+7' || (9000000000 + n)::text,
	  (1 + floor(random() * 5))::integer
	FROM generate_series(1, 5000) AS  n;

--
INSERT INTO products(
	product_name,
	price,
	category_id
)
SELECT 
	  'Product_' || n,
	  ROUND((100 + random() * 99900)::numeric, 2),
	  (1 + floor(random() * 5))::integer
	FROM generate_series(1,500) AS n;

--
INSERT INTO suppliers(
	company_name,
	contact_email,
	contact_phone
)
SELECT
	  'Supplier_' || n,
	  'supplier' || n || '@example.com',
	  '+7800' || LPAD(n::text, 7, '0')
FROM generate_series(1, 50) AS n;

--
INSERT INTO supplier_products (
    supplier_id,
    product_id
)
SELECT
    s.supplier_id,
    p.product_id
FROM suppliers s
CROSS JOIN products p
ORDER BY random()
LIMIT 1000
ON CONFLICT (supplier_id, product_id) DO NOTHING;

--
INSERT INTO warehouses(
	warehouse_name,
	warehouse_address
)
SELECT 
	'Warehouse_' || n,
	'Address_' || n
FROM generate_series(1,5) AS n;

--
INSERT INTO inventory(
	warehouse_id,
	product_id,
	stock_quantity
)
SELECT 
	w.warehouse_id,
	p.product_id,
	floor(random() * 500)::integer
FROM warehouses w
CROSS JOIN products p
ORDER BY random()
LIMIT 1500
ON CONFLICT(warehouse_id, product_id) DO NOTHING;

--
INSERT INTO orders (
    order_date,
    status,
    total_amount,
    customer_id
)
SELECT
    TIMESTAMP '2024-01-01'
        + random() * INTERVAL '730 days',

    CASE
        WHEN random() < 0.70 THEN 'completed'
        WHEN random() < 0.50 THEN 'pending'
        WHEN random() < 0.6667 THEN 'cancelled'
        ELSE 'refunded'
    END,

    ROUND((100 + random() * 49900)::numeric, 2),

    c.customer_id

FROM generate_series(1, 50000) AS n

CROSS JOIN LATERAL (
    SELECT customer_id
    FROM customers
    WHERE n > 0
    ORDER BY random()
    LIMIT 1
) c;

--
INSERT INTO order_items(
	quantity,
	unit_price,
	order_id,
	product_id 
)
SELECT 
	(1 + floor(random() * 5))::integer,
	p.price,
	o.order_id,
	p.product_id
	
FROM orders o

CROSS JOIN LATERAL
	generate_series(1, 2 + (o.order_id % 3)) AS gs(line_no)
	
JOIN products p
	ON p.product_id = ((o.order_id + gs.line_no - 1) % 500) + 1;

--
WITH order_totals AS (
    SELECT
        order_id,
        SUM(quantity * unit_price) AS subtotal
    FROM order_items
    GROUP BY order_id
)

INSERT INTO order_discounts (
    discount_amount,
    order_id,
    discount_id
)
SELECT
    ROUND(ot.subtotal * d.discount_percent / 100, 2),
    o.order_id,
    d.discount_id

FROM orders o

JOIN order_totals ot
    ON o.order_id = ot.order_id

CROSS JOIN LATERAL (
    SELECT
        discount_id,
        discount_percent
    FROM discounts
    WHERE o.order_date BETWEEN start_date AND end_date
    ORDER BY random()
    LIMIT 1
) d

WHERE o.status = 'completed'
AND random() < 0.20;

--
INSERT INTO payments (
    payment_date,
    amount,
    payment_method,
    status,
    order_id
)
SELECT
    o.order_date + random() * INTERVAL '2 days',

    o.total_amount,

    CASE
        WHEN random() < 0.60 THEN 'card'
        WHEN random() < 0.80 THEN 'cash'
        ELSE 'bank_transfer'
    END,

    CASE
        WHEN o.status = 'completed' THEN 'completed'
        WHEN o.status = 'pending' THEN 'pending'
        WHEN o.status = 'cancelled' THEN 'failed'
        ELSE 'refunded'
    END,

    o.order_id

FROM orders o;

--
INSERT INTO deliveries (
    delivery_address,
    shipped_at,
    expected_delivery_date,
    actual_delivery_date,
    delivery_status,
    order_id
)
SELECT
    'Адрес получателя, заказ №' || o.order_id,

    CASE
        WHEN o.status IN ('completed', 'refunded')
        THEN o.order_date + random() * INTERVAL '2 days'
        ELSE NULL
    END,

    o.order_date + INTERVAL '3 days'
        + random() * INTERVAL '5 days',

    CASE
        WHEN o.status IN ('completed', 'refunded')
        THEN o.order_date + INTERVAL '5 days'
             + random() * INTERVAL '4 days'
        ELSE NULL
    END,

    CASE
        WHEN o.status = 'completed' THEN 'delivered'
        WHEN o.status = 'pending' THEN 'pending'
        WHEN o.status = 'cancelled' THEN 'failed'
        ELSE 'delivered'
    END,

    o.order_id

FROM orders o;

--
INSERT INTO returns (
    return_date,
    return_quantity,
    return_reason,
    return_status,
    order_item_id
)
SELECT
    d.actual_delivery_date
        + INTERVAL '1 day'
        + random() * INTERVAL '30 days',

    (1 + floor(random() * oi.quantity))::integer,

    CASE
        WHEN random() < 0.30 THEN 'Damaged product'
        WHEN random() < 0.60 THEN 'Wrong product'
        WHEN random() < 0.80 THEN 'Changed mind'
        ELSE 'Product does not match description'
    END,

    CASE
        WHEN random() < 0.25 THEN 'requested'
        WHEN random() < 0.50 THEN 'approved'
        WHEN random() < 0.70 THEN 'rejected'
        ELSE 'completed'
    END,

    oi.order_item_id

FROM order_items oi

JOIN orders o
    ON oi.order_id = o.order_id

JOIN deliveries d
    ON o.order_id = d.order_id

WHERE d.delivery_status = 'delivered'
AND random() < 0.05;

