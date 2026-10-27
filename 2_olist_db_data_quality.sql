USE olise_db;

-- A1. Jumlah baris seluruh tabel
SELECT 'customers' AS nama_tabel, COUNT(*) AS total FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;

-- B1. Customers
SELECT
    COUNT(*) AS total_baris,
    COUNT(customer_id) AS id_terisi,
    COUNT(DISTINCT customer_id) AS id_unik
FROM customers;

-- B2. Orders
SELECT
    COUNT(*) AS total_baris,
    COUNT(order_id) AS id_terisi,
    COUNT(DISTINCT order_id) AS id_unik
FROM orders;

-- B3. Products
SELECT
    COUNT(*) AS total_baris,
    COUNT(product_id) AS id_terisi,
    COUNT(DISTINCT product_id) AS id_unik
FROM products;

-- B4. Sellers
SELECT
    COUNT(*) AS total_baris,
    COUNT(seller_id) AS id_terisi,
    COUNT(DISTINCT seller_id) AS id_unik
FROM sellers;

-- B5. Kategori
SELECT
    COUNT(*) AS total_baris,
    COUNT(product_category_name) AS kategori_terisi,
    COUNT(DISTINCT product_category_name) AS kategori_unik
FROM category_translation;

-- B6. Composite key order_items
SELECT order_id, order_item_id, COUNT(*) AS jumlah
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- B7. Composite key order_payments
SELECT order_id, payment_sequential, COUNT(*) AS jumlah
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- B8. Duplikasi review_id
SELECT review_id, COUNT(*) AS jumlah
FROM order_reviews
WHERE review_id IS NOT NULL
GROUP BY review_id
HAVING COUNT(*) > 1;

-- C1. Customers
SELECT
    SUM(customer_id IS NULL) AS customer_id_null,
    SUM(customer_unique_id IS NULL) AS customer_unique_id_null,
    SUM(customer_city IS NULL) AS city_null,
    SUM(customer_state IS NULL) AS state_null
FROM customers;

-- C2. Orders
SELECT
    SUM(order_id IS NULL) AS order_id_null,
    SUM(customer_id IS NULL) AS customer_id_null,
    SUM(order_status IS NULL) AS status_null,
    SUM(order_purchase_timestamp IS NULL) AS purchase_date_null
FROM orders;

-- C3. Products
SELECT
    SUM(product_id IS NULL) AS product_id_null,
    SUM(product_category_name IS NULL) AS category_null,
    SUM(TRIM(product_category_name) = '') AS category_empty
FROM products;

-- C4. Sellers
SELECT
    SUM(seller_id IS NULL) AS seller_id_null,
    SUM(seller_zip_code_prefix IS NULL) AS zip_null
FROM sellers;

-- C5. Order items
SELECT
    SUM(order_id IS NULL) AS order_id_null,
    SUM(order_item_id IS NULL) AS item_id_null,
    SUM(product_id IS NULL) AS product_id_null,
    SUM(seller_id IS NULL) AS seller_id_null
FROM order_items;

-- C6. Order payments
SELECT
    SUM(order_id IS NULL) AS order_id_null,
    SUM(payment_sequential IS NULL) AS sequential_null,
    SUM(payment_value IS NULL) AS payment_value_null
FROM order_payments;

-- C7. Order reviews
SELECT
    SUM(review_id IS NULL) AS review_id_null,
    SUM(order_id IS NULL) AS order_id_null,
    SUM(review_score IS NULL) AS score_null
FROM order_reviews;

-- D1. Orders -> Customers
SELECT COUNT(*) AS orders_tanpa_customer
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;

-- D2. Order items -> Orders
SELECT COUNT(*) AS items_tanpa_order
FROM order_items i
LEFT JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

-- D3. Order items -> Products
SELECT COUNT(*) AS items_tanpa_product
FROM order_items i
LEFT JOIN products p
    ON i.product_id = p.product_id
WHERE i.product_id IS NOT NULL
  AND p.product_id IS NULL;

-- D4. Order items -> Sellers
SELECT COUNT(*) AS items_tanpa_seller
FROM order_items i
LEFT JOIN sellers s
    ON i.seller_id = s.seller_id
WHERE i.seller_id IS NOT NULL
  AND s.seller_id IS NULL;

-- D5. Order payments -> Orders
SELECT COUNT(*) AS payments_tanpa_order
FROM order_payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- D6. Order reviews -> Orders
SELECT COUNT(*) AS reviews_tanpa_order
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE r.order_id IS NOT NULL
  AND o.order_id IS NULL;

-- D7. Products -> Category translation
SELECT
    p.product_category_name,
    COUNT(*) AS jumlah_produk
FROM products p
LEFT JOIN category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND TRIM(p.product_category_name) <> ''
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name;

-- E1. Skor review harus antara 1 dan 5
SELECT COUNT(*) AS skor_review_tidak_valid
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5
   OR review_score IS NULL;

-- E2. Harga dan ongkos kirim negatif
SELECT COUNT(*) AS item_nilai_tidak_valid
FROM order_items
WHERE price < 0
   OR freight_value < 0;

-- E3. Nilai pembayaran negatif
SELECT COUNT(*) AS payment_negatif
FROM order_payments
WHERE payment_value < 0;

-- E4. Jumlah pembayaran cicilan tidak valid
SELECT COUNT(*) AS installments_tidak_valid
FROM order_payments
WHERE payment_installments < 0;

-- E5. Tanggal pembelian setelah tanggal persetujuan
SELECT COUNT(*) AS tanggal_tidak_konsisten
FROM orders
WHERE order_approved_at < order_purchase_timestamp;

-- Tanggal pengiriman ke customer sebelum tanggal pembelian
SELECT COUNT(*) AS delivery_sebelum_purchase
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- Tanggal pengiriman ke carrier setelah pengiriman ke customer
SELECT COUNT(*) AS carrier_date_tidak_konsisten
FROM orders
WHERE order_delivered_carrier_date >
      order_delivered_customer_date;

-- Pesanan selesai tetapi tanggal pengiriman customer kosong
SELECT COUNT(*) AS delivered_tanpa_tanggal
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- G1. Prefix yang memiliki lebih dari satu baris
SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS jumlah_baris
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY jumlah_baris DESC
LIMIT 20;

-- G2. Koordinat di luar rentang geografis
SELECT COUNT(*) AS koordinat_tidak_valid
FROM geolocation
WHERE geolocation_lat NOT BETWEEN -90 AND 90
   OR geolocation_lng NOT BETWEEN -180 AND 180;
