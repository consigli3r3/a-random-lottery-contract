# Decentralized Provably Fair Lottery

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.18-363636)
![Framework](https://img.shields.io/badge/Framework-Foundry-orange)

## 📖 About The Project

This repository features a professional-grade, automated lottery smart contract. It addresses the inherent difficulty of generating secure randomness on a deterministic blockchain by integrating **Chainlink VRF v2**. The lottery is designed to be "set and forget," utilizing **Chainlink Automation** to handle winner selection and contract resets without human intervention.

### Core Technical Logic
* **Verifiable Randomness:** Uses a request-and-fulfill cycle via Chainlink Oracles to ensure the winner is mathematically unbiasable.
* **Autonomous Upkeep:** Implements `checkUpkeep` and `performUpkeep` to automate the transition from "Open" to "Calculating" and "Winner Paid."
* **Security Patterns:** Adheres to the Checks-Effects-Interactions (CEI) pattern to eliminate re-entrancy risks.

---

## 🛠 Tech Stack

* **Smart Contracts:** Solidity
* **Framework:** [Foundry](https://book.getfoundry.sh/) (Forge, Cast, Anvil)
* **Oracles:** Chainlink VRF v2 & Chainlink Automation
* **Automation:** GNU Makefile

---

## 🚀 Getting Started

### Prerequisites
* [Install Foundry](https://book.getfoundry.sh/getting-started/installation)
* An [Alchemy](https://www.alchemy.com/) or [Infura](https://www.infura.io/) RPC URL for Sepolia.

### Installation
1.  **Clone the repo:**
    ```bash
    git clone [https://github.com/consigli3r3/a-random-lottery-contract.git](https://github.com/consigli3r3/a-random-lottery-contract.git)
    cd a-random-lottery-contract
    ```
2.  **Install dependencies:**
    ```bash
    make install # or forge install
    ```
3.  **Environment Setup:**
    Create a `.env` file and add:
    ```env
    SEPOLIA_RPC_URL=your_rpc_url
    ACCOUNT=your_keystore_account
    ETHERSCAN_API_KEY=your_etherscan_api_key
    ```

---

## 🧪 Testing & Quality Control

This project uses Foundry’s high-performance testing suite, including unit tests, integration tests, and stateful fuzzing.

* **Run All Tests:**
    ```bash
    make test # or forge test
    ```
* **Check Coverage:**
    ```bash
    forge coverage
    ```
* **Gas Snapshots:**
    ```bash
    make snapshot
    ```

---

## 📦 Deployment Guide

I have optimized the deployment flow using a **Makefile** to handle long Foundry CLI commands.

### Local Deployment (Anvil)
1.  **Start a local blockchain:**
    ```bash
    make anvil
    ```
2.  **Deploy the contract:**
    (In a new terminal)
    ```bash
    make deploy
    ```

### Testnet Deployment (Sepolia)
To deploy to Sepolia and automatically verify the contract on Etherscan:
```bash
make deploy ARGS="--network sepolia"

---

## 👤 Author

* **Gavin Singh** * **GitHub:** [@consigli3r3](https://github.com/consigli3r3)
* **LinkedIn:** [Gavin Singh](https://www.linkedin.com/in/gavinsingh97/)
* **X (Twitter):** [@consigli3re](https://x.com/consigli3re)