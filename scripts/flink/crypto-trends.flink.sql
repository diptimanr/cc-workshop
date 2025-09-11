CREATE TABLE `crypto-trends` AS
SELECT 
  coin_id as cryptocurrency,
  window_start,
  window_end,
  avg_price,
  price_volatility,
  CASE 
    WHEN price_change_pct > 2 THEN 'UPWARD'
    WHEN price_change_pct < -2 THEN 'DOWNWARD'
    ELSE 'SIDEWAYS'
  END as trend_direction,
  LEAST(ABS(price_change_pct) / 10.0, 1.0) as confidence_score
FROM (
  SELECT 
    coin_id,
    window_start,
    window_end,
    AVG(usd) as avg_price,
    STDDEV(usd) as price_volatility,
    (LAST_VALUE(usd) - FIRST_VALUE(usd)) / FIRST_VALUE(usd) * 100 as price_change_pct
  FROM TABLE(
    TUMBLE(TABLE `crypto-prices-exploded`, DESCRIPTOR(event_time), INTERVAL '10' MINUTES)
  )
  GROUP BY coin_id, window_start, window_end
);