-- ============================================
-- БИЗНЕС-ЗАПРОСЫ ЛОГИСТИЧЕСКОЙ СИСТЕМЫ
-- Реальные запросы, которые использует компания для работы
-- ============================================

-- ====================
-- РАЗДЕЛ 1: ОПЕРАЦИОННАЯ РАБОТА (ЕЖЕДНЕВНЫЕ)
-- ====================

-- 1. ЗАКАЗЫ НА СЕГОДНЯ ДЛЯ ОБРАБОТКИ
-- Что: Список заказов, которые нужно собрать сегодня
-- Кто: Сотрудники склада
-- Когда: Каждое утро
SELECT 
    o.order_id,
    c.company_name as клиент,
    o.priority as приоритет,
    o.status as статус,
    COUNT(od.product_id) as колво_товаров,
    SUM(od.quantity) as общее_количество,
    o.total_amount as сумма,
    w.warehouse_name as склад
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN warehouses w ON o.warehouse_id = w.warehouse_id
WHERE o.required_date = CURRENT_DATE
    AND o.status IN ('pending', 'processing', 'packing')
GROUP BY o.order_id, c.company_name, o.priority, o.status, o.total_amount, w.warehouse_name
ORDER BY 
    CASE o.priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'normal' THEN 3
        WHEN 'low' THEN 4
    END,
    o.order_date;

-- 2. ТОВАРЫ ДЛЯ КОМПЛЕКТАЦИИ ЗАКАЗА
-- Что: Конкретный список товаров для одного заказа
-- Кто: Комплектовщик
-- Когда: При подготовке каждого заказа
SELECT 
    od.order_id,
    p.product_name as товар,
    od.quantity as нужно,
    p.current_stock as есть_на_складе,
    p.warehouse_id as место_хранения,
    CASE 
        WHEN p.current_stock >= od.quantity THEN 'ДОСТАТОЧНО'
        ELSE 'НЕДОСТАТОЧНО: ' || (od.quantity - p.current_stock)::VARCHAR || ' ед.'
    END as статус_наличия
FROM order_details od
JOIN products p ON od.product_id = p.product_id
WHERE od.order_id = 3  -- параметр: номер заказа
ORDER BY p.warehouse_id;

-- 3. ВОДИТЕЛИ И ТРАНСПОРТ НА СЕГОДНЯ
-- Что: Кто и на чем доступен для доставок
-- Кто: Диспетчер
-- Когда: Утреннее планирование
SELECT 
    d.driver_id,
    d.first_name || ' ' || d.last_name as водитель,
    d.phone as телефон,
    v.license_plate as транспорт,
    v.vehicle_type as тип_транспорта,
    v.capacity_kg as грузоподъемность,
    v.status as статус_транспорта,
    COUNT(dlv.delivery_id) as доставок_сегодня
FROM drivers d
LEFT JOIN vehicles v ON d.vehicle_id = v.vehicle_id
LEFT JOIN deliveries dlv ON d.driver_id = dlv.driver_id 
    AND DATE(dlv.planned_departure) = CURRENT_DATE
WHERE d.status = 'active'
    AND v.status IN ('available', 'in_transit')
GROUP BY d.driver_id, d.first_name, d.last_name, d.phone, 
         v.license_plate, v.vehicle_type, v.capacity_kg, v.status
ORDER BY доставок_сегодня;

-- ====================
-- РАЗДЕЛ 2: ОТЧЕТЫ ДЛЯ МЕНЕДЖМЕНТА (НЕДЕЛЬНЫЕ)
-- ====================

-- 4. ЭФФЕКТИВНОСТЬ ДОСТАВОК ЗА НЕДЕЛЮ
-- Что: Анализ своевременности доставок
-- Кто: Логистический менеджер
-- Когда: Понедельник утром
WITH weekly_deliveries AS (
    SELECT 
        dlv.delivery_id,
        o.order_id,
        c.company_name,
        dlv.driver_id,
        dr.first_name || ' ' || dr.last_name as driver_name,
        dlv.planned_arrival,
        dlv.actual_arrival,
        CASE 
            WHEN dlv.actual_arrival IS NULL THEN 'В ПУТИ'
            WHEN dlv.actual_arrival <= dlv.planned_arrival THEN 'ВОВРЕМЯ'
            ELSE 'ОПОЗДАНИЕ'
        END as timeliness,
        EXTRACT(EPOCH FROM (dlv.actual_arrival - dlv.planned_arrival))/3600 as delay_hours
    FROM deliveries dlv
    JOIN orders o ON dlv.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN drivers dr ON dlv.driver_id = dr.driver_id
    WHERE dlv.planned_departure >= CURRENT_DATE - INTERVAL '7 days'
        AND dlv.status = 'delivered'
)
SELECT 
    timeliness as своевременность,
    COUNT(*) as количество,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) as процент,
    ROUND(AVG(delay_hours), 1) as среднее_опоздание_часов,
    MAX(delay_hours) as макс_опоздание_часов
