module piggy_bank::constants;

use std::string::{String, utf8};

// === Constants ===
const MAX_STEPS: u8 = 50;
const EMPTY_POSITION: u8 = 255;
const MAX_PAYOUT_FACTOR_BPS: u64 = 100_000_000; // This is 10_000 times the stake or 1_000_000%

// === Public-View Functions ===
public fun empty_position(): u8 {
    EMPTY_POSITION
}

public fun max_steps(): u8 {
    MAX_STEPS
}

public fun max_payout_factor_bps(): u64 {
    MAX_PAYOUT_FACTOR_BPS
}

public fun new_status(): String {
    utf8(b"New")
}

public fun initialized_status(): String {
    utf8(b"Initialized")
}

public fun game_ongoing_status(): String {
    utf8(b"GameOngoing")
}

public fun game_finished_status(): String {
    utf8(b"GameFinished")
}

public fun start_game_action(): String {
    utf8(b"StartGame")
}

public fun advance_action(): String {
    utf8(b"Advance")
}

public fun cash_out_action(): String {
    utf8(b"CashOut")
}

public fun min_stake_param_name(): String {
    utf8(b"min_stake")
}

public fun max_stake_param_name(): String {
    utf8(b"max_stake")
}


public fun success_rate_bps_param_name(): String {
    utf8(b"success_rate_bps")
}


public fun steps_payout_bps_param_name(): String {
    utf8(b"steps_payout_bps")
}

