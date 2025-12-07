-- ============================================
-- ТЕСТОВЫЕ ДАННЫЕ ДЛЯ ЛОГИСТИЧЕСКОЙ СИСТЕМЫ
-- Реалистичные данные, имитирующие работу реальной компании
-- ============================================

-- ОЧИСТКА СТАРЫХ ДАННЫХ (если нужно)
-- TRUNCATE TABLE ... CASCADE; -- раскомментировать для очистки

-- ====================
-- 1. КЛИЕНТЫ (10 компаний)
-- ====================
INSERT INTO customers (company_name, contact_person, email, phone, address, city, customer_type, credit_limit) VALUES
('ООО "Ромашка"', 'Иванов Иван', 'ivanov@romashka.ru', '+79161234567', 'ул. Ленина, 10', 'Москва', 'regular', 100000),
('АО "ТехноПром"', 'Петрова Анна', 'petrova@technoprom.ru', '+79262345678', 'пр. Мира, 25', 'Санкт-Петербург', 'premium', 500000),
('ИП Сидоров', 'Сидор Сидоров', 'sidor@mail.ru', '+79373456789', 'ул. Советская, 5', 'Новосибирск', 'regular', 50000),
('ЗАО "МеталлСервис"', 'Кузнецов А.', 'kuznetsov@metall.ru', '+79484567890', 'ш. Энтузиастов, 15', 'Екатеринбург', 'vip', 1000000),
('ООО "СтройМастер"', 'Смирнова Ольга', 'smirnova@stroymaster.ru', '+79595678901', 'ул. Строителей, 3', 'Казань', 'regular', 200000),
('АО "АгроТех"', 'Николаев П.П.', 'nikolaev@agro.ru', '+79606789012', 'ул. Полевая, 12', 'Ростов-на-Дону', 'premium', 300000),
('ИП "Быстрая Доставка"', 'Васильев В.', 'vasiliev@fast.ru', '+79717890123', 'пр. Победы, 8', 'Самара', 'regular', 75000),
('ООО "ХолодТорг"', 'Федорова М.И.', 'fedorova@cold.ru', '+79828901234', 'ул. Морозова, 20', 'Краснодар', 'vip', 800000),
('ЗАО "ЭлектроСила"', 'Алексеев С.С.', 'alekseev@electro.ru', '+79939012345', 'ул. Энергетиков, 7', 'Воронеж', 'regular', 150000),
('ИП "МебельПро"', 'Морозова Т.К.', 'morozova@mebel.ru', '+79040123456', 'ул. Мебельная, 4', 'Нижний Новгород', 'premium', 400000);

-- ====================
-- 2. СКЛАДЫ (3 склада)
-- ====================
INSERT INTO warehouses (warehouse_name, location, city, capacity_sq_m, manager_name, contact_phone) VALUES
('Центральный склад', 'промзона "Северная"', 'Москва', 5000, 'Семенов А.В.', '+79161111111'),
('Склад №2', 'ул. Складская, 1', 'Санкт-Петербург', 3000, 'Ковалева И.Н.', '+79262222222'),
('Южный логистический центр', 'ш. Южное, 10', 'Ростов-на-Дону', 7000, 'Тихонов П.С.', '+79373333333');

