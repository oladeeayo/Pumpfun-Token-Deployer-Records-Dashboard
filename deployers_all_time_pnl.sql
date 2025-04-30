WITH deployer_pnl AS (
  SELECT
      tc.token_address,
      tc.deployer,
      SUM(CASE WHEN t.token_bought_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END) AS total_buys_usd,
      SUM(CASE WHEN t.token_sold_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END) AS total_sells_usd,
      SUM(CASE WHEN t.token_sold_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END)
          - SUM(CASE WHEN t.token_bought_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END) AS pnl
  FROM dex_solana.trades t
  JOIN dune.dev_toshiii.result_token_deployed_all_time tc
      ON t.trader_id = tc.deployer
      AND (t.token_bought_mint_address = tc.token_address OR t.token_sold_mint_address = tc.token_address)
  GROUP BY tc.token_address, tc.deployer
),
deployer_metrics AS (
  SELECT
      tc.deployer,
      COUNT(DISTINCT tc.token_address) AS total_tokens_launched,
      SUM(CASE WHEN tc.graduated IS NOT NULL AND tc.graduated = '✅' THEN 1 ELSE 0 END) AS total_graduated_tokens,
      ROUND(
        (CAST(SUM(CASE WHEN tc.graduated IS NOT NULL AND tc.graduated = '✅' THEN 1 ELSE 0 END) AS DOUBLE) / 
         COUNT(DISTINCT tc.token_address)) * 1.0000,
        4
      ) AS graduation_rate,
      MAX(tc.launch_time) AS last_launched_token_date,
      COALESCE(SUM(dp.pnl), 0) AS pnl
  FROM dune.dev_toshiii.result_token_deployed_all_time tc
  LEFT JOIN deployer_pnl dp
      ON tc.token_address = dp.token_address
      AND tc.deployer = dp.deployer
  GROUP BY tc.deployer
)
SELECT
    CONCAT('<a href="https://pump.fun/profile/', deployer, '" target="_blank">', deployer, '</a>') as deployer,
    total_tokens_launched,
    total_graduated_tokens,
    graduation_rate,
    ROUND(pnl, 3) AS pnl,
    last_launched_token_date
FROM deployer_metrics
ORDER BY total_tokens_launched DESC, last_launched_token_date DESC;