-- Stocks: Contains information about each stock.
-- Transactions: Records each buy or sell transaction.
-- Market Data: Daily market data for each stock.
-- Performance Metrics: To store calculated performance metrics of the trades.
  
-- Create Stocks table
CREATE TABLE Stocks (
    stock_id INT PRIMARY KEY,
    symbol VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL
);

-- Create Transactions table
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    stock_id INT,
    type VARCHAR(4),  -- 'BUY' or 'SELL'
    quantity INT,
    price DECIMAL(10, 2),
    transaction_date DATE,
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id)
);

-- Create Market Data table
CREATE TABLE MarketData (
    market_data_id INT PRIMARY KEY,
    stock_id INT,
    open_price DECIMAL(10, 2),
    close_price DECIMAL(10, 2),
    high_price DECIMAL(10, 2),
    low_price DECIMAL(10, 2),
    volume BIGINT,
    data_date DATE,
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id)
);

-- Create Performance Metrics table
CREATE TABLE PerformanceMetrics (
    metric_id INT PRIMARY KEY,
    stock_id INT,
    average_buy_price DECIMAL(10, 2),
    average_sell_price DECIMAL(10, 2),
    net_profit DECIMAL(10, 2),
    FOREIGN KEY (stock_id) REFERENCES Stocks(stock_id)
);
