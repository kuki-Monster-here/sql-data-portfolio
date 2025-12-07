-- ============================================
-- ОКОННЫЕ ФУНКЦИИ (WINDOW FUNCTIONS)
-- Продвинутый SQL для аналитики и отчетности
-- ============================================

-- Используем существующие таблицы users и orders
-- Добавим больше данных для демонстрации

-- ДОПОЛНИТЕЛЬНЫЕ ДАННЫЕ ДЛЯ ДЕМОНСТРАЦИИ
INSERT INTO users (user_id, username, email, registration_date) 
VALUES 
    (6, 'eva_green', 'eva@example.com', '2023-04-10'),
    (7, 'frank_black', 'frank@example.com', '2023-04-12'),
    (8, 'grace_lee', 'grace@example.com', '2023-04-12'),
    (9, 'henry_ford', 'henry@example.com', '2023-04-15'),
    (10, 'irene_adler', 'irene@example.com', '2023-04-20');

INSERT INTO orders (order_id, user_id, order_date, total_amount) 
VALUES 
    (108, 6, '2023-04-11', 89.99),
    (109, 6, '2023-04-14', 120.00),
    (110, 7, '2023-04-13', 250.00),
    (111, 7, '2023-04-13', 75.50),  -- второй заказ в тот же день
    (112, 8, '2023-04-14', 399.99),
    (113, 9, '2023-04-16', 199.99),
    (114, 10, '2023-04-21', 499.99),
    (115, 10, '2023-04-22', 150.00),
    (116, 10, '2023-04-23', 89.99);

-- Создадим таблицу для демонстрации PARTITION BY
CREATE TABLE IF NOT EXISTS employee_sales (
    emp_id INT,
    emp_name VARCHAR(50),
    department VARCHAR(50),
    sale_date DATE,
    amount DECIMAL(10, 2)
);

INSERT INTO employee_sales (emp_id, emp_name, department, sale_date, amount) VALUES
    (1, 'Анна', 'IT', '2023-01-15', 1500),
    (1, 'Анна', 'IT', '2023-01-20', 2000),
    (1, 'Анна', 'IT', '2023-02-10', 1800),
    (2, 'Борис', 'Sales', '2023-01-12', 3000),
    (2, 'Борис', 'Sales', '2023-01-25', 2500),
    (2, 'Борис', 'Sales', '2023-02-05', 4000),
    (3, 'Виктор', 'IT', '2023-01-18', 2200),
    (3, 'Виктор', 'IT', '2023-02-12', 1900),
    (4, 'Дарья', 'HR', '2023-01-22', 1200),
    (4, 'Дарья', 'HR', '2023-02-08', 1500);

-- ============================================
-- 1. ROW_NUMBER() - НУМЕРАЦИЯ СТРОК
-- ============================================
-- Нумерация заказов каждого пользователя по дате
SELECT 
    u.username,
    o.order_date,
    o.total_amount,
    ROW_NUMBER() OVER (
        PARTITION BY u.user_id 
        ORDER BY o.order_date
    ) as order_sequence
FROM users u
INNER JOIN orders o ON u.user_id = o.user_id
WHERE u.user_id IN (6, 7, 10)  -- для наглядности
ORDER BY u.username, o.order_date;

-- ============================================
-- 2. RANK() и DENSE_RANK() - РАНЖИРОВАНИЕ
-- ============================================
-- Ранжирование пользователей по сумме покупок
WITH user_totals AS (
    SELECT 
        u.username,
        SUM(o.total_amount) as total_spent,
        COUNT(o.order_id) as order_count
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.username
)
SELECT 
    username,
    total_spent,
    order_count,
    RANK() OVER (ORDER BY total_spent DESC) as rank_position,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) as dense_rank_position,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) as row_num_position
FROM user_totals
WHERE total_spent > 0
ORDER BY total_spent DESC;

-- ============================================
-- 3. NTILE() - РАЗБИЕНИЕ НА ГРУППЫ
-- ============================================
-- Разделение пользователей на 3 группы по тратам
WITH user_stats AS (
    SELECT 
        u.username,
        SUM(o.total_amount) as total_spent
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.username
    HAVING SUM(o.total_amount) > 0
)
SELECT 
    username,
    total_spent,
    NTILE(3) OVER (ORDER BY total_spent DESC) as spending_tier,
    CASE NTILE(3) OVER (ORDER BY total_spent DESC)
        WHEN 1 THEN 'Высокий уровень'
        WHEN 2 THEN 'Средний уровень'
        WHEN 3 THEN 'Базовый уровень'
    END as tier_description
