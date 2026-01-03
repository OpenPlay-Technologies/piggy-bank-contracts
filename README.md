# Piggy Bank

A progressive risk-reward game built on the [Sui blockchain](https://sui.io/) using the [OpenPlay](https://github.com/OpenPlay-Technologies/openplay-core) gaming framework.

## Overview

Piggy Bank is a GambleFi game where players take calculated risks to multiply their stake. The game features a series of steps, each with an increasing payout multiplier. Players must decide whether to cash out their current winnings or risk it all by advancing to the next step.

### How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PIGGY BANK GAME FLOW                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   START GAME                                                        │
│       │                                                             │
│       ▼                                                             │
│   Place Stake ──────► First Advance Attempt                         │
│                              │                                      │
│                    ┌─────────┴─────────┐                            │
│                    │                   │                            │
│                    ▼                   ▼                            │
│               SUCCESS              FAILURE                          │
│            (Position 0)          (Lose Stake)                       │
│                    │                                                │
│         ┌─────────┴─────────┐                                       │
│         │                   │                                       │
│         ▼                   ▼                                       │
│     ADVANCE             CASH OUT                                    │
│    (Risk More)      (Claim Winnings)                                │
│         │                   │                                       │
│    ┌────┴────┐              │                                       │
│    │         │              │                                       │
│    ▼         ▼              ▼                                       │
│ SUCCESS   FAILURE       PAYOUT                                      │
│ (Next     (Lose      (stake × multiplier)                           │
│  Step)     All)                                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Game Mechanics

1. **Start Game**: Player places a stake (bet) within configured min/max limits
2. **Advance**: Each advance attempt has a configurable success rate
   - **Success**: Move to the next position with a higher payout multiplier
   - **Failure**: Lose the entire stake
3. **Cash Out**: At any position, the player can claim their current payout
   - Payout = Stake × Position Multiplier
4. **Max Position**: Reaching the final step automatically triggers a cash out

### Example Game Configuration

| Position | Payout Multiplier | Success Rate |
|----------|-------------------|--------------|
| 0 | 2.0x | 90% |
| 1 | 4.0x | 90% |
| 2 | 8.0x | 90% |
| 3 | 16.0x | 90% |

With a 100 SUI stake:
- Cash out at Position 0 → Receive 200 SUI
- Cash out at Position 1 → Receive 400 SUI
- Reach Position 3 (max) → Receive 1,600 SUI
- Fail at any advance → Lose 100 SUI

## Architecture

### Smart Contract Structure

```
package/sources/
├── game.move       # Core game logic, entry points, admin functions
├── context.move    # Player game state management
└── constants.move  # Game constants and status definitions
```

### Key Components

#### Game Object
The main shared object that manages all player game sessions.

```move
public struct Game has key {
    id: UID,
    contexts: Table<ID, PiggyBankContext>,  // Player states
    param_store_id: ID,                      // Configuration reference
}
```

#### Player Context
Stores the state of an individual player's game session.

```move
public struct PiggyBankContext has copy, drop, store {
    stake: u64,           // Amount bet
    win: u64,             // Payout (if won)
    current_position: u8, // Current step
    status: String,       // Game state
}
```

#### Game Parameters
All configurable parameters are stored in an immutable `ParameterStore`:

| Parameter | Description |
|-----------|-------------|
| `min_stake` | Minimum bet amount |
| `max_stake` | Maximum bet amount |
| `success_rate_bps` | Probability of successful advance (basis points) |
| `steps_payout_bps` | Payout multipliers for each position |

### Integration with OpenPlay

Piggy Bank integrates with the OpenPlay gaming framework for:

- **House Management**: Fund custody, liquidity provision
- **Balance Manager**: Player account management
- **Transaction Processing**: Bet and win settlement
- **Game Statistics**: Tracking and reporting
- **Fee Collection**: House revenue management

## Security Features

### Randomness
Uses Sui's native VRF (`sui::random`) for cryptographically secure, unpredictable outcomes.

### Immutability
- Package is deployed as immutable (UpgradeCap destroyed)
- Game parameters frozen at creation time

### Parameter Validation
All parameter reads validate the ParameterStore ID to prevent parameter swapping attacks.

### Fund Safety
House funds are verified before RNG to ensure payouts can always be honored.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy-package.sh` | Deploy the package and make it immutable |
| `scripts/create-game.sh` | Create a new game instance with parameters |
| `scripts/claim-fees.sh` | Claim accumulated fees from a house |

## Audit Status

This repository has been audited. See the audit folder for:

- [Security Audit Report](audit/SECURITY_AUDIT_REPORT_OPUS4.5.md) - Comprehensive security analysis
- [Game Whitelisting Checklist](audit/GAME_WHITELISTING_CHECKLIST_OPUS4.5.md) - OpenPlay whitelisting verification

## Dependencies

- [Sui Framework](https://github.com/MystenLabs/sui) - Blockchain framework
- [OpenPlay Core](https://github.com/OpenPlay-Technologies/openplay-core) - Gaming infrastructure

## License

See LICENSE file for details.

