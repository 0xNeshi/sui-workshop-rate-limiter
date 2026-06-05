module sui_workshop_rate_limiter::simple_faucet;

use sui::balance::Balance;
use sui::coin::{Self, Coin};

public struct SIMPLE_FAUCET has drop {}

public struct Faucet has key {
    id: UID,
    balance: Balance<SIMPLE_FAUCET>,
}

fun init(witness: SIMPLE_FAUCET, ctx: &mut TxContext) {
    let (mut currency, mut treasury_cap) = sui::coin_registry::new_currency_with_otw(
        witness,
        9,
        "SIMPLE_FAUCET",
        "Simple Faucet Token",
        "",
        "",
        ctx,
    );
    let balance = treasury_cap.mint_balance(10_000);
    currency.make_supply_fixed(treasury_cap);
    let metadata_cap = currency.finalize(ctx);
    transfer::public_freeze_object(metadata_cap);

    sui::transfer::share_object(Faucet {
        id: object::new(ctx),
        balance,
    })
}

public fun claim(self: &mut Faucet, amount: u64, ctx: &mut TxContext): Coin<SIMPLE_FAUCET> {
    coin::from_balance(self.balance.split(amount), ctx)
}

public fun balance(self: &Faucet): u64 {
    self.balance.value()
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(SIMPLE_FAUCET {}, ctx)
}
