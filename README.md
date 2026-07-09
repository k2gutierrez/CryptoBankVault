<div align="center">
  <h1>🏦 CryptoBank Vault</h1>
  <p><b>A full-stack DeFi protocol featuring multi-signature joint accounts, automated yield generation, and a modern Next.js frontend.</b></p>
</div>

## 📖 About the Project

The **CryptoBank Vault** is a production-ready Web3 application that bridges secure, gas-optimized Smart Contracts with a highly interactive, beautifully animated frontend. Built with **Solidity `0.8.30`** and the **Foundry** framework on the backend, and **Next.js, Wagmi v2, Jotai, and Framer Motion** on the frontend, it demonstrates a complete, modern DeFi product lifecycle.

This architecture goes beyond basic deposits and withdrawals. It introduces automated yield farming (users earn `$K2CBT` tokens block-by-block) and a dual-tier account system that supports strict multi-signature authorizations for joint accounts.

**Key Technical Highlights:**
* **Smart Contracts (Solidity `0.8.30`):** Gas-optimized logic utilizing custom errors, the Checks-Effects-Interactions pattern, and modular token separation (`YieldToken` and `BankAccounts`).
* **Multi-Signature Logic:** Native implementation of joint accounts requiring sequential approvals for asset withdrawal, demonstrating complex state management.
* **Frontend State Management:** Utilizes **Jotai** for atomic, lightweight global state, seamlessly paired with **Wagmi v2 / React Query** for cached, highly responsive blockchain reads/writes.
* **Modern UI/UX:** Built with the Next.js App Router, styled with Tailwind CSS, and animated using Framer Motion to provide a premium, fintech-grade user experience.

---

## ⚙️ How It Works

The ecosystem is divided into two primary Smart Contracts and a React-based frontend application.

Users connect their wallets via **RainbowKit** and can open either an `Individual` or a `Joint` vault. When funds (Ether) are deposited, the `BankAccounts` contract tracks the timestamp. Upon any subsequent state change (deposit or withdrawal), the internal `_processYield` function calculates the time elapsed and automatically mints `$K2CBT` (CryptoBank Yield Tokens) directly to the user's wallet as interest.

For `Joint` accounts, if Co-Owner A requests a withdrawal, the funds are locked in a `WithdrawalRequest` state. The transaction will only execute when Co-Owner B connects their wallet and explicitly signs the `approveWithdrawal` transaction.

### Architecture Diagram

![CryptoBank Vault Architecture Diagram](./images/diagram.png)

### Core Component File Paths
* **Smart Contracts:**
  * [`BankAccounts.sol`](./src/BankAccounts.sol) - Main Vault and Multi-sig Logic
  * [`YieldToken.sol`](./src/YieldToken.sol) - ERC20 Reward Token
  * [`DeployBankAndToken.s.sol`](./script/DeployBankAndToken.s.sol) - Foundry Deployment Script
* **Frontend (Next.js):**
  * [`app/page.tsx`](./frontend/src/cryptobank-vault-ui/src/app/page.tsx) - Main Dashboard Layout
  * [`components/AccountDetails.tsx`](./frontend/cryptobank-vault-ui/src/components/AccountDetails.tsx) - Wagmi Integration & Multi-sig UI
  * [`components/YieldPortfolio.tsx`](./frontend/cryptobank-vault-ui/src/components/YieldPortfolio.tsx) - Real-time ERC20 Balance Polling
  * [`store/index.ts`](./frontend/cryptobank-vault-ui/store/index.ts) - Jotai Global State

---

## 💻 Technical Docs: Smart Contracts

### _processYield (BankAccounts.sol)
An internal engine that mathematically calculates yield based on the vault's balance and the time elapsed since the last update. It mints `$K2CBT` tokens before any balance mutation occurs to ensure accurate payouts.

```solidity
    function _processYield(uint256 _accountId) internal {
        Account storage account = s_accounts[_accountId];
        if (account.balance > 0) {
            uint256 timeElapsed = block.timestamp - account.lastUpdateTime;
            uint256 yieldAmount = (account.balance * timeElapsed) / YIELD_RATE_DENOMINATOR;
            if (yieldAmount > 0) {
                uint256 yieldPerOwner = yieldAmount / account.owners.length;
                for (uint i = 0; i < account.owners.length; i++) {
                    s_yieldToken.mint(account.owners[i], yieldPerOwner);
                }
            }
        }
        account.lastUpdateTime = block.timestamp;
    }
```

