-- Calculate average buy and sell prices 
INSERT INTO PerformanceMetrics (metric_id, stock_id, average_buy_price, average_sell_price, net_profit)
SELECT 1, stock_id, AVG(CASE WHEN type = 'BUY' THEN price END), AVG(CASE WHEN type = 'SELL' THEN price END), SUM(CASE WHEN type = 'SELL' THEN price * quantity WHEN type = 'BUY' THEN -price * quantity END)
FROM Transactions
WHERE stock_id = 1;

--Profit per stock
SELECT stock_id, SUM(CASE WHEN type = 'SELL' THEN price * quantity WHEN type = 'BUY' THEN -price * quantity END) AS net_profit
FROM Transactions
GROUP BY stock_id;

-- Daily-high performing stocks
SELECT md.data_date, md.stock_id, s.symbol, MAX(md.close_price - md.open_price) AS daily_gain
FROM MarketData md
JOIN Stocks s ON md.stock_id = s.stock_id
GROUP BY md.data_date, md.stock_id, s.symbol
ORDER BY daily_gain DESC;

-- Calculating moving averages for stocks
WITH OrderedPrices AS (
    SELECT stock_id, close_price, ROW_NUMBER() OVER (PARTITION BY stock_id ORDER BY data_date) AS rn
    FROM MarketData
)
SELECT a.stock_id, a.close_price, AVG(b.close_price) AS moving_average
FROM OrderedPrices a
JOIN OrderedPrices b ON a.stock_id = b.stock_id AND b.rn BETWEEN a.rn - 9 AND a.rn
WHERE a.rn >= 10
GROUP BY a.stock_id, a.close_price
ORDER BY a.stock_id, a.rn;


-- Identify potential buy/sell signalsbased on moving averages
SELECT today.stock_id, s.symbol, today.close_price,
       CASE
           WHEN yesterday.moving_average < day_before_yesterday.moving_average AND today.moving_average > yesterday.moving_average THEN 'Buy'
           WHEN yesterday.moving_average > day_before_yesterday.moving_average AND today.moving_average < yesterday.moving_average THEN 'Sell'
           ELSE 'Hold'
       END AS signal
FROM (
    SELECT stock_id, data_date, moving_average, LAG(moving_average, 1) OVER (PARTITION BY stock_id ORDER BY data_date) AS yesterday_moving_average,
                                     LAG(moving_average, 2) OVER (PARTITION BY stock_id ORDER BY data_date) AS day_before_yesterday_moving_average
    FROM (
        SELECT md.data_date, md.stock_id, AVG(md.close_price) OVER (PARTITION BY md.stock_id ORDER BY md.data_date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS moving_average
        FROM MarketData md
    ) as CalculatedMA
) AS today
JOIN Stocks s ON today.stock_id = s.stock_id
WHERE data_date = CURRENT_DATE;


-- Calculate historical volatility for risk management
SELECT stock_id, AVG(POWER(log(close_price / LAG(close_price, 1) OVER (PARTITION BY stock_id ORDER BY data_date)) - avg_log_return, 2)) AS volatility
FROM (
    SELECT stock_id, close_price, data_date,
           AVG(log(close_price / LAG(close_price, 1) OVER (PARTITION BY stock_id ORDER BY data_date))) OVER (PARTITION BY stock_id) AS avg_log_return
    FROM MarketData
    WHERE close_price IS NOT NULL AND LAG(close_price, 1) OVER (PARTITION BY stock_id ORDER BY data_date) IS NOT NULL
) AS returns
GROUP BY stock_id;


-- Calculate portfolio diversification and exposure
SELECT stock_id, SUM(quantity * price) / (SELECT SUM(quantity * price) FROM Transactions) AS portfolio_exposure
FROM Transactions
WHERE type = 'BUY'
GROUP BY stock_id;

-- Generate end-of-day portfolio summary
SELECT t.transaction_date, s.symbol, t.type, t.quantity, t.price,
       (t.quantity * t.price) AS total_value,
       SUM(t.quantity * t.price) OVER (PARTITION BY t.transaction_date) AS daily_total
FROM Transactions t
JOIN Stocks s ON t.stock_id = s.stock_id
WHERE t.transaction_date = CURRENT_DATE;

-- Alerts for significant price drops and spikes
SELECT stock_id, symbol, data_date, close_price,
       LAG(close_price, 1) OVER (PARTITION BY stock_id ORDER BY data_date) AS previous_close,
       CASE
           WHEN close_price < 0.9 * LAG(close_price, 1) OVER (PARTITION BY stock_id ORDER BY data_date) THEN 'Alert Drop >10%'
           WHEN close_price > 1.1 * LAG(close_price, 1) OVER (PARTITION BY stock_id ORDER BY data_date) THEN 'Alert Spike >10%'
           ELSE 'Normal'
       END AS price_alert
FROM MarketData
JOIN Stocks ON MarketData.stock_id = Stocks.stock_id;

