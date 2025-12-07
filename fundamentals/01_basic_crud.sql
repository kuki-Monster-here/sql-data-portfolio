-- ============================================
-- ОСНОВНЫЕ CRUD-ОПЕРАЦИИ (Create, Read, Update, Delete)
-- Вдохновлено статьей о фундаментальных навыках работы с базами данных
-- ============================================

-- 1. СОЗДАНИЕ ТАБЛИЦ (CREATE)
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    registration_date DATE
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 2. ВСТАВКА ДАННЫХ (INSERT)
INSERT INTO users (user_id, username, email, registration_date) 
VALUES 
    (1, 'john_doe', 'john@example.com', '2023-01-15'),
    (2, 'alice_smith', 'alice@example.com', '2023-02-20');

INSERT INTO orders (order_id, user_id, order_date, total_amount) 
VALUES 
    (101, 1, '2023-01-20', 149.99),
    (102, 2, '2023-02-25', 299.50);

-- 3. ЧТЕНИЕ ДАННЫХ (SELECT)
-- Простой выбор
SELECT * FROM users;

-- Выборка с условием
SELECT username, email 
FROM users 
WHERE registration_date >= '2023-02-01';

-- Агрегация с JOIN
SELECT 
    u.username,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id;

-- 4. ОБНОВЛЕНИЕ ДАННЫХ (UPDATE)
UPDATE users 
SET email = 'john.new@example.com' 
WHERE user_id = 1;

-- 5. УДАЛЕНИЕ ДАННЫХ (DELETE)
DELETE FROM orders 
WHERE order_date < '2023-02-01';