FROM weekly_deliveries
GROUP BY timeliness
ORDER BY 
    CASE timeliness
        WHEN 'ВОВРЕМЯ' THEN 1
        WHEN 'В ПУТИ' THEN 2
        WHEN 'ОПОЗДАНИЕ' THEN 3
    END;

-- 5. ТОП-10 КЛИЕНТОВ ПО ОБЪЕМУ
-- Что: Кто приносит больше всего денег
-- Кто: Отдел продаж
-- Когда: Раз в месяц
SELECT 
    c.company_name as клиент,
    c.city as город,
    c.customer_type as тип,
    COUNT(DISTINCT o.order_id) as всего_заказов,
    SUM(o.total_amount) as общая_сумма,
    ROUND(AVG(o.total_amount), 2) as средний_чек,
    MAX(o.order_date) as последний_заказ
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
    AND o.status NOT IN ('cancelled')
GROUP BY c.customer_id, c.company_name, c.city, c.customer_type
ORDER BY общая_сумма DESC
LIMIT 10;

-- 6. АНАЛИЗ ЗАПАСОВ НА СКЛАДАХ
-- Что: Каких товаров мало/много
-- Кто: Складской менеджер
-- Когда: Раз в неделю
SELECT 
    w.warehouse_name as склад,
    p.category as категория,
    p.product_name as товар,
    p.current_stock as текущий_остаток,
    p.min_stock_level as минимальный_запас,
    p.current_stock - p.min_stock_level as разница,
    CASE 
        WHEN p.current_stock <= 0 THEN 'НЕТ В НАЛИЧИИ'
        WHEN p.current_stock <= p.min_stock_level THEN 'НИЖЕ МИНИМУМА'
        WHEN p.current_stock <= p.min_stock_level * 1.5 THEN 'МАЛО'
        ELSE 'ДОСТАТОЧНО'
    END as статус,
    COALESCE(SUM(od.quantity), 0) as продано_за_месяц,
    p.last_restock_date as дата_последнего_пополнения
FROM products p
JOIN warehouses w ON p.warehouse_id = w.warehouse_id
LEFT JOIN order_details od ON p.product_id = od.product_id
    AND od.order_id IN (
        SELECT order_id FROM orders 
        WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
    )
GROUP BY w.warehouse_id, w.warehouse_name, p.product_id, p.product_name, 
         p.category, p.current_stock, p.min_stock_level, p.last_restock_date
HAVING p.current_stock <= p.min_stock_level * 2  -- показываем проблемные
ORDER BY w.warehouse_name, статус, разница;

-- ====================
-- РАЗДЕЛ 3: АНАЛИТИКА И ПЛАНИРОВАНИЕ (МЕСЯЧНЫЕ)
-- ====================

-- 7. ЗАГРУЗКА СКЛАДОВ И ТРАНСПОРТА
-- Что: Насколько эффективно используем ресурсы
-- Кто: Директор по логистике
-- Когда: Отчет за месяц
SELECT 
    'СКЛАДЫ' as тип_ресурса,
    w.warehouse_name as ресурс,
    ROUND(100.0 * w.current_occupancy / w.capacity_sq_m, 1) as загрузка_процент,
    w.current_occupancy || ' из ' || w.capacity_sq_m || ' м²' as загрузка_детально,
    COUNT(DISTINCT p.product_id) as уникальных_товаров,
    SUM(p.current_stock) as всего_единиц
FROM warehouses w
LEFT JOIN products p ON w.warehouse_id = p.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name, w.current_occupancy, w.capacity_sq_m

UNION ALL

