-- Create price alerts using exploded cryptocurrency data
--insert into`price-alerts`
create table price-alerts as(
SELECT 
  coin_id as cryptocurrency,
  usd as current_price,
  usd_24h_change as price_change,
  CASE 
    WHEN usd_24h_change > 5 THEN 'STRONG_BULLISH'
    WHEN usd_24h_change > 5 THEN 'BULLISH'
    WHEN usd_24h_change < -5 THEN 'STRONG_BEARISH'
    WHEN usd_24h_change < -3 THEN 'BEARISH'
    ELSE 'NEUTRAL'
  END as alert_type,
  event_time as alert_time
FROM `crypto-prices-exploded`
WHERE ABS(usd_24h_change) > 3.0
);
