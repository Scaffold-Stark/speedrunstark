use snforge_std::{declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_block_timestamp, stop_cheat_block_timestamp};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use core::traits::TryInto;

use contracts::{
    MyUSD::MyUSDDispatcher, MyUSD::MyUSDDispatcherTrait,
    MyUSDStaking::MyUSDStakingDispatcher, MyUSDStaking::MyUSDStakingDispatcherTrait,
    MyUSDEngine::MyUSDEngineDispatcher, MyUSDEngine::MyUSDEngineDispatcherTrait,
    RateController::RateControllerDispatcher, RateController::RateControllerDispatcherTrait,
};

// Constants
const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
const STAKE_AMOUNT: u256 = 1000 * PRECISION; // 1000 MyUSD

#[test]
fn test_staking_deployment() {
    let (staking, accounts) = deploy_staking();
    let (owner, user1, user2) = accounts;

    assert(staking.savings_rate() == 0, 'Staking should start with 0 savings rate');
    assert(staking.get_total_staked() == 0, 'Total staked should start at 0');
    assert(staking.get_balance(user1) == 0, 'User balance should start at 0');
}

#[test]
fn test_stake() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Give user1 some MyUSD tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    // Stake tokens
    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(staking.get_balance(user1) == STAKE_AMOUNT, 'User should have staked balance');
    assert(staking.get_total_staked() == STAKE_AMOUNT, 'Total staked should be updated');
}

#[test]
fn test_stake_zero_amount() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Give user1 some MyUSD tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    // Try to stake 0 amount
    start_cheat_caller_address(user1);
    // This should emit an error event
    staking.stake(0);
    stop_cheat_caller_address(user1);

    assert(staking.get_balance(user1) == 0, 'User balance should remain 0');
}

#[test]
fn test_stake_insufficient_balance() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Give user1 some MyUSD tokens but less than stake amount
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT / 2);
    stop_cheat_caller_address(owner);

    // Try to stake more than balance
    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    // This should emit an error event
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(staking.get_balance(user1) == 0, 'User balance should remain 0');
}

#[test]
fn test_stake_insufficient_allowance() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Give user1 some MyUSD tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    // Approve less than stake amount
    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT / 2);
    // This should emit an error event
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(staking.get_balance(user1) == 0, 'User balance should remain 0');
}

#[test]
fn test_multiple_stakes() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Give user1 some MyUSD tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT * 2);
    stop_cheat_caller_address(owner);

    // First stake
    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    let balance_after_first = staking.get_balance(user1);

    // Second stake
    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    let balance_after_second = staking.get_balance(user1);

    assert(balance_after_first == STAKE_AMOUNT, 'First stake should be recorded');
    assert(balance_after_second == STAKE_AMOUNT * 2, 'Second stake should be added');
}

#[test]
fn test_withdraw() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    let initial_balance = myusd.balance_of(user1);

    // Withdraw
    start_cheat_caller_address(user1);
    staking.withdraw();
    stop_cheat_caller_address(user1);

    let final_balance = myusd.balance_of(user1);
    assert(staking.get_balance(user1) == 0, 'User balance should be 0 after withdrawal');
    assert(final_balance > initial_balance, 'User should receive tokens back');
}

#[test]
fn test_withdraw_no_balance() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Try to withdraw with no balance
    start_cheat_caller_address(user2);
    // This should emit an error event
    staking.withdraw();
    stop_cheat_caller_address(user2);

    assert(staking.get_balance(user2) == 0, 'User balance should remain 0');
}

#[test]
fn test_set_savings_rate() {
    let (staking, accounts) = deploy_staking();
    let (owner, user1, user2) = accounts;

    let new_rate = 300; // 3%
    start_cheat_caller_address(owner);
    staking.set_savings_rate(new_rate);
    stop_cheat_caller_address(owner);

    assert(staking.savings_rate() == new_rate, 'Savings rate should be set');
}

#[test]
fn test_set_savings_rate_unauthorized() {
    let (staking, accounts) = deploy_staking();
    let (owner, user1, user2) = accounts;

    let new_rate = 300; // 3%
    start_cheat_caller_address(user1);
    // This should emit an error event
    staking.set_savings_rate(new_rate);
    stop_cheat_caller_address(user1);

    assert(staking.savings_rate() == 0, 'Savings rate should remain unchanged');
}

#[test]
fn test_set_savings_rate_above_borrow_rate() {
    let (staking, myusd, engine, rate_controller, accounts) = deploy_staking_with_engine();
    let (owner, user1, user2) = accounts;

    // Set borrow rate to 4%
    rate_controller.set_borrow_rate(400);

    // Try to set savings rate to 5% (above borrow rate)
    start_cheat_caller_address(owner);
    // This should emit an error event
    staking.set_savings_rate(500);
    stop_cheat_caller_address(owner);

    assert(staking.savings_rate() == 0, 'Savings rate should remain unchanged');
}

#[test]
fn test_interest_accrual_no_rate() {
    let (staking, myusd, accounts) = deploy_staking_with_myusd();
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    let initial_balance = staking.get_balance(user1);

    // Fast forward time by 1 year
    start_cheat_block_timestamp(get_block_timestamp() + 365 * 24 * 60 * 60);
    let final_balance = staking.get_balance(user1);
    stop_cheat_block_timestamp();

    assert(final_balance == initial_balance, 'Balance should not change with 0 savings rate');
}

