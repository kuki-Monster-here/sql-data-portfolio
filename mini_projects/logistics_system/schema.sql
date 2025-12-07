-- ============================================
-- ЛОГИСТИЧЕСКАЯ СИСТЕМА: СХЕМА БАЗЫ ДАННЫХ
-- ============================================

-- 1. КЛИЕНТЫ
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) DEFAULT 'Russia',
    registration_date DATE DEFAULT CURRENT_DATE,
    customer_type VARCHAR(20) CHECK (customer_type IN ('regular', 'premium', 'vip')),
    credit_limit DECIMAL(12, 2) DEFAULT 0
);

-- 2. СКЛАДЫ
CREATE TABLE warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    capacity_sq_m INT NOT NULL,
    current_occupancy INT DEFAULT 0,
    manager_name VARCHAR(100),
    contact_phone VARCHAR(20)
);

-- 3. ТОВАРЫ
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    weight_kg DECIMAL(10, 2) NOT NULL,
    volume_cu_m DECIMAL(10, 3) NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    min_stock_level INT DEFAULT 10,
    current_stock INT DEFAULT 0,
    warehouse_id INT REFERENCES warehouses(warehouse_id),
    last_restock_date DATE
);

-- 4. ЗАКАЗЫ
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'packing', 'ready', 'shipped', 'delivered', 'cancelled')),
    priority VARCHAR(10) DEFAULT 'normal' 
        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    total_weight DECIMAL(10, 2),
    total_volume DECIMAL(10, 3),
    total_amount DECIMAL(12, 2),
    warehouse_id INT REFERENCES warehouses(warehouse_id),
    notes TEXT
);

-- 5. ЭЛЕМЕНТЫ ЗАКАЗА
CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12, 2) NOT NULL,
    discount DECIMAL(5, 2) DEFAULT 0,
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount/100)) STORED
);

-- 6. ТРАНСПОРТ
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(30) NOT NULL 
        CHECK (vehicle_type IN ('truck', 'van', 'refrigerator', 'container')),
    capacity_kg DECIMAL(10, 2) NOT NULL,
    capacity_volume DECIMAL(10, 3) NOT NULL,
    current_location VARCHAR(100),
    status VARCHAR(20) DEFAULT 'available' 
        CHECK (status IN ('available', 'in_transit', 'maintenance', 'out_of_service')),
    last_maintenance_date DATE
);

-- 7. ВОДИТЕЛИ
CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    hire_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active' 
        CHECK (status IN ('active', 'vacation', 'sick', 'inactive')),
    vehicle_id INT REFERENCES vehicles(vehicle_id)
);

-- 8. ДОСТАВКИ
CREATE TABLE deliveries (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL UNIQUE REFERENCES orders(order_id),
    driver_id INT NOT NULL REFERENCES drivers(driver_id),
    vehicle_id INT NOT NULL REFERENCES vehicles(vehicle_id),
    planned_departure TIMESTAMP,
    actual_departure TIMESTAMP,
    planned_arrival TIMESTAMP,
    actual_arrival TIMESTAMP,
    status VARCHAR(20) DEFAULT 'scheduled' 
        CHECK (status IN ('scheduled', 'loading', 'in_transit', 'delivered', 'delayed', 'cancelled')),
    distance_km DECIMAL(8, 2),
    fuel_consumption DECIMAL(8, 2),
    delivery_notes TEXT
);

-- 9. ТРЕКИНГ ДОСТАВОК
CREATE TABLE delivery_tracking (
    tracking_id SERIAL PRIMARY KEY,
    delivery_id INT NOT NULL REFERENCES deliveries(delivery_id),
    tracking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    notes TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

-- 10. ИНВЕНТАРИЗАЦИЯ
CREATE TABLE inventory_logs (
    log_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id),
    warehouse_id INT NOT NULL REFERENCES warehouses(warehouse_id),
    transaction_type VARCHAR(10) CHECK (transaction_type IN ('in', 'out', 'adjust')),
    quantity_change INT NOT NULL,
    previous_quantity INT NOT NULL,
    new_quantity INT NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_id INT, -- order_id или delivery_id
    reference_type VARCHAR(20),
    performed_by VARCHAR(100),
    notes TEXT
);

-- ============================================
-- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ
-- ============================================

