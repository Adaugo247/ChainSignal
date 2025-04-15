# CryptoSignal

A blockchain-based trading strategy system built on Stacks that enables sequential trading signals with verifiable execution and automated profit distribution.

## Overview

CryptoSignal is a decentralized platform that allows strategy creators to publish trading signals with cryptographic proof requirements, while subscribers can execute these signals and earn rewards. The system uses the Clarity smart contract language on the Stacks blockchain to ensure transparency, security, and fair profit distribution.

## Features

- **Secure Signal Publishing**: Strategy owners can publish trading signals with cryptographic execution proofs
- **Sequential Signal Execution**: Signals must be executed in order, ensuring strategy integrity
- **Lockup Periods**: Signals are protected by time-based lockup periods to prevent front-running
- **Automated Profit Distribution**: Successful signal execution automatically distributes profits
- **Performance Tracking**: Comprehensive tracking of trader performance and signal execution history
- **Subscription Model**: Traders pay a subscription fee to access signals

## Smart Contract Architecture

### Core Components

1. **Strategy Management**
   - Owner-controlled strategy activation
   - Signal creation with execution proofs
   - Block height management for time-based features

2. **Trader Management**
   - Subscription system
   - Performance tracking
   - Execution history

3. **Signal Execution**
   - Cryptographic proof verification
   - Automated profit distribution
   - Success recording

### Data Structures

- `trading-signals`: Stores signal details including description, execution hash, lockup period, and profit share
- `trader-performance`: Tracks trader activity including current signal, executed signals, and total executions
- `signal-executions`: Records execution attempts and successful completions
- `signal-successes`: Lists successful traders for each signal

## How It Works

1. **Strategy Creation**:
   - The strategy owner activates the strategy
   - Owner adds signals with descriptions, execution proofs, lockup periods, and profit shares

2. **Trader Onboarding**:
   - Traders subscribe by paying the subscription fee
   - Subscription initializes trader performance tracking

3. **Signal Execution**:
   - Traders wait for lockup periods to end
   - Traders submit execution proofs for signals
   - If proof is correct, the signal is marked as executed
   - Profit share is automatically transferred to the trader
   - Execution is recorded in the trader's history

4. **Performance Monitoring**:
   - Strategy owner and traders can view execution statistics
   - Signal success history is publicly available

## Technical Details

### Error Codes

- `ERR-NOT-STRATEGY-OWNER (u1)`: Caller is not the strategy owner
- `ERR-STRATEGY-NOT-LIVE (u2)`: Strategy is not active
- `ERR-INVALID-SIGNAL (u3)`: Signal does not exist
- `ERR-ALREADY-EXECUTED (u4)`: Signal has already been executed
- `ERR-WRONG-EXECUTION-HASH (u5)`: Execution proof does not match
- `ERR-LOCKUP-PERIOD-ACTIVE (u6)`: Signal is still in lockup period
- `ERR-INSUFFICIENT-CAPITAL (u7)`: Not enough capital for operation
- `ERR-INVALID-PARAMETER (u8)`: Invalid parameter provided
- `ERR-SIGNAL-EXISTS (u9)`: Signal ID already exists

### Public Functions

#### Strategy Management
- `activate-strategy()`: Activates the trading strategy
- `add-signal(signal-id, description, execution-hash, lockup-end, profit-share)`: Adds a new trading signal
- `update-block-height(new-height)`: Updates the current block height

#### Trader Functions
- `subscribe-to-signals()`: Subscribes a trader to the strategy
- `execute-signal(signal-id, execution-proof)`: Executes a signal with proof

#### Read-Only Functions
- `get-signal-description(signal-id)`: Returns a signal's description if lockup period has ended
- `get-trader-status(trader)`: Returns a trader's performance statistics
- `get-signal-successes(signal-id)`: Returns successful executions for a signal
- `get-current-block-height()`: Returns the current block height
- `get-strategy-stats()`: Returns overall strategy statistics

## Development and Deployment

### Prerequisites
- Stacks blockchain development environment
- Clarity language knowledge
- Stacks wallet for deployment

### Deployment Steps
1. Deploy the contract to the Stacks blockchain
2. Initialize the strategy as the contract owner
3. Add signals with appropriate parameters
4. Activate the strategy to allow trader subscriptions

### Testing
The contract should be thoroughly tested with:
- Unit tests for each function
- Integration tests for the complete signal flow
- Security audits to ensure fund safety

## Security Considerations

- **Execution Proof Generation**: Use secure cryptographic methods to generate execution proofs
- **Lockup Periods**: Set appropriate lockup periods to prevent front-running
- **Profit Share Amounts**: Ensure profit share amounts are reasonable and sustainable
- **Block Height Management**: Regularly update block height to maintain system integrity

## Future Enhancements

- Multi-asset support for different cryptocurrencies
- Tiered subscription models with different access levels
- Reputation system for strategy owners
- Governance mechanisms for community-driven parameter adjustments
- Integration with external price oracles for automated signal verification