#[test]
fn test_interest_accrual_with_rate() {
    let (staking, myusd, engine, rate_controller, accounts) = deploy_staking_with_engine();
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    // Set rates
    rate_controller.set_borrow_rate(1000); // 10%
    rate_controller.set_savings_rate(800); // 8%

    let initial_balance = staking.get_balance(user1);

    // Fast forward time by 1 year
    start_cheat_block_timestamp(get_block_timestamp() + 365 * 24 * 60 * 60);
    let final_balance = staking.get_balance(user1);
    stop_cheat_block_timestamp();

    assert(final_balance > initial_balance, 'Balance should increase with savings rate');
}

#[test]
fn test_interest_accrual_partial_time() {
    let (staking, myusd, engine, rate_controller, accounts) = deploy_staking_with_engine();
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    // Set rates
    rate_controller.set_borrow_rate(1200); // 12%
    rate_controller.set_savings_rate(900); // 9%

    let initial_balance = staking.get_balance(user1);

    // Fast forward time by 6 months
    start_cheat_block_timestamp(get_block_timestamp() + 182 * 24 * 60 * 60);
    let final_balance = staking.get_balance(user1);
    stop_cheat_block_timestamp();

    assert(final_balance > initial_balance, 'Balance should increase with partial time interest');
}

#[test]
fn test_interest_accrual_multiple_periods() {
    let (staking, myusd, engine, rate_controller, accounts) = deploy_staking_with_engine();
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, STAKE_AMOUNT);
    stop_cheat_caller_address(owner);

    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), STAKE_AMOUNT);
    staking.stake(STAKE_AMOUNT);
    stop_cheat_caller_address(user1);

    // Set initial rates
    rate_controller.set_borrow_rate(600); // 6%
    rate_controller.set_savings_rate(400); // 4%

    let initial_balance = staking.get_balance(user1);

    // Fast forward 3 months
    start_cheat_block_timestamp(get_block_timestamp() + 91 * 24 * 60 * 60);
    let mid_balance = staking.get_balance(user1);
    stop_cheat_block_timestamp();

    // Change rates
    rate_controller.set_borrow_rate(1000); // 10%
    rate_controller.set_savings_rate(700); // 7%

    // Fast forward another 3 months
    start_cheat_block_timestamp(get_block_timestamp() + 91 * 24 * 60 * 60);
    let final_balance = staking.get_balance(user1);
    stop_cheat_block_timestamp();

    assert(mid_balance > initial_balance, 'Balance should increase in first period');
    assert(final_balance > mid_balance, 'Balance should increase in second period');
}

// Helper function to deploy MyUSDStaking
fn deploy_staking() -> (MyUSDStakingDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy RateController
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![owner.into(), owner.into()]).unwrap();

    // Deploy MyUSDStaking
    let staking_class = declare("MyUSDStaking");
    let staking = staking_class.deploy(@array![
        owner.into(),
        myusd.contract_address().into(),
        owner.into(), // placeholder for engine
        rate_controller.contract_address().into()
    ]).unwrap();

    (staking, (owner, user1, user2))
}

// Helper function to deploy MyUSDStaking with MyUSD token
fn deploy_staking_with_myusd() -> (MyUSDStakingDispatcher, MyUSDDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy RateController
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![owner.into(), owner.into()]).unwrap();

    // Deploy MyUSDStaking
    let staking_class = declare("MyUSDStaking");
    let staking = staking_class.deploy(@array![
        owner.into(),
        myusd.contract_address().into(),
        owner.into(), // placeholder for engine
        rate_controller.contract_address().into()
    ]).unwrap();

    (staking, myusd, (owner, user1, user2))
}

// Helper function to deploy MyUSDStaking with engine
fn deploy_staking_with_engine() -> (MyUSDStakingDispatcher, MyUSDDispatcher, MyUSDEngineDispatcher, RateControllerDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy dependencies
    let dex_class = declare("DEX");
    let dex = dex_class.deploy(@array![myusd.contract_address().into()]).unwrap();

    let oracle_class = declare("Oracle");
    let default_price = 2000 * PRECISION; // $2000 default
    let oracle = oracle_class.deploy(@array![dex.contract_address().into(), default_price.into()]).unwrap();

    // Deploy RateController
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![owner.into(), owner.into()]).unwrap();

    // Deploy MyUSDStaking
    let staking_class = declare("MyUSDStaking");
    let staking = staking_class.deploy(@array![
        owner.into(),
        myusd.contract_address().into(),
        owner.into(), // placeholder for engine
        rate_controller.contract_address().into()
    ]).unwrap();

    // Deploy MyUSDEngine
    let engine_class = declare("MyUSDEngine");
    let engine = engine_class.deploy(@array![
        owner.into(),
        oracle.contract_address().into(),
        myusd.contract_address().into(),
        staking.contract_address().into(),
        rate_controller.contract_address().into()
    ]).unwrap();

    (staking, myusd, engine, rate_controller, (owner, user1, user2))
}

