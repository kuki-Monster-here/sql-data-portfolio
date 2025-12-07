-- ============================================
-- ОПЕРАЦИИ JOIN (СОЕДИНЕНИЕ ТАБЛИЦ)
-- "элегантный запрос из 10 строк с использованием JOIN и GROUP BY"
-- ============================================

-- Продолжаем использовать таблицы из 01_basic_crud.sql
-- Предполагаем, что они уже созданы

-- ДОБАВИМ НОВЫЕ ДАННЫЕ ДЛЯ ДЕМОНСТРАЦИИ
INSERT INTO users (user_id, username, email, registration_date) 
VALUES 
    (3, 'bob_johnson', 'bob@example.com', '2023-03-10'),
    (4, 'carol_white', 'carol@example.com', '2023-03-15'),
    (5, 'david_brown', 'david@example.com', '2023-04-01');

INSERT INTO orders (order_id, user_id, order_date, total_amount) 
VALUES 
    (103, 3, '2023-03-12', 89.99),
    (104, 3, '2023-03-20', 150.00),
    (105, 4, '2023-03-18', 199.99),
    (106, 5, '2023-04-05', 299.99);

-- ============================================
-- 1. INNER JOIN (ВНУТРЕННЕЕ СОЕДИНЕНИЕ)
-- ============================================
-- Только пользователи с заказами
SELECT 
    u.username,
    u.email,
    o.order_date,
    o.total_amount
FROM users u
INNER JOIN orders o ON u.user_id = o.user_id
ORDER BY o.order_date DESC;

-- ============================================
-- 2. LEFT JOIN (ЛЕВОЕ СОЕДИНЕНИЕ)
-- ============================================
-- Все пользователи, даже без заказов
SELECT 
    u.username,
    u.email,
    COUNT(o.order_id) as order_count,
    COALESCE(SUM(o.total_amount), 0) as total_spent
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username, u.email
ORDER BY total_spent DESC;

-- ============================================
-- 3. RIGHT JOIN (ПРАВОЕ СОЕДИНЕНИЕ)
-- ============================================
-- Пример: все заказы (даже если пользователь удалён)
-- Создадим тестовый "потерянный" заказ
INSERT INTO orders (order_id, user_id, order_date, total_amount) 
VALUES (107, 999, '2023-04-10', 49.99);

SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    COALESCE(u.username, '[ПОЛЬЗОВАТЕЛЬ УДАЛЕН]') as username
FROM users u
RIGHT JOIN orders o ON u.user_id = o.user_id
WHERE u.user_id IS NULL OR o.order_id = 107;

-- ============================================
-- 4. FULL OUTER JOIN (ПОЛНОЕ СОЕДИНЕНИЕ)
-- ============================================
-- В MySQL используем комбинацию LEFT + RIGHT JOIN
SELECT 
    COALESCE(u.username, '[НЕТ ПОЛЬЗОВАТЕЛЯ]') as username,
    COALESCE(o.order_id::VARCHAR, '[НЕТ ЗАКАЗОВ]') as order_info
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id

UNION

SELECT 
    COALESCE(u.username, '[НЕТ ПОЛЬЗОВАТЕЛЯ]') as username,
    COALESCE(o.order_id::VARCHAR, '[НЕТ ЗАКАЗОВ]') as order_info
FROM users u
RIGHT JOIN orders o ON u.user_id = o.user_id
WHERE u.user_id IS NULL;

-- ============================================
-- 5. SELF JOIN (САМОСОЕДИНЕНИЕ)
-- ============================================
-- Пример: находим пользователей, зарегистрированных в один день
SELECT 
    a.username as user_a,
    b.username as user_b,
    a.registration_date
FROM users a
INNER JOIN users b 
    ON a.registration_date = b.registration_date 
    AND a.user_id < b.user_id  -- избегаем дубликатов
ORDER BY a.registration_date;

-- ============================================
-- 6. CROSS JOIN (ДЕКАРТОВО ПРОИЗВЕДЕНИЕ)
-- ============================================
-- Все возможные комбинации (осторожно с большими таблицами!)
SELECT 
    u.username,
    p.promo_code
FROM users u
CROSS JOIN (
    SELECT 'SPRING2023' as promo_code
    UNION SELECT 'SUMMER2023'
    UNION SELECT 'WINTER2023'
) p
WHERE u.registration_date > '2023-01-01'
LIMIT 10;

-- ============================================
-- 7. СЛОЖНЫЙ JOIN С НЕСКОЛЬКИМИ ТАБЛИЦАМИ
-- ============================================
-- Создадим таблицу продуктов для демонстрации
CREATE TABLE IF NOT EXISTS order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Вставим тестовые данные
INSERT INTO order_items (item_id, order_id, product_name, quantity, price) VALUES
    (1, 101, 'Ноутбук', 1, 1299.99),
    (2, 101, 'Мышка', 1, 49.99),
    (3, 102, 'Монитор', 1, 299.50),
    (4, 103, 'Клавиатура', 1, 89.99);

-- Запрос с несколькими JOIN (как в оптимизированном примере из статьи)
SELECT 
    u.username,
    o.order_date,
    oi.product_name,
    oi.quantity,
    oi.price,
    (oi.quantity * oi.price) as item_total
FROM users u
INNER JOIN orders o ON u.user_id = o.user_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
ORDER BY o.order_date DESC, u.username;

-- ============================================
-- 8. ПРАКТИЧЕСКИЙ КЕЙС 
-- ============================================
-- Оптимизация "монструозного запроса"
-- Исходная проблема: анализ продаж с множеством подзапросов
-- Решение: использование JOIN и правильной агрегации

-- ПЛОХО: множество подзапросов (старая версия)
-- ХОРОШО: один эффективный запрос с JOIN (новая версия)
SELECT 
    u.username,
    u.registration_date,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(oi.item_id) as total_items,
    SUM(oi.quantity * oi.price) as total_revenue,
    AVG(o.total_amount) as avg_order_value
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE u.registration_date BETWEEN '2023-01-01' AND '2023-04-30'
GROUP BY u.user_id, u.username, u.registration_date
HAVING COUNT(o.order_id) > 0
ORDER BY total_revenue DESC;

-- ============================================
-- КОММЕНТАРИИ ДЛЯ ПОРТФОЛИО:
-- ============================================
/*
ЧТО ЭТОТ ФАЙЛ ДЕМОНСТРИРУЕТ:

1. Все типы JOIN операций
2. Реальный кейс из статьи (оптимизация запроса)
3. Работу с несколькими связанными таблицами
4. Практическое применение агрегатных функций
5. Решение бизнес-задач (анализ продаж)

НАВЫКИ:
- Понимание разницы между INNER, LEFT, RIGHT, FULL JOIN
- Умение оптимизировать сложные запросы
- Работа с иерархией данных
- Решение реальных аналитических задач
*/
