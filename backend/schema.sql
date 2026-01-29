-- Create Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE,
    name VARCHAR(100),
    email VARCHAR(100),
    profile_image_url TEXT,
    password VARCHAR(255), -- Optional for phone login, mandatory if email used
    role VARCHAR(10) DEFAULT 'user', -- 'user' or 'admin'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Products Table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    discount INTEGER DEFAULT 0,
    description TEXT,
    sizes JSONB, -- Array of strings e.g. ["S", "M"]
    colors JSONB, -- Array of strings
    image_urls JSONB, -- Array of strings
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Confirmed', -- Confirmed, Packed, Shipped, Delivered
    payment_method VARCHAR(50), -- COD, UPI
    transaction_id VARCHAR(100), -- For UPI
    tracking_id VARCHAR(100),
    tracking_slip_url TEXT,
    items JSONB NOT NULL, -- Snapshot of items ordered: [{productId, name, price, quantity, size}]
    shipping_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Chats Table
CREATE TABLE IF NOT EXISTS chats (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    admin_id INTEGER REFERENCES users(id), -- Optional, whoever picked it up
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Messages Table
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER REFERENCES chats(id),
    sender_role VARCHAR(10) NOT NULL, -- 'user' or 'admin'
    message_text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed Initial Admin (Password: password123)
-- In production, passwords must be hashed. This is a placeholder insert.
INSERT INTO users (phone, email, password, role) 
VALUES ('9876543210', 'admin@boutique.com', '$2b$10$YourHashedPasswordHere', 'admin')
ON CONFLICT (phone) DO NOTHING;
