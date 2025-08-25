-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES categories(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id),
    base_price DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Product inventory
CREATE TABLE IF NOT EXISTS product_inventory (
    product_id UUID PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
    quantity_available INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 10,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_inventory_availability ON product_inventory(quantity_available);

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Books', 'Books and educational materials'),
('Clothing', 'Apparel and accessories')
ON CONFLICT DO NOTHING;

-- Insert sample products
WITH category_electronics AS (
    SELECT id FROM categories WHERE name = 'Electronics' LIMIT 1
)
INSERT INTO products (sku, name, description, category_id, base_price) 
SELECT 'LAPTOP-001', 'Gaming Laptop', 'High-performance gaming laptop', id, 1299.99 FROM category_electronics
UNION ALL
SELECT 'PHONE-001', 'Smartphone Pro', 'Latest flagship smartphone', id, 899.99 FROM category_electronics
ON CONFLICT (sku) DO NOTHING;

-- Insert inventory for sample products
INSERT INTO product_inventory (product_id, quantity_available, low_stock_threshold)
SELECT id, 50, 10 FROM products WHERE sku IN ('LAPTOP-001', 'PHONE-001')
ON CONFLICT (product_id) DO NOTHING;