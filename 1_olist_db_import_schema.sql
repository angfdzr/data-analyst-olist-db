-- 1. Membuat database
create database olise_db;
use olise_db;

-- 2. Membuat skema database tanpa relasi terlebih dahulu, namun pakai primary key dan tipe data
create table sellers(
	seller_id varchar(255) primary key,
	seller_zip_code_prefix int,
	seller_city varchar(255),
	seller_state varchar(32)
); 

create table category_translation(
	product_category_name varchar(255) primary key,
	product_category_name_english varchar(255)
);

create table geolocation(
	geolocation_id bigint primary key auto_increment,
	geolocation_zip_code_prefix int,
	geolocation_lat decimal(10,7),
	geolocation_lng decimal(10,7),
	geolocation_city varchar(255),
	geolocation_state varchar(32)
);

create table customers(
	customer_id varchar(255) primary key,
	customer_unique_id varchar(255),
	customer_zip_code_prefix int,
	customer_city varchar(255),
	customer_state varchar(32)
);

create table products(
	product_id varchar(255) primary key,
	product_category_name varchar(255),
	product_name_lenght int,
	product_description_lenght int,
	product_photos_qty int,
	product_weight_g int,
	product_length_cm int,
	product_height_cm int,
	product_width_cm int
);

create table orders(
	order_id varchar(255) primary key,
	customer_id varchar(255),
	order_status varchar(255),
	order_purchase_timestamp datetime,
	order_approved_at datetime,
	order_delivered_carrier_date datetime,
	order_delivered_customer_date datetime,
	order_estimated_delivery_date datetime
);

create table order_items(
	order_id varchar(255),
	order_item_id varchar(255),
	product_id varchar(255),
	seller_id varchar(255),
	shipping_limit_date datetime,
	price decimal(10,2),
	freight_value decimal(10,2),
	primary key (order_id, order_item_id)
);

create table order_reviews(
	review_row_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

create table order_payments(
	order_id varchar(255),
	payment_sequential varchar(255),
	payment_type varchar(255),
	payment_installments int,
	payment_value decimal(10,2),
	primary key(order_id, payment_sequential)
);