### approveWithdrawal (BankAccounts.sol)
The second half of the multi-signature flow. It verifies the caller is a co-owner, ensures they did not initiate the original request, processes pending yield, and safely transfers the assets.

```Solidity
    function approveWithdrawal(uint256 _accountId) external {
        Account storage account = s_accounts[_accountId];
        WithdrawalRequest storage request = s_withdrawalRequests[_accountId];

        // ... validations and owner checks ...
        if (msg.sender == request.requester) revert BankAccounts__CannotApproveOwnRequest();

        request.approvedByOther = true;
        request.isExecuted = true;
        _processYield(_accountId);
        account.balance -= request.amount;
        
        (bool success, ) = request.requester.call{value: request.amount}("");
        require(success, "Transfer failed");

        emit WithdrawalExecuted(_accountId, request.requester, request.amount);
    }
```

🖥️ Technical Docs: Frontend Integration
The frontend leverages Wagmi v2 to interact directly with the deployed contracts, utilizing React hooks for reactive UI updates.

Reactive Contract Reads (Wagmi + React Query)
By passing refetchInterval, the frontend automatically polls the blockchain to animate the user's growing $K2CBT yield balance in real-time without requiring manual page refreshes.

```TypeScript
  const { data: bktBalance, isLoading } = useReadContract({
    address: yieldTokenAddress,
    abi: YIELD_TOKEN_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { 
      enabled: isConnected && !!yieldTokenAddress && !!address,
      refetchInterval: 5000 
    }
  });
```

🚀 Execution Example
Here is a step-by-step example of how users interact with the full-stack ecosystem:

Step 1: Deployment & Setup: The protocol owner deploys the contracts via Foundry to ApeChain Curtis. The BankAccounts contract is granted ownership of the YieldToken contract to allow minting.

Step 2: Connecting & Creation: User A opens the Next.js app, connects their wallet via RainbowKit, and creates a Joint vault, providing User B's wallet address.

Step 3: Depositing Funds: User A deposits 5 ETH into the newly created vault. The transaction is tracked, and the frontend animations update the total balance instantly.

Step 4: Accumulating Yield: Time passes. User A decides to request a withdrawal of 2 ETH. The contract automatically calculates the interest generated on the 5 ETH over that time period and mints $K2CBT tokens to both User A and User B.

Step 5: Multi-sig Authorization: The 2 ETH withdrawal is placed in a pending state. User B navigates to the Web3 app. The UI detects the pending request and displays a golden "Approve & Execute" button. User B signs the transaction, the 2 ETH is released to User A, and the UI clears the notification.

⬆️ Installation & Setup
1. Smart Contracts (Backend)
Ensure you have Foundry installed.

# Install dependencies
```bash
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std
```

# Run the test suite
```bash
forge test -vvvv
```

# Deploy to ApeChain Curtis Testnet
```bash
forge script script/DeployBankAndToken.s.sol:DeployBankAndToken --rpc-url [https://curtis.rpc.caldera.xyz/http](https://curtis.rpc.caldera.xyz/http) --account YOUR_WALLET --broadcast --verify --verifier blockscout --verifier-url "[https://api.etherscan.io/v2/api?chainid=33111](https://api.etherscan.io/v2/api?chainid=33111)"
```

2. Frontend (Next.js)
Ensure you have Node.js installed.

```bash
# Navigate to the frontend directory
cd frontend

# Install dependencies
npm install

# Run the local development server
npm run dev
```
Navigate to http://localhost:3000 to interact with the UI.

📜 Contract Addresses (ApeChain Curtis Testnet)
BankAccounts Vault: [0x30CE21546C19C1fc230A3A657C3492653fe7Eb2A]
YieldToken ($K2CBT): [0xDF6236c9f4a3b383DFb52b5F35A1340450800F24]

📜 Website (ApeChain Curtis Testnet)
[CryptoBank Website]()