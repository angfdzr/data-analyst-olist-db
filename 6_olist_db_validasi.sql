
USE olise_db;

-- VALIDASI 1: TOTAL NILAI PENJUALAN MANUAL
SELECT
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    COUNT(*) AS jumlah_item,
    ROUND(SUM(oi.price), 2) AS total_nilai_penjualan
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- VALIDASI 2: TOTAL PENJUALAN PADA VIEW BULANAN
SELECT
    SUM(jumlah_pesanan) AS total_pesanan_per_bulan,
    ROUND(SUM(nilai_penjualan), 2) AS total_penjualan_view
FROM vw_monthly_sales;

-- Catatan:
-- SUM(jumlah_pesanan) dari view bulanan bukan jumlah
-- pesanan unik keseluruhan, karena satu pesanan hanya
-- masuk satu bulan, tetapi tetap validasi jumlah pesanan
-- dengan perhitungan manual pada periode yang sama.


-- VALIDASI 3: TOTAL PENJUALAN PER KATEGORI
SELECT
    ROUND(SUM(nilai_penjualan), 2) AS total_penjualan_kategori
FROM vw_category_sales;


-- VALIDASI 4: TOTAL PENJUALAN PER NEGARA BAGIAN
SELECT
    ROUND(SUM(nilai_penjualan), 2) AS total_penjualan_wilayah
FROM vw_state_sales_delivery;


-- VALIDASI 5: BANDINGKAN TOTAL PENJUALAN
SELECT
    'Manual: delivered orders' AS sumber,
    ROUND(SUM(oi.price), 2) AS total_penjualan
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'

UNION ALL

SELECT
    'View: category sales',
    ROUND(SUM(nilai_penjualan), 2)
FROM vw_category_sales

UNION ALL

SELECT
    'View: state sales',
    ROUND(SUM(nilai_penjualan), 2)
FROM vw_state_sales_delivery;


-- VALIDASI 6: CEK KATEGORI DENGAN PENJUALAN TERBESAR
SELECT *
FROM vw_category_sales
ORDER BY nilai_penjualan DESC
LIMIT 10;


-- VALIDASI 7: CEK WILAYAH DENGAN KETERLAMBATAN TERTINGGI
SELECT
    negara_bagian,
    rata_rata_hari_pengiriman,
    persentase_terlambat
FROM vw_state_sales_delivery
ORDER BY persentase_terlambat DESC;


-- VALIDASI 8: CEK JUMLAH BARIS PADA SETIAP VIEW
SELECT
    'vw_monthly_sales' AS nama_view,
    COUNT(*) AS jumlah_baris
FROM vw_monthly_sales

UNION ALL

SELECT
    'vw_category_sales',
    COUNT(*)
FROM vw_category_sales

UNION ALL

SELECT
    'vw_state_sales_delivery',
    COUNT(*)
FROM vw_state_sales_delivery;