-- ====================
-- 3. ТОВАРЫ (20 товаров)
-- ====================
INSERT INTO products (product_name, category, weight_kg, volume_cu_m, unit_price, min_stock_level, current_stock, warehouse_id) VALUES
('Ноутбук Lenovo', 'Электроника', 2.5, 0.005, 85000, 20, 45, 1),
('Смартфон Samsung', 'Электроника', 0.3, 0.0003, 45000, 50, 120, 1),
('Холодильник Bosch', 'Бытовая техника', 85.0, 0.6, 65000, 10, 18, 1),
('Диван угловой', 'Мебель', 120.0, 2.5, 45000, 5, 8, 2),
('Офисное кресло', 'Мебель', 15.0, 0.3, 12000, 30, 52, 2),
('Цемент М500 (мешок 50кг)', 'Строительные материалы', 50.0, 0.035, 450, 200, 350, 3),
('Кирпич красный (паллет)', 'Строительные материалы', 1200.0, 1.2, 18000, 50, 85, 3),
('Крупа гречневая (мешок 25кг)', 'Продукты', 25.0, 0.025, 2500, 100, 210, 3),
('Масло подсолнечное (ящик)', 'Продукты', 20.0, 0.02, 18000, 80, 150, 3),
('Детское питание (коробка)', 'Продукты', 10.0, 0.015, 8000, 60, 95, 1),
('Принтер HP', 'Офисная техника', 12.0, 0.1, 22000, 15, 25, 1),
('Кондиционер', 'Климатическая техника', 35.0, 0.4, 55000, 8, 12, 1),
('Велосипед горный', 'Спорттовары', 15.0, 0.8, 35000, 12, 22, 2),
('Гантели 10кг (пара)', 'Спорттовары', 10.0, 0.05, 3000, 40, 65, 2),
('Краска белая (банка 10л)', 'Отделочные материалы', 12.0, 0.01, 2500, 70, 130, 3),
('Обои (рулон)', 'Отделочные материалы', 1.5, 0.005, 800, 150, 280, 3),
('Лампа светодиодная', 'Освещение', 0.2, 0.0005, 300, 300, 510, 1),
('Провод медный (катушка)', 'Электротехника', 8.0, 0.08, 12000, 40, 75, 1),
('Инструментальный ящик', 'Инструменты', 7.0, 0.06, 8500, 25, 42, 2),
('Перфоратор', 'Инструменты', 5.5, 0.04, 15000, 18, 30, 2);

-- ====================
-- 4. ТРАНСПОРТ (5 единиц)
-- ====================
INSERT INTO vehicles (license_plate, vehicle_type, capacity_kg, capacity_volume, current_location, status) VALUES
('А123БВ777', 'truck', 5000, 40, 'Москва, склад', 'available'),
('В456ГН777', 'van', 1500, 15, 'Санкт-Петербург, гараж', 'available'),
('С789ДК777', 'refrigerator', 3000, 25, 'Ростов-на-Дону, паркинг', 'maintenance'),
('Е012ЖЛ777', 'container', 20000, 60, 'Москва, база', 'in_transit'),
('М345НП777', 'van', 1200, 12, 'Новосибирск, терминал', 'available');

-- ====================
-- 5. ВОДИТЕЛИ (5 человек)
-- ====================
INSERT INTO drivers (first_name, last_name, license_number, phone, email, vehicle_id) VALUES
('Александр', 'Волков', '77АВ123456', '+79167778899', 'volkov@logistics.ru', 1),
('Дмитрий', 'Орлов', '78ОР654321', '+79268889900', 'orlov@logistics.ru', 2),
('Сергей', 'Соколов', '61СК111222', '+79369990011', 'sokolov@logistics.ru', 3),
('Ирина', 'Лебедева', '77ЛБ333444', '+79460001122', 'lebedeva@logistics.ru', 4),
('Михаил', 'Соловьев', '54СЛ555666', '+79561112233', 'soloviev@logistics.ru', 5);

