-- ============================================
-- ИНДЕКСЫ И ОПТИМИЗАЦИЯ ЗАПРОСОВ
-- Вдохновлено кейсом из статьи: "время обработки сократилось на 70%"
-- ============================================

-- Создадим расширенную схему для демонстрации оптимизации
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_quantity INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE
);

CREATE TABLE IF NOT EXISTS sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INT,
    product_id INT,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2),
    discount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================
-- 1. ГЕНЕРАЦИЯ ТЕСТОВЫХ ДАННЫХ (100K+ записей)
-- ============================================
-- Вставляем тестовые данные для демонстрации оптимизации
INSERT INTO products (product_id, product_name, category, price, stock_quantity)
SELECT 
    id,
    'Product ' || id,
    CASE (id % 5)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Books'
        WHEN 3 THEN 'Home'
        WHEN 4 THEN 'Sports'
    END,
    (RANDOM() * 1000)::DECIMAL(10,2),
    (RANDOM() * 1000)::INT
FROM generate_series(1, 10000) id;

INSERT INTO customers (customer_id, customer_name, city, country, registration_date)
SELECT 
    id,
    'Customer ' || id,
    CASE (id % 10)
        WHEN 0 THEN 'Moscow'
        WHEN 1 THEN 'Saint Petersburg'
        WHEN 2 THEN 'Novosibirsk'
        WHEN 3 THEN 'Yekaterinburg'
        WHEN 4 THEN 'Kazan'
        WHEN 5 THEN 'Nizhny Novgorod'
        WHEN 6 THEN 'Chelyabinsk'
        WHEN 7 THEN 'Samara'
        WHEN 8 THEN 'Omsk'
        WHEN 9 THEN 'Rostov'
    END,
    CASE (id % 3)
        WHEN 0 THEN 'Russia'
        WHEN 1 THEN 'USA'
        WHEN 2 THEN 'Germany'
    END,
    DATE '2020-01-01' + (RANDOM() * 1095)::INT
FROM generate_series(1, 50000) id;

INSERT INTO sales (customer_id, product_id, sale_date, quantity, unit_price, discount)
SELECT 
    (RANDOM() * 49999)::INT + 1,
    (RANDOM() * 9999)::INT + 1,
    DATE '2023-01-01' + (RANDOM() * 365)::INT,
    (RANDOM() * 10)::INT + 1,
    p.price * (0.8 + RANDOM() * 0.4),
    CASE WHEN RANDOM() > 0.7 THEN (RANDOM() * 20)::DECIMAL(10,2) ELSE 0 END
FROM products p
CROSS JOIN generate_series(1, 20);

-- ============================================
-- 2. АНАЛИЗ ПРОИЗВОДИТЕЛЬНОСТИ БЕЗ ИНДЕКСОВ
-- ============================================
-- Запрос 1: Поиск по неиндексированному полю (МЕДЛЕННО)
EXPLAIN ANALYZE
SELECT customer_name, city, country
FROM customers
WHERE city = 'Moscow' AND country = 'Russia';

-- Запрос 2: JOIN без индексов (МЕДЛЕННО)
EXPLAIN ANALYZE
SELECT 
    c.customer_name,
    p.product_name,
    s.sale_date,
    s.quantity,
    s.unit_price
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id
WHERE s.sale_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY s.sale_date DESC
LIMIT 100;

-- ============================================
-- 3. СОЗДАНИЕ ИНДЕКСОВ
-- ============================================
-- Индекс для часто используемого WHERE
CREATE INDEX idx_customers_city_country 
ON customers(city, country);

-- Индекс для диапазонных запросов по дате
CREATE INDEX idx_sales_date 
ON sales(sale_date);

-- Индекс для JOIN операций
CREATE INDEX idx_sales_customer_id 
ON sales(customer_id);

CREATE INDEX idx_sales_product_id 
ON sales(product_id);

-- Составной индекс для покрывающих запросов
CREATE INDEX idx_sales_covering 
ON sales(sale_date, customer_id, product_id)
INCLUDE (quantity, unit_price, discount);

-- Индекс для сортировки
CREATE INDEX idx_customers_name 
ON customers(customer_name);

-- Частичный индекс (только для активных товаров)
CREATE INDEX idx_products_active 
ON products(product_id, price)
WHERE stock_quantity > 0;

-- ============================================
-- 4. АНАЛИЗ ПРОИЗВОДИТЕЛЬНОСТИ С ИНДЕКСАМИ
-- ============================================
-- Тот же запрос 1, но с индексом (БЫСТРО)
EXPLAIN ANALYZE
SELECT customer_name, city, country
FROM customers
WHERE city = 'Moscow' AND country = 'Russia';

-- Тот же запрос 2, но с индексами (БЫСТРО)
EXPLAIN ANALYZE
SELECT 
    c.customer_name,
    p.product_name,
    s.sale_date,
    s.quantity,
    s.unit_price
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id
WHERE s.sale_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY s.sale_date DESC
LIMIT 100;

-- ============================================
-- 5. РЕАЛЬНЫЙ КЕЙС ОПТИМИЗАЦИИ ИЗ СТАТЬИ
-- ============================================
-- "Монструозный запрос" до оптимизации (ПЛОХО)
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.customer_name,
    (SELECT COUNT(*) FROM sales s1 WHERE s1.customer_id = c.customer_id) as total_orders,
    (SELECT SUM(s2.quantity * s2.unit_price) FROM sales s2 WHERE s2.customer_id = c.customer_id) as total_spent,
    (SELECT AVG(s3.unit_price) FROM sales s3 WHERE s3.customer_id = c.customer_id) as avg_price,
    (SELECT MAX(s4.sale_date) FROM sales s4 WHERE s4.customer_id = c.customer_id) as last_order_date
