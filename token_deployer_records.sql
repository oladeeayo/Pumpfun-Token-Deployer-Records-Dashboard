WITH token_info AS (
  SELECT
    token_mint_address,
    name,
    symbol
  FROM tokens_solana.fungible
),
all_launched_tokens_all_time AS (
  SELECT 
    tx_signer AS token_creator,
    t.token_mint_address,
    amount / 1e6 AS total_supply,
    block_time,
    ti.symbol
  FROM tokens_solana.transfers t
  JOIN token_info ti ON t.token_mint_address = ti.token_mint_address
  WHERE action = 'mint'
    AND outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
    AND t.token_mint_address IS NOT NULL
),
token_creators AS (
  SELECT
    token_mint_address AS token_address,
    token_creator AS deployer,
    block_time AS launch_time
  FROM all_launched_tokens_all_time
),
deployer_self_buys AS (
  SELECT
    buy.account_mint AS token_address,
    buy.account_user AS user,
    COUNT(*) AS self_buy_count
  FROM pumpdotfun_solana.pump_call_buy AS buy
  JOIN token_creators AS tc
    ON buy.account_mint = tc.token_address AND buy.account_user = tc.deployer
  GROUP BY
    buy.account_mint,
    buy.account_user
),
manipulator_buys AS (
  SELECT
    buy.account_mint AS token_address,
    buy.account_user AS user,
    COUNT(*) AS buy_count
  FROM pumpdotfun_solana.pump_call_buy AS buy
  LEFT JOIN token_creators AS tc
    ON buy.account_mint = tc.token_address
  WHERE
    buy.account_user <> COALESCE(tc.deployer, '')
  GROUP BY
    buy.account_mint,
    buy.account_user
  HAVING
    COUNT(*) > 6
),
actual_snipers AS (
  SELECT
    buy.account_mint AS token_address,
    buy.account_user AS user
  FROM pumpdotfun_solana.pump_call_buy AS buy
  JOIN token_creators AS tc
    ON buy.account_mint = tc.token_address
  WHERE
    buy.account_user <> tc.deployer
    AND buy.call_block_time BETWEEN tc.launch_time + INTERVAL '1' SECOND AND tc.launch_time + INTERVAL '40' SECOND
  GROUP BY
    buy.account_mint,
    buy.account_user
),
deployer_transfers AS (
  SELECT
    t.token_mint_address AS token_address,
    COUNT(*) AS deployer_transfer_count
  FROM tokens_solana.transfers t
  JOIN token_creators tc ON t.token_mint_address = tc.token_address AND t.from_owner = tc.deployer
  WHERE t.action = 'transfer'
    AND t.outer_instruction_index = 2
    AND t.inner_instruction_index = 0
  GROUP BY t.token_mint_address
),
deployer_pnl AS (
  SELECT
    tc.token_address,
    tc.deployer,
    SUM(CASE WHEN t.token_bought_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END) AS total_buys_usd,
    SUM(CASE WHEN t.token_sold_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END) AS total_sells_usd,
    SUM(CASE WHEN t.token_sold_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END)
      - SUM(CASE WHEN t.token_bought_mint_address = tc.token_address THEN t.amount_usd ELSE 0 END) AS pnl
  FROM dex_solana.trades t
  JOIN token_creators tc
    ON t.trader_id = tc.deployer
    AND (t.token_bought_mint_address = tc.token_address OR t.token_sold_mint_address = tc.token_address)
  GROUP BY tc.token_address, tc.deployer
)
SELECT
  CONCAT('<a href="gmgn.ai/sol/token/', tc.token_address, '" target="_blank">', tc.token_address, '</a>') as token_address,
  ti.symbol,
  CONCAT('<a href="https://pump.fun/profile/', tc.deployer, '" target="_blank">', tc.deployer, '</a>') as deployer,
  COALESCE(ROUND(dp.pnl, 2), 0) AS deployer_pnl,
  COALESCE(dsb.self_buy_count, 0) AS deployer_self_buys,
  COALESCE(dt.deployer_transfer_count, 0) AS deployer_transfer_count,
  COUNT(DISTINCT mb.user) AS manipulator_count,
  COUNT(DISTINCT asn.user) AS actual_sniper_count,
  tc.launch_time
FROM token_creators AS tc
LEFT JOIN deployer_self_buys AS dsb
  ON tc.token_address = dsb.token_address AND tc.deployer = dsb.user
LEFT JOIN manipulator_buys AS mb
  ON tc.token_address = mb.token_address
LEFT JOIN actual_snipers AS asn
  ON tc.token_address = asn.token_address
LEFT JOIN token_info ti
  ON tc.token_address = ti.token_mint_address
LEFT JOIN deployer_transfers dt
  ON tc.token_address = dt.token_address
LEFT JOIN deployer_pnl dp
  ON tc.token_address = dp.token_address AND tc.deployer = dp.deployer
WHERE
  DATE_TRUNC('year', tc.launch_time) = DATE_TRUNC('year', CURRENT_DATE)
GROUP BY
  tc.token_address,
  ti.symbol,
  tc.deployer,
  tc.launch_time,
  dsb.self_buy_count,
  dt.deployer_transfer_count,
  dp.pnl
ORDER BY
  tc.launch_time DESC;