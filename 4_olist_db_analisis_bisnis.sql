
USE olise_db;

-- 1 TREND PENJUALAN BULANAN
SELECT
    DATE_FORMAT(o.order_delivered_customer_date, '%Y-%m') AS bulan,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    SUM(oi.price) AS nilai_penjualan
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_delivered_customer_date, '%Y-%m')
ORDER BY bulan;


-- 2 KATEGORI DENGAN NILAI PENJUALAN TERBESAR
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS kategori,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    SUM(oi.price) AS nilai_penjualan
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY kategori
ORDER BY nilai_penjualan DESC;


-- 3 NILAI PENJUALAN PER NEGARA BAGIAN PELANGGAN
SELECT
    c.customer_state AS negara_bagian,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    SUM(oi.price) AS nilai_penjualan
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY nilai_penjualan DESC;


-- 4 RATA-RATA WAKTU PENGIRIMAN PER NEGARA BAGIAN
WITH waktu_kirim AS (
    SELECT
        o.order_id,
        c.customer_state,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_purchase_timestamp
        ) AS lama_hari
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
)
SELECT
    customer_state AS negara_bagian,
    COUNT(*) AS jumlah_pesanan,
    ROUND(AVG(lama_hari), 2) AS rata_rata_hari_pengiriman
FROM waktu_kirim
GROUP BY customer_state
ORDER BY rata_rata_hari_pengiriman DESC;


-- 5 PERSENTASE KETERLAMBATAN PER NEGARA BAGIAN
SELECT
    c.customer_state AS negara_bagian,
    COUNT(*) AS jumlah_pesanan_terkirim,
    SUM(
        CASE
            WHEN o.order_delivered_customer_date >
                 o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS jumlah_terlambat,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS persentase_terlambat
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY persentase_terlambat DESC;


-- 6 JUMLAH PESANAN BERDASARKAN STATUS
SELECT
    order_status,
    COUNT(*) AS jumlah_pesanan,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM orders),
        2
    ) AS persentase_pesanan
FROM orders
GROUP BY order_status
ORDER BY jumlah_pesanan DESC;


-- 7 PERFORMA SELLER BERDASARKAN NILAI PENJUALAN
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    COUNT(*) AS jumlah_item,
    SUM(oi.price) AS nilai_penjualan
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY nilai_penjualan DESC
LIMIT 20;


-- 8 METODE PEMBAYARAN
SELECT
    op.payment_type AS metode_pembayaran,
    COUNT(*) AS jumlah_transaksi_pembayaran,
    COUNT(DISTINCT op.order_id) AS jumlah_pesanan,
    ROUND(SUM(op.payment_value), 2) AS total_pembayaran,
    ROUND(AVG(op.payment_value), 2) AS rata_rata_nilai_pembayaran
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY total_pembayaran DESC;


-- 9 DISTRIBUSI SKOR ULASAN
SELECT
    review_score,
    COUNT(*) AS jumlah_ulasan,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*)
         FROM order_reviews
         WHERE review_score BETWEEN 1 AND 5),
        2
    ) AS persentase_ulasan
FROM order_reviews
WHERE review_score BETWEEN 1 AND 5
GROUP BY review_score
ORDER BY review_score;


-- 10 HUBUNGAN KETERLAMBATAN DENGAN SKOR ULASAN
WITH durasi_pesanan AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date >
                 o.order_estimated_delivery_date
            THEN 'Terlambat'
            ELSE 'Tepat waktu'
        END AS status_pengiriman
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
ulasan_per_pesanan AS (
    SELECT
        order_id,
        AVG(review_score) AS rata_rata_skor
    FROM order_reviews
    WHERE review_score BETWEEN 1 AND 5
    GROUP BY order_id
)
SELECT
    d.status_pengiriman,
    COUNT(*) AS jumlah_pesanan_dengan_ulasan,
    ROUND(AVG(u.rata_rata_skor), 2) AS rata_rata_skor_ulasan
FROM durasi_pesanan d
JOIN ulasan_per_pesanan u
    ON d.order_id = u.order_id
GROUP BY d.status_pengiriman;