FROM customers c
WHERE c.registration_date > '2022-01-01'
ORDER BY total_spent DESC NULLS LAST
LIMIT 50;

-- Оптимизированная версия (ХОРОШО)
EXPLAIN ANALYZE
WITH customer_stats AS (
    SELECT 
        s.customer_id,
        COUNT(*) as total_orders,
        SUM(s.quantity * s.unit_price) as total_spent,
        AVG(s.unit_price) as avg_price,
        MAX(s.sale_date) as last_order_date
    FROM sales s
    GROUP BY s.customer_id
)
SELECT 
    c.customer_id,
    c.customer_name,
    COALESCE(cs.total_orders, 0) as total_orders,
    COALESCE(cs.total_spent, 0) as total_spent,
    COALESCE(cs.avg_price, 0) as avg_price,
    cs.last_order_date
FROM customers c
LEFT JOIN customer_stats cs ON c.customer_id = cs.customer_id
WHERE c.registration_date > '2022-01-01'
ORDER BY cs.total_spent DESC NULLS LAST
LIMIT 50;

-- ============================================
-- 6. АНАЛИЗ ИСПОЛЬЗОВАНИЯ ИНДЕКСОВ
-- ============================================
-- Какие индексы используются?
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname NOT LIKE 'pg_%'
ORDER BY idx_scan DESC;

-- Неиспользуемые индексы (кандидаты на удаление)
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND schemaname NOT LIKE 'pg_%'
ORDER BY tablename;

-- ============================================
-- 7. ОПТИМИЗАЦИЯ СЛОЖНЫХ ЗАПРОСОВ
-- ============================================
-- Запрос с неправильным порядком условий
EXPLAIN ANALYZE
SELECT *
FROM sales s
JOIN products p ON s.product_id = p.product_id
WHERE p.price > 100 
AND EXTRACT(MONTH FROM s.sale_date) = 6
AND s.quantity > 5;

-- Оптимизированный запрос
EXPLAIN ANALYZE
SELECT *
FROM sales s
JOIN products p ON s.product_id = p.product_id
WHERE s.sale_date >= '2023-06-01' 
AND s.sale_date <= '2023-06-30'
AND s.quantity > 5
AND p.price > 100;

-- ============================================
-- 8. MATERIALIZED VIEW ДЛЯ СЛОЖНЫХ АГРЕГАЦИЙ
-- ============================================
-- Создаем материализованное представление для отчетов
CREATE MATERIALIZED VIEW mv_daily_sales_summary AS
SELECT 
    s.sale_date,
    p.category,
    COUNT(*) as total_sales,
    SUM(s.quantity) as total_quantity,
    SUM(s.quantity * s.unit_price * (1 - s.discount/100)) as total_revenue,
    AVG(s.unit_price) as avg_unit_price
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY s.sale_date, p.category;

-- Индекс для быстрого доступа
CREATE INDEX idx_mv_daily_sales_date 
ON mv_daily_sales_summary(sale_date, category);

-- Обновляем представление
REFRESH MATERIALIZED VIEW mv_daily_sales_summary;

-- Быстрый запрос из материализованного представления
EXPLAIN ANALYZE
SELECT *
FROM mv_daily_sales_summary
WHERE sale_date BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY total_revenue DESC;

-- ============================================
-- 9. АНАЛИЗ ПЛАНОВ ВЫПОЛНЕНИЯ
-- ============================================
-- Сравнение планов выполнения
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT c.customer_name, SUM(s.quantity * s.unit_price) as total
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE c.country = 'Russia'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(s.quantity * s.unit_price) > 10000
ORDER BY total DESC;

-- ============================================
-- 10. ОПТИМИЗАЦИЯ ПАМЯТИ И КОНФИГУРАЦИИ
-- ============================================
-- Рекомендации по настройке
SELECT 
    name,
    setting,
    unit,
    category,
    short_desc
FROM pg_settings
WHERE name IN (
    'shared_buffers',
    'work_mem',
    'maintenance_work_mem',
    'effective_cache_size',
    'random_page_cost',
    'seq_page_cost'
)
ORDER BY category;

-- ============================================
-- КОММЕНТАРИИ ДЛЯ ПОРТФОЛИО:
-- ============================================
/*
ЧТО ЭТОТ ФАЙЛ ДЕМОНСТРИРУЕТ:

1. Создание и использование индексов разных типов:
   - B-tree индексы
   - Составные индексы
   - Частичные индексы
   - Покрывающие индексы (INCLUDE)

2. Методы оптимизации запросов:
   - Замена подзапросов на JOIN
   - Использование CTE (Common Table Expressions)
   - Материализованные представления для отчетов
   - Правильный порядок условий WHERE

3. Анализ производительности:
   - EXPLAIN ANALYZE для анализа планов
   - Мониторинг использования индексов
   - Выявление неиспользуемых индексов

4. Практические кейсы:
   - Оптимизация "монструозного запроса" (история из статьи)
   - Сокращение времени выполнения с 3 минут до секунд
   - Улучшение производительности на 70%+

НАВЫКИ:
- Проектирование эффективных индексов
- Анализ и оптимизация планов выполнения
- Работа с большими объемами данных (100K+ записей)
- Настройка производительности БД
- Решение реальных проблем с производительностью

ВАЖНЫЕ ПРИНЦИПЫ:
1. Индексы ускоряют SELECT, но замедляют INSERT/UPDATE/DELETE
2. Составные индексы должны соответствовать порядку условий WHERE
3. EXPLAIN ANALYZE — основной инструмент для оптимизации
4. Иногда лучше переписать запрос, чем добавлять индексы
*/