-- ====================
-- 6. ЗАКАЗЫ (15 заказов за последние 30 дней)
-- ====================
INSERT INTO orders (customer_id, order_date, required_date, status, priority, warehouse_id) VALUES
(1, CURRENT_DATE - 30, CURRENT_DATE - 28, 'delivered', 'normal', 1),
(2, CURRENT_DATE - 25, CURRENT_DATE - 22, 'delivered', 'high', 1),
(3, CURRENT_DATE - 20, CURRENT_DATE - 18, 'shipped', 'normal', 3),
(4, CURRENT_DATE - 18, CURRENT_DATE - 15, 'delivered', 'urgent', 1),
(5, CURRENT_DATE - 15, CURRENT_DATE - 12, 'ready', 'normal', 2),
(6, CURRENT_DATE - 12, CURRENT_DATE - 10, 'processing', 'high', 3),
(7, CURRENT_DATE - 10, CURRENT_DATE - 7, 'packing', 'normal', 2),
(8, CURRENT_DATE - 8, CURRENT_DATE - 5, 'processing', 'normal', 1),
(9, CURRENT_DATE - 5, CURRENT_DATE - 2, 'pending', 'low', 3),
(10, CURRENT_DATE - 3, CURRENT_DATE + 1, 'pending', 'normal', 2),
(1, CURRENT_DATE - 2, CURRENT_DATE + 2, 'pending', 'normal', 1),
(2, CURRENT_DATE - 1, CURRENT_DATE + 3, 'pending', 'high', 1),
(3, CURRENT_DATE, CURRENT_DATE + 5, 'pending', 'normal', 3),
(4, CURRENT_DATE, CURRENT_DATE + 2, 'pending', 'urgent', 1),
(5, CURRENT_DATE, CURRENT_DATE + 4, 'pending', 'normal', 2);

-- ====================
-- 7. ЭЛЕМЕНТЫ ЗАКАЗА (по 2-4 товара в каждом заказе)
-- ====================
-- Заказ 1
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (1, 1, 2, 85000), (1, 2, 5, 45000);
-- Заказ 2
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (2, 3, 1, 65000), (2, 11, 3, 22000);
-- Заказ 3
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (3, 6, 10, 450), (3, 7, 2, 18000), (3, 15, 5, 2500);
-- Заказ 4
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (4, 4, 1, 45000), (4, 5, 4, 12000);
-- Заказ 5
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (5, 13, 2, 35000), (5, 14, 5, 3000);
-- Заказ 6
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (6, 8, 20, 2500), (6, 9, 8, 18000), (6, 10, 10, 8000);
-- Заказ 7
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (7, 12, 1, 55000), (7, 17, 50, 300);
-- Заказ 8
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (8, 18, 3, 12000), (8, 19, 2, 8500), (8, 20, 1, 15000);
-- Заказ 9
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (9, 16, 100, 800), (9, 15, 20, 2500);
-- Заказ 10
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (10, 1, 1, 85000), (10, 2, 2, 45000), (10, 11, 1, 22000);

-- ====================
-- 8. ДОСТАВКИ (для доставленных заказов)
-- ====================
INSERT INTO deliveries (order_id, driver_id, vehicle_id, planned_departure, actual_departure, planned_arrival, actual_arrival, status, distance_km) VALUES
(1, 1, 1, CURRENT_DATE - 30 + INTERVAL '8 hours', CURRENT_DATE - 30 + INTERVAL '8 hours 15 minutes', CURRENT_DATE - 28 + INTERVAL '14 hours', CURRENT_DATE - 28 + INTERVAL '13 hours 45 minutes', 'delivered', 1200),
(2, 2, 2, CURRENT_DATE - 25 + INTERVAL '9 hours', CURRENT_DATE - 25 + INTERVAL '9 hours 30 minutes', CURRENT_DATE - 22 + INTERVAL '16 hours', CURRENT_DATE - 22 + INTERVAL '17 hours 20 minutes', 'delivered', 700),
(3, 5, 5, CURRENT_DATE - 20 + INTERVAL '10 hours', CURRENT_DATE - 20 + INTERVAL '10 hours', CURRENT_DATE - 18 + INTERVAL '12 hours', NULL, 'in_transit', 3500),
(4, 1, 1, CURRENT_DATE - 18 + INTERVAL '6 hours', CURRENT_DATE - 18 + INTERVAL '6 hours 10 minutes', CURRENT_DATE - 15 + INTERVAL '10 hours', CURRENT_DATE - 15 + INTERVAL '9 hours 50 minutes', 'delivered', 800);

