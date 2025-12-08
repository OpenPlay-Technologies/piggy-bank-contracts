#[test_only]
module piggy_bank::game_tests;

use openplay_core::balance_manager;
use openplay_core::core_test_utils::create_and_fix_random;
use openplay_core::transaction::{bet, win};
use piggy_bank::constants::{
    start_game_action,
    advance_action,
    cash_out_action,
    game_finished_status,
    game_ongoing_status,
    empty_position
};
use piggy_bank::context;
use piggy_bank::game::{Self, new_interact};
use piggy_bank::test_utils::{default_game, always_die_game, always_win_game};
use std::unit_test::destroy;
use std::uq32_32::{int_mul, from_quotient};
use sui::random::Random;
use sui::test_scenario::{begin, return_shared};

#[test]
public fun success_instant_lose() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_die_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 100_000);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_finished_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == empty_position());

    // Validate transactions
    assert!(interact.transactions() == vector[bet(100_000)]);

    destroy(game);
    destroy(param_store);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_start_win() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_win_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 100_000);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_ongoing_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == 0);

    // Validate transactions
    assert!(interact.transactions() == vector[bet(100_000)]);

    destroy(game);
    destroy(param_store);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_cash_out() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, 0, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(cash_out_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    let expected_win = int_mul(100_000, game.payout_factor(&param_store, 0));
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_finished_status());
    assert!(context.get_win() == expected_win);
    assert!(context.current_position() == 0);

    // Validate transactions
    assert!(interact.transactions() == vector[win(expected_win)]);

    destroy(game);
    destroy(param_store);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_cash_out_invalid_pos() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, 2, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(cash_out_action(), balance_manager.id(), 100_000);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    let expected_win = 800_000;
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_finished_status());
    assert!(context.get_win() == expected_win);
    assert!(context.current_position() == 2);

    // Validate transactions
    assert!(interact.transactions() == vector[win(expected_win)]);

    destroy(param_store);
    destroy(game);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_advance_start_0() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_win_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, 0, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(advance_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_ongoing_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == 1);

    // Validate transactions
    assert!(interact.transactions() == vector[]);

    destroy(game);
    destroy(param_store);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_advance_start_1() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_win_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, 1, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(advance_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_ongoing_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == 2);

    // Validate transactions
    assert!(interact.transactions() == vector[]);

    destroy(game);
    destroy(param_store);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_win() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_win_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, 2, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(advance_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    let expected_win = game.max_payout(&param_store, 100_000);
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_finished_status());
    assert!(context.get_win() == expected_win);
    assert!(context.current_position() == 3);

    // Validate transactions
    assert!(interact.transactions() == vector[win(expected_win)]);

    destroy(game);
    destroy(param_store);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_new_game_after_win() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_win_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 100_000, 2, game_finished_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 200_000);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 200_000);
    assert!(context.status() == game_ongoing_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == 0);

    // Validate transactions
    assert!(interact.transactions() == vector[bet(200_000)]);

    destroy(game);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);
    destroy(param_store);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_instant_loss_after_win() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_die_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 100_000, 2, game_finished_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 200_000);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 200_000);
    assert!(context.status() == game_finished_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == empty_position());

    // Validate transactions
    assert!(interact.transactions() == vector[bet(200_000)]);

    destroy(game);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);
    destroy(param_store);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_new_game_after_loss() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_win_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, empty_position(), game_finished_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 200_000);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 200_000);
    assert!(context.status() == game_ongoing_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == 0);

    // Validate transactions
    assert!(interact.transactions() == vector[bet(200_000)]);

    destroy(game);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);
    destroy(param_store);

    return_shared(rand);
    scenario.end();
}

#[test]
public fun success_advance_die() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, house, admin_cap, param_store) = always_die_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100_000, 0, 0, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(advance_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);

    // Validate context
    let context = game.get_context_ref(&balance_manager);
    assert!(context.stake() == 100_000);
    assert!(context.status() == game_finished_status());
    assert!(context.get_win() == 0);
    assert!(context.current_position() == 0);

    // Validate transactions
    assert!(interact.transactions() == vector[]);

    destroy(game);
    destroy(balance_manager);
    destroy(balance_manager_cap);
    destroy(admin_cap);
    destroy(house);
    destroy(param_store);

    return_shared(rand);
    scenario.end();
}

#[test, expected_failure(abort_code = game::EGameNotInProgress)]
public fun fail_advance_after_finish() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, _house, _admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, _balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100, 0, 0, game_finished_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(advance_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);
    abort 0
}

#[test, expected_failure(abort_code = game::ECannotAdvanceFurther)]
public fun fail_advance_invalid_position() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, _house, _admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, _balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100, 0, 99, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(advance_action(), balance_manager.id(), 0);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);
    abort 0
}

#[test, expected_failure(abort_code = game::EGameAlreadyOngoing)]
public fun fail_start_game_while_ongoing() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, _house, _admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, _balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100, 0, 99, game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 100);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);
    abort 0
}

#[test, expected_failure(abort_code = game::EInvalidCashOut)]
public fun fail_cash_out_empty_pos() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, _house, _admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, _balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100, 0, empty_position(), game_ongoing_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(cash_out_action(), balance_manager.id(), 100);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);
    abort 0
}

#[test, expected_failure(abort_code = game::EGameNotInProgress)]
public fun fail_cash_out_game_finished() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, _house, _admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, _balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Fix context
    let context = context::create_for_testing(100, 0, 1, game_finished_status());
    game.fix_context_for_testing(balance_manager.id(), context);

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(cash_out_action(), balance_manager.id(), 100);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);
    abort 0
}

#[test, expected_failure(abort_code = game::EUnsupportedStake)]
public fun fail_unsupported_stake() {
    // We create and fix random
    create_and_fix_random(x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1C");

    // Start scenario
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (mut game, _house, _admin_cap, param_store) = default_game(scenario.ctx());

    // Create a balance manager
    let (balance_manager, _balance_manager_cap) = balance_manager::new(scenario.ctx());

    // Internal interact
    let rand = scenario.take_shared<Random>();
    let mut rand_generator = rand.new_generator(scenario.ctx());
    let mut interact = new_interact(start_game_action(), balance_manager.id(), 10_000_000 + 1);
    game.interact_int(&param_store, &mut interact, &mut rand_generator);
    abort 0
}

#[test]
public fun correct_props() {
    let addr = @0xa;
    let mut scenario = begin(addr);

    // Create the game
    let (game, house, admin_cap, param_store) = default_game(scenario.ctx());

    // Payout factor
    assert!(game.payout_factor(&param_store, 0) == from_quotient(20_000, 10_000));
    assert!(game.payout_factor(&param_store, 3) == from_quotient(160_000, 10_000));

    // Max step
    assert!(game.max_step_index(&param_store) == 3);

    // Stake
    assert!(game.max_stake(&param_store) == 10_000_000);
    assert!(game.min_stake(&param_store) == 0);

    destroy(game);
    destroy(param_store);
    destroy(admin_cap);
    destroy(house);
    scenario.end();
}
