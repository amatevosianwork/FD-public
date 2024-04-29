# FooDriver Smart Contract System

This system is designed to facilitate complex interactions within a service-oriented ecosystem, leveraging blockchain technology for security, transparency, and efficiency.

## Overview

The FooDriver smart contract system is a suite of interconnected contracts each serving distinct roles within the platform:

- **FooDriverToken**
- **FooDriverRegistry**
- **FooDriverFactory**
- **FooDriverStore**
- **FooDriverBank**

Each contract plays a vital role in the ecosystem, from managing financial transactions to handling user roles and permissions.

## Contract Details

### FooDriverToken

This ERC20 token acts as the currency within the FooDriver platform. It is used for:

- **Transactions**: Payments for services within the platform.
- **Rewards**: Incentivizing users and service providers.
- **Governance**: Voting on platform decisions (if governance features are implemented).

Features include:
- **Public and Private Sales**: Mechanisms for token distribution before the platform becomes fully operational.
- **Initial Minting**: Allocation of tokens to stakeholders such as marketing, liquidity provisions, team members, and founders.

### FooDriverRegistry

Acts as the central hub for:
- **Role Management**: Defines roles like admins, store owners, and service providers, and assigns permissions.
- **Contract Interactions**: Facilitates interactions between different contracts, ensuring that operations such as token transfers, store creation, and order management are executed securely and in accordance with platform rules.

### FooDriverFactory

Responsible for:
- **Store Creation**: Dynamically creates instances of `FooDriverStore` for each new store or service provider on the platform.
- **Tracking**: Maintains a registry of all active stores, providing lookup capabilities to find stores by their identifiers.

### FooDriverStore

Each store or service provider has its own instance, managing:
- **Order Processing**: Creation, confirmation, and fulfillment of orders.
- **Financial Operations**: Handles deposits and payments related to orders, interacting with the `FooDriverBank` to lock and release funds as needed.
- **Order Status Tracking**: Monitors and updates the status of each order, from pending to completed or refunded.

### FooDriverBank

Manages all financial aspects related to services:
- **Fund Locking and Releasing**: Secures funds when orders are placed and releases them upon order completion or as refunds.
- **Transaction Security**: Ensures that financial transactions are executed in accordance with the agreed-upon terms of service.

## Ecosystem Interactions

The contracts are designed to work in a cohesive manner:
1. **Token Distribution**: `FooDriverToken` facilitates the initial distribution and subsequent transactions of tokens.
2. **Role and Permission Management**: `FooDriverRegistry` manages roles and permissions across the ecosystem, interacting with other contracts to enforce these roles.
3. **Dynamic Store Management**: `FooDriverFactory` creates and manages `FooDriverStore` instances as new service providers join the platform.
4. **Order and Financial Management**: Each `FooDriverStore` handles its orders while interacting with `FooDriverBank` to manage financial transactions securely and efficiently.


## TokenLock Contract

The `TokenLock` contract is providing a secure and transparent mechanism for locking ERC20 tokens. This contract is particularly used to manage the token allocations for founders and team members, ensuring that these tokens are released over time to align incentives with the long-term success of the platform.

### Features and Functionalities

- **Token Locking**: Facilitates the locking of ERC20 tokens for a predetermined duration, preventing premature circulation.
- **Configurable Locking and Release Periods**: Tokens can be deposited until a specified `depositDeadline` and are securely locked until the `lockDuration` expires.
- **Non-Transferable Lock Tokens**: The contract ensures that lock claim tokens, representing the locked assets, cannot be transferred, sold, or used before the lock period concludes.

### Operations

#### Initialization

The contract is initialized with parameters specifying:
- **Owner**: Typically, a governance or multisig wallet responsible for contract oversight.
- **Token Address**: The ERC20 token to be locked.
- **Deposit Deadline and Lock Duration**: Timeframes for depositing and locking the tokens.
- **Token Identifiers**: Custom name and symbol for the locked tokens, often reflecting their specific purpose (e.g., `FDT Founders`, `FDT Team`).

#### Deposit

Founders and team members (or the entity managing their allocations) will deposit their allocated tokens into the contract until the `depositDeadline`. This action records their balances and increases the `totalSupply` of the lock claim tokens.

#### Withdrawal

After the lock duration expires, the stakeholders can withdraw their tokens:
- **End of Lock Duration**: Ensures that the tokens can be gradually integrated into the market, supporting both price stability and continued commitment from the founders and team members.

### Error Handling

Custom errors are defined to handle common operational exceptions:
- `ExceedsBalance`: Ensures withdrawal requests do not exceed the locked balance.
- `DepositPeriodOver`: Prevents deposits post-deadline, enforcing the locking schedule.
- `LockPeriodOngoing`: Blocks withdrawals before the lock period ends, ensuring compliance with the vesting schedule.
- `TransferFailed`: Addresses issues in token transfers to and from the contract.

### Use Case in FooDriver

The primary use of the `TokenLock` contract within the FooDriver ecosystem is to lock tokens of founders and team members. This is crucial for:
- **Ensuring Long-term Commitment**: By locking tokens, founders and team members are incentivized to continue contributing to the project's success over a more extended period.
- **Preventing Premature Selling**: Reduces the risk of early token sell-offs that could destabilize the token economy.

### Conclusion

By implementing the `TokenLock` contract, FooDriver ensures that the release of tokens to its core contributors is aligned with the platform’s growth and milestones, thereby supporting sustainable development and value creation within the ecosystem.

The final version of `TokenLock` to be used in ecosystem is still TBD and might be changed.  


The FooDriver smart contract system is structured to support a scalable and secure platform for service-oriented transactions.
