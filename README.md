# Token Price Betting Game on zkSync using Chainlink DataFeed and ChainLink Automation

## Overview

This project allows users to place bets on the future prices of tokens on the zkSync chain. Players can bet on whether the price of a specific token will increase or decrease after a predefined time interval (e.g., 5 minutes). The system fetches live prices using Chainlink Data Feeds and determines the outcome of the bets using Chainlink Automation. Winners are rewarded based on the results, and rewards are distributed accordingly.

## Features

- **Token Price Betting**: Bet on the price movement of tokens on the zkSync chain.
- **Time Intervals**: Place bets for specific time intervals (e.g., 5 minutes).
- **Live Price Feeds**: Utilize Chainlink Data Feeds for accurate and reliable price information.
- **Automation**: Use Chainlink Automation to fetch prices and determine bet outcomes.
- **Rewards Distribution**: Winners are rewarded based on the bet outcomes.

## Prerequisites

- Node.js
- Yarn or npm
- zkSync Wallet
- Chainlink VRF and Automation credentials

## Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/din1376/Token-Price-Betting.git
   cd Token-Price-Betting
   ```

2. **Install dependencies**:

   ```bash
   yarn install
   # or
   npm install
   ```

3. **Configure environment variables**:
   Create a `.env` file in the root directory and add the following variables:

   ```plaintext
   ZKSYNC_NETWORK_URL=<your_zksync_network_url>
   PRIVATE_KEY=<your_private_key>
   ```

4. **Compile contracts**:

   ```bash
   yarn compile
   # or
   npm run compile
   ```

5. **Deploy contracts**:
   ```bash
   yarn deploy
   # or
   npm run deploy
   ```

## Usage

1. **Place a Bet**:

   - Users can place bets on the price movement (increase or decrease) of a specific token.
   - Specify the token, bet amount, and the time interval (e.g., 5 minutes).

2. **Fetch Live Prices**:

   - The system automatically fetches live token prices using Chainlink Data Feeds at the end of the betting interval.

3. **Determine Outcome**:

   - Chainlink Automation is used to determine the outcome of the bets based on the fetched prices.
   - Winners are identified based on the correct prediction of the price movement.

4. **Distribute Rewards**:
   - Rewards are distributed to the winners according to the predefined reward structure.

## Smart Contracts

- **Betting Contract**: Manages bets, fetches prices, and determines outcomes.
- **Reward Contract**: Distributes rewards to the winners.

## Contributing

We welcome contributions from the community. Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