-- Индексы для частых поисков
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_status_date ON orders(status, order_date);
CREATE INDEX idx_orders_priority_date ON orders(priority, required_date);

-- Индексы для JOIN операций
CREATE INDEX idx_order_details_order ON order_details(order_id);
CREATE INDEX idx_order_details_product ON order_details(product_id);
CREATE INDEX idx_deliveries_order ON deliveries(order_id);
CREATE INDEX idx_deliveries_driver ON deliveries(driver_id);

-- Индексы для отчетов
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_customers_city ON customers(city);
CREATE INDEX idx_deliveries_status_date ON deliveries(status, planned_arrival);

-- Составные индексы для покрывающих запросов
CREATE INDEX idx_orders_covering ON orders(order_date, status, customer_id) 
    INCLUDE (total_amount);
CREATE INDEX idx_delivery_tracking_covering ON delivery_tracking(delivery_id, tracking_time) 
    INCLUDE (location, status);

-- ============================================
-- ТРИГГЕРЫ И ПРАВИЛА ЦЕЛОСТНОСТИ
-- ============================================

-- Триггер для автоматического обновления total_amount в заказе
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders 
    SET total_amount = (
        SELECT COALESCE(SUM(line_total), 0)
        FROM order_details
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_details_update
AFTER INSERT OR UPDATE OR DELETE ON order_details
FOR EACH ROW
EXECUTE FUNCTION update_order_total();

-- Триггер для обновления уровня запасов
CREATE OR REPLACE FUNCTION update_inventory()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем количество на складе
    UPDATE products 
    SET current_stock = current_stock - NEW.quantity,
        last_restock_date = CASE 
            WHEN current_stock - NEW.quantity <= min_stock_level THEN CURRENT_DATE
            ELSE last_restock_date
        END
    WHERE product_id = NEW.product_id;
    
    -- Логируем изменение инвентаря
    INSERT INTO inventory_logs (
        product_id, warehouse_id, transaction_type, 
        quantity_change, previous_quantity, new_quantity,
        reference_id, reference_type, performed_by
    )
    SELECT 
        p.product_id,
        p.warehouse_id,
        'out',
        NEW.quantity,
        p.current_stock,
        p.current_stock - NEW.quantity,
        NEW.order_id,
        'order',
        'system'
    FROM products p
    WHERE p.product_id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_details_inventory
AFTER INSERT ON order_details
FOR EACH ROW
EXECUTE FUNCTION update_inventory();

-- ============================================
-- ПРЕДСТАВЛЕНИЯ ДЛЯ ОТЧЕТОВ
-- ============================================

-- Представление для отчета по доставкам
CREATE VIEW delivery_performance AS
SELECT 
    d.delivery_id,
    o.order_id,
    c.company_name,
    dr.first_name || ' ' || dr.last_name as driver_name,
    v.vehicle_type,
    d.planned_departure,
    d.actual_departure,
    d.planned_arrival,
    d.actual_arrival,
    CASE 
        WHEN d.actual_arrival IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (d.actual_arrival - d.planned_arrival))/3600
        ELSE NULL
    END as delay_hours,
    d.distance_km,
    d.status
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN drivers dr ON d.driver_id = dr.driver_id
JOIN vehicles v ON d.vehicle_id = v.vehicle_id;

-- Представление для анализа запасов
CREATE VIEW inventory_analysis AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.current_stock,
    p.min_stock_level,
    p.current_stock - p.min_stock_level as stock_difference,
    CASE 
        WHEN p.current_stock <= p.min_stock_level THEN 'CRITICAL'
        WHEN p.current_stock <= p.min_stock_level * 1.5 THEN 'LOW'
        ELSE 'OK'
    END as stock_status,
    w.warehouse_name,
    p.last_restock_date,
    COALESCE(SUM(od.quantity), 0) as monthly_demand
FROM products p
JOIN warehouses w ON p.warehouse_id = w.warehouse_id
LEFT JOIN order_details od ON p.product_id = od.product_id
    AND od.order_id IN (
        SELECT order_id FROM orders 
        WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
    )
GROUP BY p.product_id, p.product_name, p.category, p.current_stock, 
         p.min_stock_level, w.warehouse_name, p.last_restock_date;

COMMENT ON DATABASE logistics_system IS 'Логистическая система - кейс из статьи про оптимизацию на 70%';