SELECT 
    'ТРАНСПОРТ' as тип_ресурса,
    v.license_plate || ' (' || v.vehicle_type || ')' as ресурс,
    ROUND(100.0 * COUNT(dlv.delivery_id) / 20, 1) as загрузка_процент, -- 20 доставок = 100%
    COUNT(dlv.delivery_id) || ' доставок за месяц' as загрузка_детально,
    COUNT(DISTINCT dlv.driver_id) as разных_водителей,
    SUM(dlv.distance_km) as всего_км
FROM vehicles v
LEFT JOIN deliveries dlv ON v.vehicle_id = dlv.vehicle_id
    AND dlv.planned_departure >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY v.vehicle_id, v.license_plate, v.vehicle_type
ORDER BY тип_ресурса DESC, загрузка_процент DESC;

-- 8. СЕЗОННОСТЬ ПО КАТЕГОРИЯМ ТОВАРОВ
-- Что: Когда что лучше продается
-- Кто: Планирование закупок
-- Когда: Перед сезоном
SELECT 
    EXTRACT(MONTH FROM o.order_date) as месяц,
    p.category as категория,
    COUNT(DISTINCT o.order_id) as заказов,
    SUM(od.quantity) as проданных_единиц,
    SUM(od.quantity * od.unit_price) as выручка,
    ROUND(AVG(od.unit_price), 2) as средняя_цена
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
    AND o.status NOT IN ('cancelled', 'pending')
GROUP BY EXTRACT(MONTH FROM o.order_date), p.category
ORDER BY месяц, выручка DESC;

-- ====================
-- РАЗДЕЛ 4: ОПЕРАТИВНЫЕ УВЕДОМЛЕНИЯ (АВТОМАТИЧЕСКИЕ)
-- ====================

-- 9. ТОВАРЫ, КОТОРЫЕ ЗАКОНЧАТСЯ СКОРО
-- Что: Авто-отчет для отдела закупок
-- Кто: Система (автоматически)
-- Когда: Каждый день в 9:00
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    w.warehouse_name,
    p.current_stock,
    p.min_stock_level,
    ROUND(p.current_stock * 30.0 / NULLIF(
        (SELECT SUM(od2.quantity)
         FROM order_details od2
         JOIN orders o2 ON od2.order_id = o2.order_id
         WHERE od2.product_id = p.product_id
            AND o2.order_date >= CURRENT_DATE - INTERVAL '30 days'
        ), 0), 1
    ) as дней_осталось  -- прогноз, на сколько дней хватит
FROM products p
JOIN warehouses w ON p.warehouse_id = w.warehouse_id
WHERE p.current_stock <= p.min_stock_level * 1.2  -- близко к минимуму
    AND (SELECT SUM(od2.quantity)
         FROM order_details od2
         JOIN orders o2 ON od2.order_id = o2.order_id
         WHERE od2.product_id = p.product_id
            AND o2.order_date >= CURRENT_DATE - INTERVAL '30 days'
        ) > 0  -- были продажи в последний месяц
ORDER BY дней_осталось;

-- 10. КЛИЕНТЫ С ПРОСРОЧЕННЫМИ ЗАКАЗАМИ
-- Что: Для службы поддержки
-- Кто: Менеджер по работе с клиентами
-- Когда: Два раза в день
SELECT 
    o.order_id,
    c.company_name,
    c.contact_person,
    c.phone,
    o.required_date as обещанная_дата,
    CURRENT_DATE - o.required_date as дней_просрочки,
    o.total_amount as сумма_заказа,
    o.status,
    dlv.status as статус_доставки,
    dt.location as последнее_известное_местоположение
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN deliveries dlv ON o.order_id = dlv.order_id
LEFT JOIN delivery_tracking dt ON dlv.delivery_id = dt.delivery_id
    AND dt.tracking_time = (
        SELECT MAX(tracking_time)
        FROM delivery_tracking
        WHERE delivery_id = dlv.delivery_id
    )
WHERE o.required_date < CURRENT_DATE
    AND o.status NOT IN ('delivered', 'cancelled')
    AND (dlv.status IS NULL OR dlv.status NOT IN ('delivered'))
ORDER BY дней_просрочки DESC, o.order_id;

-- ====================
-- РАЗДЕЛ 5: ОПТИМИЗАЦИОННЫЕ ЗАПРОСЫ (ДЛЯ АНАЛИТА)
-- ====================