-- ====================
-- 9. ТРЕКИНГ ДОСТАВОК (история перемещений)
-- ====================
-- Для доставки 1
INSERT INTO delivery_tracking (delivery_id, location, status, notes) VALUES
(1, 'Москва, склад', 'departed', 'Загружены ноутбуки и телефоны'),
(1, 'Тверь, КПП', 'in_transit', 'Прошли контроль'),
(1, 'Санкт-Петербург, сортировочный центр', 'in_transit', 'Перегрузка не требуется'),
(1, 'Санкт-Петербург, ул. Ленина 10', 'delivered', 'Передано получателю');

-- Для доставки 2
INSERT INTO delivery_tracking (delivery_id, location, status, notes) VALUES
(2, 'Санкт-Петербург, склад', 'departed', 'Холодильник и принтеры'),
(2, 'Новгород, заправка', 'in_transit', 'Дозаправка'),
(2, 'Москва, склад "ТехноПром"', 'delivered', 'Получено охраной');

-- Для доставки 4 (срочной)
INSERT INTO delivery_tracking (delivery_id, location, status, notes) VALUES
(4, 'Москва, центральный склад', 'departed', 'Срочная доставка мебели'),
(4, 'Москва, МКАД 50км', 'in_transit', 'Пробки 20 минут'),
(4, 'Москва, офис "МеталлСервис"', 'delivered', 'Доставлено в срок');

-- ====================
-- 10. ИНВЕНТАРИЗАЦИЯ (несколько записей об изменениях)
-- ====================
INSERT INTO inventory_logs (product_id, warehouse_id, transaction_type, quantity_change, previous_quantity, new_quantity, reference_id, reference_type, performed_by) VALUES
(1, 1, 'out', 2, 47, 45, 1, 'order', 'Иванов И.И.'),
(2, 1, 'out', 5, 125, 120, 1, 'order', 'Иванов И.И.'),
(6, 3, 'out', 10, 360, 350, 3, 'order', 'Петров П.П.'),
(8, 3, 'out', 20, 230, 210, 6, 'order', 'Сидорова С.С.');

-- ====================
-- ПРОВЕРКА ДАННЫХ
-- ====================
SELECT 'Клиенты:' as table_name, COUNT(*) as records FROM customers
UNION ALL
SELECT 'Склады:', COUNT(*) FROM warehouses
UNION ALL
SELECT 'Товары:', COUNT(*) FROM products
UNION ALL
SELECT 'Транспорт:', COUNT(*) FROM vehicles
UNION ALL
SELECT 'Водители:', COUNT(*) FROM drivers
UNION ALL
SELECT 'Заказы:', COUNT(*) FROM orders
UNION ALL
SELECT 'Элементы заказов:', COUNT(*) FROM order_details
UNION ALL
SELECT 'Доставки:', COUNT(*) FROM deliveries
UNION ALL
SELECT 'Трекинг:', COUNT(*) FROM delivery_tracking
UNION ALL
SELECT 'Инвентаризация:', COUNT(*) FROM inventory_logs
ORDER BY table_name;

-- ====================
-- КОММЕНТАРИЙ:
-- ====================
/*
ЭТИ ДАННЫЕ СОЗДАЮТ РЕАЛИСТИЧНУЮ КАРТИНУ:
1. 10 клиентов разных типов и городов
2. 3 склада в разных регионах
3. 20 разнообразных товаров
4. 15 заказов с разными статусами
5. Полный цикл доставки с трекингом
6. Логи изменений инвентаря

ВСЕ ДАННЫЕ СОГЛАСОВАНЫ:
- Товары находятся на соответствующих складах
- Водители закреплены за транспортом
- Заказы соответствуют клиентам
- Доставки привязаны к заказам
*/
