#[test_only]
module piggy_bank::test_utils;

use openplay_core::house::{Self, House, HouseAdminCap};
use openplay_core::parameter_store::ParameterStore;
use openplay_core::registry::registry_for_testing;
use piggy_bank::game::{Self, Game, get_admin_cap_for_testing};
use sui::test_utils::destroy;

public fun default_game(ctx: &mut TxContext): (Game, House, HouseAdminCap, ParameterStore) {
    let cap = get_admin_cap_for_testing(ctx);
    let mut registry = registry_for_testing(ctx);
    let (game, param_store, stats) = game::admin_create(
        &cap,
        &mut registry,
        0,
        10_000_000,
        5_000,
        vector[20_000, 40_000, 80_000, 160_000],
        ctx,
    );

    let (house, house_admin_cap) = house::new_for_testing(false, 10_000_000, 50, ctx);

    destroy(cap);
    destroy(registry);
    destroy(stats);

    (game, house, house_admin_cap, param_store)
}

public fun always_die_game(ctx: &mut TxContext): (Game, House, HouseAdminCap, ParameterStore) {
    let cap = get_admin_cap_for_testing(ctx);
    let mut registry = registry_for_testing(ctx);
    let (game, param_store, stats) = game::admin_create(
        &cap,
        &mut registry,
        0,
        10_000_000,
        0,
        vector[20_000, 40_000, 80_000, 160_000],
        ctx,
    );

    let (house, house_admin_cap) = house::new_for_testing(false, 10_000_000, 50, ctx);

    destroy(cap);
    destroy(registry);
    destroy(stats);

    (game, house, house_admin_cap, param_store)
}

public fun always_win_game(ctx: &mut TxContext): (Game, House, HouseAdminCap, ParameterStore) {
    let cap = get_admin_cap_for_testing(ctx);
    let mut registry = registry_for_testing(ctx);

    let (game, param_store, stats) = game::admin_create(
        &cap,
        &mut registry,
        0,
        10_000_000,
        10_000,
        vector[20_000, 40_000, 80_000, 160_000],
        ctx,
    );

    let (house, house_admin_cap) = house::new_for_testing(false, 10_000_000, 50, ctx);

    destroy(cap);
    destroy(registry);
    destroy(stats);

    (game, house, house_admin_cap, param_store)
}
