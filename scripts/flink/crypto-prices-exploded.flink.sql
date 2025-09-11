-- Create exploded table with individual records for each cryptocurrency
-- Note: This creates a table with proper time attributes for windowing operations
CREATE TABLE `crypto-prices-exploded` (
    coin_id STRING,
    usd DOUBLE,
    usd_market_cap DOUBLE,
    usd_24h_vol DOUBLE,
    usd_24h_change DOUBLE,
    last_updated_at BIGINT,
    event_time AS TO_TIMESTAMP_LTZ(last_updated_at, 0),
    processed_at AS CURRENT_TIMESTAMP,
    WATERMARK FOR event_time AS event_time - INTERVAL '30' SECONDS
);

-- Populate the exploded table from the raw crypto-prices data
INSERT INTO `crypto-prices-exploded`
SELECT 
    coin_id,
    usd,
    usd_market_cap,
    usd_24h_vol,
    usd_24h_change,
    last_updated_at
FROM (
    SELECT 'bitcoin' as coin_id, bitcoin.usd, bitcoin.usd_market_cap, bitcoin.usd_24h_vol, bitcoin.usd_24h_change, bitcoin.last_updated_at FROM `crypto-prices` WHERE bitcoin IS NOT NULL
    UNION ALL
    SELECT 'ethereum' as coin_id, ethereum.usd, ethereum.usd_market_cap, ethereum.usd_24h_vol, ethereum.usd_24h_change, ethereum.last_updated_at FROM `crypto-prices` WHERE ethereum IS NOT NULL
    UNION ALL
    SELECT 'binancecoin' as coin_id, binancecoin.usd, binancecoin.usd_market_cap, binancecoin.usd_24h_vol, binancecoin.usd_24h_change, binancecoin.last_updated_at FROM `crypto-prices` WHERE binancecoin IS NOT NULL
    UNION ALL
    SELECT 'cardano' as coin_id, cardano.usd, cardano.usd_market_cap, cardano.usd_24h_vol, cardano.usd_24h_change, cardano.last_updated_at FROM `crypto-prices` WHERE cardano IS NOT NULL
    UNION ALL
    SELECT 'solana' as coin_id, solana.usd, solana.usd_market_cap, solana.usd_24h_vol, solana.usd_24h_change, solana.last_updated_at FROM `crypto-prices` WHERE solana IS NOT NULL
) exploded
WHERE usd IS NOT NULL AND usd > 0;
