module sui_workshop_rate_limiter::simple_faucet_tests;

use std::unit_test::{destroy, assert_eq};
use sui::clock;
use sui::coin;
use sui::sui::SUI;
use sui::test_scenario as ts;
use sui_workshop_rate_limiter::simple_faucet::{Self, Faucet};

const USER: address = @0xA;

#[test]
fun faucet_global_throttle() {
    let mut scenario = ts::begin(USER);
    let mut clock = clock::create_for_testing(scenario.ctx());

    let initial_deposit = coin::mint_for_testing<SUI>(10_000, scenario.ctx());
    simple_faucet::new(initial_deposit, &clock, scenario.ctx());
    scenario.next_tx(USER);

    let mut faucet = scenario.take_shared<Faucet>();

    // The bucket starts full at 100, shared across all claimers.
    assert_eq!(faucet.claimable_now(&clock), 100);
    // Drain it completely: 100 claims of 1 SUI each.
    let mut i: u64 = 0;
    while (i < 100) {
        destroy(faucet.claim(&clock, scenario.ctx()));
        i = i + 1;
    };
    assert_eq!(faucet.claimable_now(&clock), 0);

    // The bucket refills 10 every minute, in whole-interval steps: nothing accrues mid-minute.
    clock.increment_for_testing(59_000);
    assert_eq!(faucet.claimable_now(&clock), 0);
    // One full minute -> 10, two more minutes -> 30.
    clock.increment_for_testing(1_000);
    assert_eq!(faucet.claimable_now(&clock), 10);
    clock.increment_for_testing(120_000);
    assert_eq!(faucet.claimable_now(&clock), 30);

    ts::return_shared(faucet);
    clock::destroy_for_testing(clock);
    scenario.end();
}
