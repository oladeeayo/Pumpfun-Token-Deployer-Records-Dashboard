# Pumpfun Token Deployer Records Dashboard

### Overview

This repository contains the Dune Analytics queries for the Pumpfun Token Deployer Records Dashboard, designed for the MCSI Hackathon. The dashboard provides a comprehensive view of deployer behavior across all tokens launched on the Pumpfun platform in the Solana ecosystem. It tracks key metrics like total tokens launched, graduation rates, and profit/loss (PnL), while offering per-token insights into deployer actions, including self-buys, transfers, snipers, and manipulators. This tool is ideal for on-chain investigators and analysts aiming to detect suspicious patterns or serial rug pullers.

## Queries

**Query 1: Token Deployer Records**

Description: Retrieves detailed information about each token launched on Pumpfun, including the deployer's behavior, self-buys, transfers, snipers, and manipulators.

Logic Explanation:

Token Info: Fetches token metadata (name, symbol) from the Solana fungible tokens dataset.
All Launched Tokens: Identifies tokens minted via Pumpfun by filtering mint transactions with the specific outer executing account.
Token Creators: Extracts the deployer and launch time for each token.
Deployer Self-Buys: Counts the deployer's own token purchases.
Manipulator Buys: Flags wallets with over 6 buys, indicating potential manipulation.
Actual Snipers: Detects non-deployer wallets buying within 1 to 40 seconds post-launch.
Deployer Transfers: Counts token transfers from the deployer to other wallets.
Deployer PnL: Calculates the deployer's profit/loss by subtracting total buys from sells in USD.

Output: Combines data into a per-token view with links to external resources (gmgn.ai for tokens, Pumpfun for deployers). Filters for current-year launches to optimize performance.

**Query 2: Pumpfun Deployers All Time PnL**

Description: Aggregates metrics per deployer, showing total tokens launched, graduation rates, and cumulative PnL.

Logic Explanation:

Deployer PnL: Computes per-token PnL for each deployer by aggregating trade data.
Deployer Metrics: Aggregates:
Total tokens launched.
Number of graduated tokens (tokens meeting Pumpfun thresholds).
Graduation rate (percentage of graduated tokens).
Most recent launch date.
Cumulative PnL across all tokens.

Output: Presents metrics per deployer with links to their Pumpfun profile, ordered by total tokens launched and most recent launch date.

### Usage

Access the dashboard on Dune Analytics (link to be provided).
Explore the Token Deployer Records table for per-token insights or the All Time PnL table for deployer-level metrics.
Use the data to identify high-risk deployers or analyze token launch patterns.

### Notes

Queries rely on Dune Analytics datasets like tokens_solana.transfers, pumpdotfun_solana.pump_call_buy, and dex_solana.trades.
The dashboard focuses on Pumpfun due to its dominance in Solana memecoin launches.
For detailed query implementation, refer to the source files in this repository.

### Contributing

Contributions are welcome! Please submit issues or pull requests for improvements or bug fixes.

