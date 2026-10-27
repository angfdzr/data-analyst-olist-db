
USE olise_db;

-- VIEW 1: TREN PENJUALAN BULANAN
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    DATE_FORMAT(
        o.order_delivered_customer_date,
        '%Y-%m'
    ) AS bulan,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    ROUND(SUM(oi.price), 2) AS nilai_penjualan
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY DATE_FORMAT(
    o.order_delivered_customer_date,
    '%Y-%m'
);


-- VIEW 2: PENJUALAN PER KATEGORI
CREATE OR REPLACE VIEW vw_category_sales AS
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS kategori,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    COUNT(*) AS jumlah_item,
    ROUND(SUM(oi.price), 2) AS nilai_penjualan
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(
    ct.product_category_name_english,
    p.product_category_name,
    'Uncategorized'
);


-- VIEW 3: PENJUALAN DAN PENGIRIMAN PER NEGARA BAGIAN
CREATE OR REPLACE VIEW vw_state_sales_delivery AS
SELECT
    sales.negara_bagian,
    sales.jumlah_pesanan,
    sales.nilai_penjualan,
    delivery.rata_rata_hari_pengiriman,
    delivery.persentase_terlambat
FROM
(
    SELECT
        c.customer_state AS negara_bagian,
        COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
        ROUND(SUM(oi.price), 2) AS nilai_penjualan
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
) AS sales
LEFT JOIN
(
    SELECT
        c.customer_state AS negara_bagian,
        ROUND(
            AVG(
                DATEDIFF(
                    o.order_delivered_customer_date,
                    o.order_purchase_timestamp
                )
            ),
            2
        ) AS rata_rata_hari_pengiriman,
        ROUND(
            100.0 * AVG(
                CASE
                    WHEN o.order_delivered_customer_date >
                         o.order_estimated_delivery_date
                    THEN 1.0
                    ELSE 0.0
                END
            ),
            2
        ) AS persentase_terlambat
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_state
) AS delivery
    ON sales.negara_bagian = delivery.negara_bagian;


-- CEK HASIL VIEW
SELECT * FROM vw_monthly_sales ORDER BY bulan;
SELECT * FROM vw_category_sales ORDER BY nilai_penjualan DESC;
SELECT * FROM vw_state_sales_delivery
ORDER BY nilai_penjualan DESC;