-- 11. ОПТИМИЗАЦИЯ МАРШРУТОВ (ГРУППИРОВКА ЗАКАЗОВ)
-- Что: Как объединить доставки в одном направлении
-- Кто: Логистический аналитик
-- Когда: При планировании на день
WITH todays_orders AS (
    SELECT 
        o.order_id,
        c.city,
        c.address,
        o.total_weight,
        o.total_volume,
        o.warehouse_id,
        w.location as warehouse_location
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN warehouses w ON o.warehouse_id = w.warehouse_id
    WHERE o.required_date = CURRENT_DATE + 1
        AND o.status IN ('ready', 'packing')
        AND o.total_weight IS NOT NULL
)
SELECT 
    city as город,
    COUNT(*) as заказов,
    SUM(total_weight) as общий_вес_кг,
    SUM(total_volume) as общий_объем_м3,
    STRING_AGG(order_id::VARCHAR, ', ') as номера_заказов,
    -- Подбираем подходящий транспорт
    CASE 
        WHEN SUM(total_weight) <= 1500 THEN 'van'
        WHEN SUM(total_weight) <= 5000 THEN 'truck'
        ELSE 'container'
    END as рекомендованный_транспорт
FROM todays_orders
GROUP BY city
HAVING SUM(total_weight) > 0
ORDER BY город;

-- 12. АНАЛИЗ ПРИБЫЛЬНОСТИ КЛИЕНТОВ (LTV)
-- Что: Lifetime Value клиентов
-- Кто: Финансовый аналитик
-- Когда: Квартальный отчет
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.company_name,
        c.registration_date,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date,
        AVG(o.total_amount) as avg_order_value,
        COUNT(DISTINCT EXTRACT(MONTH FROM o.order_date)) as active_months
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
        AND o.status NOT IN ('cancelled')
        AND o.order_date >= c.registration_date
    GROUP BY c.customer_id, c.company_name, c.registration_date
)
SELECT 
    company_name as клиент,
    registration_date as дата_регистрации,
    total_orders as всего_заказов,
    total_revenue as общая_выручка,
    ROUND(total_revenue / NULLIF(total_orders, 0), 2) as средний_чек,
    EXTRACT(DAY FROM CURRENT_DATE - last_order_date) as дней_без_заказов,
    active_months as активных_месяцев,
    CASE 
        WHEN EXTRACT(DAY FROM CURRENT_DATE - last_order_date) <= 30 THEN 'АКТИВНЫЙ'
        WHEN EXTRACT(DAY FROM CURRENT_DATE - last_order_date) <= 90 THEN 'ПАССИВНЫЙ'
        ELSE 'НЕАКТИВНЫЙ'
    END as статус_клиента,
    ROUND(total_revenue / NULLIF(
        EXTRACT(DAY FROM CURRENT_DATE - registration_date) / 30.0, 0
    ), 2) as доход_в_месяц
FROM customer_metrics
ORDER BY доход_в_месяц DESC NULLS LAST;

-- ====================
-- КОММЕНТАРИЙ ДЛЯ ПОРТФОЛИО:
-- ====================
/*
ЭТИ ЗАПРОСЫ ПОКАЗЫВАЮТ РЕАЛЬНУЮ РАБОТУ СИСТЕМЫ:

1. ОПЕРАЦИОННЫЕ (ежедневные) - для сотрудников
2. ОТЧЕТНЫЕ (недельные) - для менеджеров  
3. АНАЛИТИЧЕСКИЕ (месячные) - для руководства
4. АВТОМАТИЧЕСКИЕ - для системных уведомлений
5. ОПТИМИЗАЦИОННЫЕ - для улучшения процессов

КАЖДЫЙ ЗАПРОС РЕШАЕТ КОНКРЕТНУЮ БИЗНЕС-ЗАДАЧУ:
- Ускорение обработки заказов
- Снижение издержек
- Улучшение обслуживания клиентов
- Планирование ресурсов

ИМЕННО ТАКИЕ ЗАПРОСЫ ПОЗВОЛИЛИ СОКРАТИТЬ ВРЕМЯ
ОБРАБОТКИ НА 70% В РЕАЛЬНОМ КЕЙСЕ ИЗ СТАТЬИ.
*/
