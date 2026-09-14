-- ================================================
-- Create backend application user and grant access
-- ================================================

CREATE USER IF NOT EXISTS 'ecommerce_user'@'%' IDENTIFIED BY 'hello123@';
ALTER USER 'ecommerce_user'@'%' IDENTIFIED BY 'hello123@';
GRANT ALL PRIVILEGES ON ecommerce_store.* TO 'ecommerce_user'@'%';
FLUSH PRIVILEGES;