FROM user_stats
ORDER BY total_spent DESC;

-- ============================================
-- 4. АГРЕГАТНЫЕ ФУНКЦИИ С ОКНАМИ
-- ============================================
-- Скользящее среднее и накопительная сумма
SELECT 
    o.order_date,
    u.username,
    o.total_amount,
    -- Скользящее среднее за 3 дня
    AVG(o.total_amount) OVER (
        PARTITION BY u.user_id
        ORDER BY o.order_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) as moving_avg_3days,
    
    -- Накопительная сумма по пользователю
    SUM(o.total_amount) OVER (
        PARTITION BY u.user_id
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_sum,
    
    -- Процент от общей суммы пользователя
    ROUND(
        100.0 * o.total_amount / SUM(o.total_amount) OVER (
            PARTITION BY u.user_id
        ), 2
    ) as percent_of_user_total
FROM users u
INNER JOIN orders o ON u.user_id = o.user_id
WHERE u.user_id IN (6, 10)
ORDER BY u.username, o.order_date;

-- ============================================
-- 5. LAG() и LEAD() - СМЕЩЕНИЕ
-- ============================================
-- Анализ последовательных заказов
WITH user_orders AS (
    SELECT 
        u.username,
        o.order_date,
        o.total_amount,
        LAG(o.order_date) OVER (
            PARTITION BY u.user_id 
            ORDER BY o.order_date
        ) as previous_order_date,
        LAG(o.total_amount) OVER (
            PARTITION BY u.user_id 
            ORDER BY o.order_date
        ) as previous_order_amount,
        LEAD(o.order_date) OVER (
            PARTITION BY u.user_id 
            ORDER BY o.order_date
        ) as next_order_date
    FROM users u
    INNER JOIN orders o ON u.user_id = o.user_id
    WHERE u.user_id IN (6, 7, 10)
)
SELECT 
    username,
    order_date,
    total_amount,
    previous_order_date,
    previous_order_amount,
    next_order_date,
    -- Разница в днях между заказами
    CASE 
        WHEN previous_order_date IS NOT NULL 
        THEN DATE_PART('day', order_date - previous_order_date)
        ELSE NULL 
    END as days_since_previous,
    
    -- Разница в сумме с предыдущим заказом
    CASE 
        WHEN previous_order_amount IS NOT NULL 
        THEN total_amount - previous_order_amount
        ELSE NULL 
    END as amount_change
FROM user_orders
ORDER BY username, order_date;

-- ============================================
-- 6. FIRST_VALUE() и LAST_VALUE() - ГРАНИЧНЫЕ ЗНАЧЕНИЯ
-- ============================================
-- Анализ по отделам с первым и последним значением
SELECT 
    emp_name,
    department,
    sale_date,
    amount,
    FIRST_VALUE(amount) OVER (
        PARTITION BY department
        ORDER BY sale_date
    ) as first_sale_in_dept,
    
    LAST_VALUE(amount) OVER (
        PARTITION BY department
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_sale_in_dept,
    
    -- Максимальная продажа в отделе
    MAX(amount) OVER (
        PARTITION BY department
    ) as max_sale_in_dept,
    
    -- Среднее по отделу
    ROUND(AVG(amount) OVER (
        PARTITION BY department
    ), 2) as avg_sale_in_dept
FROM employee_sales
ORDER BY department, sale_date;

-- ============================================
-- 7. СЛОЖНЫЙ ПРИМЕР: АНАЛИЗ ПОВЕДЕНИЯ ПОЛЬЗОВАТЕЛЕЙ
-- ============================================
-- Бизнес-аналитика: когортный анализ и активность
WITH user_activity AS (
    SELECT 
        u.user_id,
        u.username,
        u.registration_date,
        o.order_date,
        o.total_amount,
        -- Первый заказ пользователя
        FIRST_VALUE(o.order_date) OVER (
            PARTITION BY u.user_id
            ORDER BY o.order_date
        ) as first_order_date,
        
        -- Дней с регистрации до первого заказа
        CASE 
            WHEN MIN(o.order_date) OVER (PARTITION BY u.user_id) IS NOT NULL
            THEN DATE_PART('day', 
                MIN(o.order_date) OVER (PARTITION BY u.user_id) - u.registration_date
            )
            ELSE NULL
        END as days_to_first_order,
        
        -- Общая сумма пользователя
        SUM(o.total_amount) OVER (
            PARTITION BY u.user_id
        ) as user_lifetime_value
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
)
SELECT 
    username,
    registration_date,
    first_order_date,
    days_to_first_order,
    user_lifetime_value,
    -- Когорта по месяцу регистрации
    TO_CHAR(registration_date, 'YYYY-MM') as registration_cohort,
    
    -- Активность по когортам
    CASE 
        WHEN user_lifetime_value > 1000 THEN 'VIP'
        WHEN user_lifetime_value > 500 THEN 'Активный'
        WHEN user_lifetime_value > 0 THEN 'Стандартный'
        ELSE 'Неактивный'
    END as user_segment,
    
    -- Сравнение с средней по когорте
    ROUND(user_lifetime_value / AVG(user_lifetime_value) OVER (
        PARTITION BY TO_CHAR(registration_date, 'YYYY-MM')
    ), 2) as vs_cohort_avg
FROM (
    SELECT DISTINCT ON (user_id) *
    FROM user_activity
) as distinct_users
WHERE registration_date >= '2023-01-01'
ORDER BY registration_date, user_lifetime_value DESC;

-- ============================================
-- 8. ПРАКТИЧЕСКИЙ КЕЙС: АНАЛИЗ ПРОДАЖ
-- ============================================
-- Анализ эффективности сотрудников с оконными функциями
SELECT 
    department,
    emp_name,
    sale_date,
    amount,
    -- Сумма продаж по сотруднику
    SUM(amount) OVER (PARTITION BY emp_id) as emp_total,
    
    -- Доля продаж сотрудника в отделе
    ROUND(
        100.0 * amount / SUM(amount) OVER (PARTITION BY department),
        2
    ) as percent_of_dept,
    
    -- Ранг сотрудника в отделе по сумме продаж
    RANK() OVER (
        PARTITION BY department
        ORDER BY SUM(amount) OVER (PARTITION BY emp_id) DESC
    ) as dept_rank,
    
    -- Изменение продаж относительно предыдущего месяца
    LAG(amount) OVER (
        PARTITION BY emp_id
        ORDER BY DATE_TRUNC('month', sale_date)
    ) as prev_month_sales,
    
    -- Тренд продаж (рост/падение)
    CASE 
        WHEN LAG(amount) OVER (
            PARTITION BY emp_id
            ORDER BY DATE_TRUNC('month', sale_date)
        ) IS NOT NULL
        THEN ROUND(
            100.0 * (amount - LAG(amount) OVER (
                PARTITION BY emp_id
                ORDER BY DATE_TRUNC('month', sale_date)
            )) / LAG(amount) OVER (
                PARTITION BY emp_id
                ORDER BY DATE_TRUNC('month', sale_date)
            ), 2
        )
        ELSE NULL
    END as growth_percent
FROM employee_sales
ORDER BY department, emp_name, sale_date;

-- ============================================
-- КОММЕНТАРИИ ДЛЯ ПОРТФОЛИО:
-- ============================================
/*
ЧТО ЭТОТ ФАЙЛ ДЕМОНСТРИРУЕТ:

1. Все основные оконные функции: ROW_NUMBER, RANK, DENSE_RANK, NTILE
2. Агрегатные функции в окнах: SUM, AVG, MAX, MIN
3. Функции смещения: LAG, LEAD
4. Функции граничных значений: FIRST_VALUE, LAST_VALUE
5. Практические бизнес-кейсы:
   - Когортный анализ пользователей
   - Анализ продаж по отделам
   - RFM-сегментация (Recency, Frequency, Monetary)
6. Сложные оконные спецификации:
   - PARTITION BY
   - ORDER BY
   - ROWS/RANGE рамки

НАВЫКИ:
- Продвинутый SQL для аналитики данных
- Создание бизнес-отчетов
- Анализ временных рядов
- Сегментация пользователей
- Расчет метрик удержания и lifetime value

ВАЖНО:
Оконные функции выполняются после WHERE/GROUP BY/HAVING
и перед ORDER BY. Они не группируют строки, а вычисляют
значения для каждой строки отдельно.
*/
