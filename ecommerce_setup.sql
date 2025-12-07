-- #############################################
-- 1. DATABASE SETUP
-- #############################################

-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS ecommerce;

-- Use the newly created database
USE ecommerce;


-- #############################################
-- 2. TABLE CREATION
-- #############################################

-- Create the customers table
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    address VARCHAR(255)
);

-- Create the products table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    CHECK (price >= 0)
);

-- Create the orders table (before normalization, this had total_amount)
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    CHECK (total_amount >= 0)
);


-- #############################################
-- 3. INSERT SAMPLE DATA
-- #############################################

-- Insert sample data into the customers table
INSERT INTO customers (name, email, address) VALUES
('Alice Smith', 'alice.smith@example.com', '123 Main St'),
('Bob Johnson', 'bob.johnson@example.com', '456 Oak Ave'),
('Charlie Brown', 'charlie.brown@example.com', '789 Pine Ln'),
('Diana Prince', 'diana.prince@example.com', '101 God St');

-- Insert sample data into the products table
INSERT INTO products (name, price, description) VALUES
('Product A', 50.00, 'A great standard product.'),
('Product B', 120.50, 'A premium item.'),
('Product C', 35.00, 'An affordable essential.'),
('Product D', 200.00, 'A high-value item.');

-- Insert sample data into the orders table (Use a consistent date context, e.g., 2025-12-07 as today)
INSERT INTO orders (customer_id, order_date, total_amount) VALUES
(1, '2025-12-05', 75.00),     -- Alice (within 30 days)
(1, '2025-11-20', 160.00),    -- Alice (within 30 days)
(2, '2025-10-15', 250.75),    -- Bob (outside 30 days)
(3, '2025-11-10', 50.00),     -- Charlie (within 30 days)
(3, '2025-12-07', 170.00),    -- Charlie (today)
(4, '2025-12-01', 100.00);    -- Diana (within 30 days)


-- #############################################
-- 4. DATABASE NORMALIZATION (Adding order_items table)
-- #############################################

-- Create the order_items table to link orders and products
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    item_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    CHECK (quantity > 0),
    CHECK (item_price >= 0)
);

-- Insert sample data into order_items (to support queries like 'who bought Product A')
-- Assuming Product IDs: 1=Product A, 2=Product B, 3=Product C, 4=Product D
INSERT INTO order_items (order_id, product_id, quantity, item_price) VALUES
(1, 1, 1, 50.00),    -- Alice's Order 1: Product A
(1, 3, 1, 25.00),
(2, 2, 1, 120.50),   -- Alice's Order 2: Product B
(2, 3, 1, 39.50),
(4, 1, 1, 50.00),    -- Charlie's Order 4: Product A
(5, 4, 1, 200.00),   -- Charlie's Order 5: Product D (Note: Total amount in orders table might be slightly off)
(6, 4, 1, 100.00);   -- Diana's Order 6: Product D (for simplicity)


-- #############################################
-- 5. REQUIRED QUERIES / OPERATIONS
-- #############################################

-- Query 1: Update the price of Product C to 45.00.
UPDATE
    products
SET
    price = 45.00
WHERE
    name = 'Product C';

-- Query 2: Add a new column discount to the products table.
ALTER TABLE
    products
ADD COLUMN
    discount DECIMAL(5, 2) DEFAULT 0.00;

-- Query 3: Retrieve all customers who have placed an order in the last 30 days.
SELECT DISTINCT
    c.name,
    c.email
FROM
    customers c
JOIN
    orders o ON c.id = o.customer_id
WHERE
    o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- Query 4: Get the total amount of all orders placed by each customer.
SELECT
    c.name,
    SUM(o.total_amount) AS total_spent
FROM
    customers c
JOIN
    orders o ON c.id = o.customer_id
GROUP BY
    c.name
ORDER BY
    total_spent DESC;

-- Query 5: Retrieve the top 3 products with the highest price.
SELECT
    name,
    price
FROM
    products
ORDER BY
    price DESC
LIMIT 3;

-- Query 6: Get the names of customers who have ordered Product A (Requires order_items data).
SELECT DISTINCT
    c.name
FROM
    customers c
JOIN
    orders o ON c.id = o.customer_id
JOIN
    order_items oi ON o.id = oi.order_id
JOIN
    products p ON oi.product_id = p.id
WHERE
    p.name = 'Product A';

-- Query 7: Join the orders and customers tables to retrieve the customer's name and order date for each order.
SELECT
    o.id AS order_id,
    c.name AS customer_name,
    o.order_date
FROM
    orders o
JOIN
    customers c ON o.customer_id = c.id
ORDER BY
    o.order_date DESC;

-- Query 8: Retrieve the orders with a total amount greater than 150.00.
SELECT
    *
FROM
    orders
WHERE
    total_amount > 150.00;

-- Query 9: Retrieve the average total of all orders.
SELECT
    AVG(total_amount) AS average_order_total
FROM
    orders;