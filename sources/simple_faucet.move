/// Example 1 — Faucet with a single, globally applied bucket rate limiter.
///
/// One `RateLimiter` field on a shared `Faucet` throttles *all* claimers collectively: every
/// caller draws from the same token bucket, which holds at most 100 coins and refills 10 every
/// minute. Claiming is permissionless — the limiter alone governs throughput.
module sui_workshop_rate_limiter::simple_faucet;

use openzeppelin_utils::rate_limiter::{Self, RateLimiter};
use sui::balance::Balance;
use sui::clock::Clock;
use sui::coin::{Self, Coin};
use sui::sui::SUI;

/// Shared faucet holding pooled funds behind one global bucket limiter.
public struct Faucet has key {
    id: UID,
    balance: Balance<SUI>,
    limiter: RateLimiter,
}

/// Share a faucet throttled by a single global token bucket: at most 100 coins outstanding,
/// refilling 10 every minute, starting full.
public fun new(initial_deposit: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
    sui::transfer::share_object(Faucet {
        id: object::new(ctx),
        balance: initial_deposit.into_balance(),
        // 2. arm it: 100 / minute
        limiter: rate_limiter::new_bucket(
            100,
            10,
            60_000,
            100,
            clock.timestamp_ms(),
            clock,
        ),
    })
}

/// Deposit funds into the faucet (no rate limit on the way in).
public fun deposit(self: &mut Faucet, payment: Coin<SUI>) {
    self.balance.join(payment.into_balance());
}

/// Claim 1 SUI, charging the global limiter first. The rate-limit check runs before the
/// balance split, so a denied claim never touches `balance`.
public fun claim(self: &mut Faucet, clock: &Clock, ctx: &mut TxContext): Coin<SUI> {
    self.limiter.consume_or_abort(1, clock);
    coin::from_balance(self.balance.split(1), ctx)
}

/// How much the faucet will allow to be claimed right now (projects bucket refill on read).
public fun claimable_now(self: &Faucet, clock: &Clock): u64 {
    self.limiter.available(clock)
}
