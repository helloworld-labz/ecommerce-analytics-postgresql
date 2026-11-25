
--CATEGORIES 
CREATE TABLE categories(
	category_id serial primary key,
	category_name varchar(50) NOT NULL UNIQUE
	);

--PRODUCTS
CREATE TABLE products(
	product_id serial primary key,
	product_name varchar(100) NOT NULL,
	price numeric(9, 2) NOT NULL CHECK (price > 0),
	category_id integer NOT NULL,
	foreign key(category_id) references categories(category_id)
	);

--REGIONS
CREATE TABLE regions(
	region_id serial primary key,
	region_name varchar(100) NOT NULL UNIQUE 
	);

--CUSTOMERS
CREATE TABLE customers(
	customer_id serial primary key,
	customer_name varchar(50) NOT NULL,
	email varchar(150) UNIQUE NOT NULL,
	registration_date timestamp NOT NULL,
	phone text,
	region_id integer NOT NULL,
	foreign key(region_id) references regions(region_id)
	);

--ORDERS
CREATE TABLE orders(
	order_id serial primary key,
	order_date timestamp NOT NULL,
	status varchar(30) NOT NULL CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
	total_amount numeric(9, 2) NOT NULL CHECK(total_amount >= 0), --итоговая стоимость заказа уже после скидок
	customer_id integer NOT NULL,
	foreign key(customer_id) references customers(customer_id)
	);

--ORDER_ITEMS
CREATE TABLE order_items(
	order_item_id serial primary key,
	quantity integer NOT NULL CHECK(quantity > 0),
	unit_price numeric(9, 2) NOT NULL CHECK(unit_price >= 0), --цена товара на момент покупки до скидки
	order_id integer NOT NULL,
	product_id integer NOT NULL,
	foreign key(order_id) references orders(order_id),
	foreign key(product_id) references products(product_id)
	);

--SUPPLIERS
CREATE TABLE suppliers(
	supplier_id serial primary key,
	company_name varchar(100) NOT NULL,
	contact_email varchar(150) NOT NULL UNIQUE,
	contact_phone text
	);

--SUPPLIER_PRODUCTS
CREATE TABLE supplier_products(
	supplier_product_id serial primary key,
	supplier_id integer NOT NULL,
	product_id integer NOT NULL,
	foreign key(supplier_id) references suppliers(supplier_id),
	foreign key(product_id) references products(product_id),
	UNIQUE (supplier_id, product_id)
	);

--WAREHOUSES
CREATE TABLE warehouses(
	warehouse_id serial primary key,
	warehouse_name varchar(100) NOT NULL UNIQUE,
	warehouse_address text NOT NULL
	);

--INVENTORY
CREATE TABLE inventory(
	inventory_id serial primary key,
	stock_quantity integer NOT NULL CHECK(stock_quantity >= 0),
	warehouse_id integer NOT NULL,
	product_id integer NOT NULL,
	foreign key(warehouse_id) references warehouses(warehouse_id),
	foreign key(product_id) references products(product_id),
	UNIQUE(warehouse_id, product_id)
	);

--PAYMENTS
CREATE TABLE payments(
	payment_id serial primary key,
	payment_date timestamp NOT NULL,
	amount numeric(9, 2) NOT NULL CHECK(amount  > 0),
	payment_method varchar(50) NOT NULL CHECK(payment_method IN('card', 'cash', 'bank_transfer')),
	status varchar(30) NOT NULL CHECK(status IN('pending', 'completed', 'failed', 'refunded')),
	order_id integer NOT NULL,
	foreign key(order_id) references orders(order_id)
	);

--DELIVERIES
CREATE TABLE deliveries(
	delivery_id serial primary key,
	delivery_address varchar(100) NOT NULL,
	shipped_at timestamp,
	expected_delivery_date TIMESTAMP NOT NULL
    	CHECK (shipped_at IS NULL OR expected_delivery_date >= shipped_at),
	actual_delivery_date TIMESTAMP,
	delivery_status varchar(50) NOT NULL CHECK(delivery_status IN('pending', 'shipped', 'delivered', 'failed')),
	order_id integer NOT NULL UNIQUE,
	foreign key (order_id) references orders(order_id)
	);

--RETURNS
CREATE TABLE returns(
	return_id serial primary key,
	return_date timestamp NOT NULL,
	return_quantity integer NOT NULL CHECK(return_quantity > 0),
	return_reason text NOT NULL,
	return_status varchar(50) NOT NULL CHECK(return_status IN('requested', 'approved', 'rejected', 'completed')),
	order_item_id integer NOT NULL,
	foreign key (order_item_id) references order_items(order_item_id)
	);

--DISCOUNTS
CREATE TABLE discounts(
	discount_id serial primary key,
	discount_code text NOT NULL UNIQUE,
	discount_percent numeric(5,2) NOT NULL CHECK(discount_percent > 0 AND discount_percent <= 100),
	start_date timestamp NOT NULL,
	end_date timestamp NOT NULL CHECK(start_date < end_date)
	);

--ORDER_DISCOUNT
CREATE TABLE order_discounts(
	order_discount_id serial primary key,
	discount_amount numeric(9, 2) NOT NULL CHECK(discount_amount >= 0), --сумма скидки в рублях
	order_id integer NOT NULL,
	discount_id integer NOT NULL,
	foreign key (order_id) references orders(order_id),
	foreign key (discount_id) references discounts(discount_id),
	UNIQUE(order_id, discount_id)
	);

