use contracts::DEX::{DEXDispatcher, DEXDispatcherTrait};
use contracts::MyUSD::{MyUSDDispatcher, MyUSDDispatcherTrait};
use contracts::MyUSDEngine::{MyUSDEngineDispatcher, MyUSDEngineDispatcherTrait};
use contracts::MyUSDStaking::{MyUSDStakingDispatcher, MyUSDStakingDispatcherTrait};
use contracts::Oracle::{OracleDispatcher, OracleDispatcherTrait};
use contracts::RateController::{RateControllerDispatcher, RateControllerDispatcherTrait};
use core::traits::TryInto;
use snforge_std::{
    ContractClassTrait, declare, start_cheat_balance, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_balance, stop_cheat_block_timestamp,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp, get_caller_address};

// Constants
const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
const COLLATERAL_AMOUNT: u256 = 10 * PRECISION; // 10 STRK
const BORROW_AMOUNT: u256 = 5000 * PRECISION; // 5000 MyUSD
const STRK_CONTRACT: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

#[test]
fn test_deployment() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Test initial state
    assert(myusd.owner() == owner, 'Owner should be set correctly');
    assert(dex.total_liquidity() > 0, 'DEX should have liquidity');
    assert(oracle.get_strk_myusd_price() > 0, 'Oracle should return price');
    assert(engine.get_borrow_rate() == 0, 'Engine should start with 0 borrow rate');
    assert(staking.savings_rate() == 0, 'Staking should start with 0 savings rate');
}

#[test]
fn test_collateral_operations() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Test adding collateral
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_collateral(user1) == COLLATERAL_AMOUNT, 'User collateral should be set');

    // Test withdrawing collateral when no debt
    start_cheat_caller_address(user1);
    engine.withdraw_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_collateral(user1) == 0, 'User collateral should be withdrawn');
}

#[test]
fn test_borrowing_operations() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Add collateral first
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    // Test borrowing
    start_cheat_caller_address(user1);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_debt_shares(user1) == BORROW_AMOUNT, 'User debt shares should be set');
    assert(myusd.balance_of(user1) == BORROW_AMOUNT, 'User should receive MyUSD tokens');
}

#[test]
fn test_repayment_operations() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Setup: add collateral and borrow
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    // Test repaying
    start_cheat_caller_address(user1);
    myusd.approve(engine.contract_address(), BORROW_AMOUNT);
    engine.repay_up_to(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_debt_shares(user1) == 0, 'User debt should be repaid');
}

#[test]
fn test_rate_management() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Test setting borrow rate
    let new_rate = 500; // 5%
    rate_controller.set_borrow_rate(new_rate);
    assert(engine.get_borrow_rate() == new_rate, 'Borrow rate should be set');

    // Test setting savings rate
    let savings_rate = 300; // 3%
    rate_controller.set_savings_rate(savings_rate);
    assert(staking.savings_rate() == savings_rate, 'Savings rate should be set');
}

#[test]
fn test_staking_operations() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Setup: get some MyUSD tokens
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    // Test staking
    let stake_amount = 1000 * PRECISION;
    start_cheat_caller_address(user1);
    myusd.approve(staking.contract_address(), stake_amount);
    staking.stake(stake_amount);
    stop_cheat_caller_address(user1);

    assert(staking.get_balance(user1) == stake_amount, 'User should have staked balance');
}

#[test]
fn test_withdrawal_operations() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    myusd.approve(staking.contract_address(), 1000 * PRECISION);
    staking.stake(1000 * PRECISION);
    stop_cheat_caller_address(user1);

    let initial_balance = myusd.balance_of(user1);

    // Test withdrawal
    start_cheat_caller_address(user1);
    staking.withdraw();
    stop_cheat_caller_address(user1);

    let final_balance = myusd.balance_of(user1);
    assert(final_balance > initial_balance, 'User should receive tokens back');
}

#[test]
fn test_interest_accrual() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Setup: borrow some tokens
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    // Set borrow rate
    rate_controller.set_borrow_rate(1000); // 10%

    let initial_debt = engine.get_current_debt_value(user1);

    // Fast forward time by 1 year
    start_cheat_block_timestamp(get_block_timestamp() + 365 * 24 * 60 * 60);
    let final_debt = engine.get_current_debt_value(user1);
    stop_cheat_block_timestamp();

    assert(final_debt > initial_debt, 'Debt should increase with interest');
}

#[test]
fn test_savings_interest_accrual() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Setup: stake some tokens
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    myusd.approve(staking.contract_address(), 1000 * PRECISION);
    staking.stake(1000 * PRECISION);
    stop_cheat_caller_address(user1);

    // Set rates
    rate_controller.set_borrow_rate(1000); // 10%
    rate_controller.set_savings_rate(800); // 8%

    let initial_balance = staking.get_balance(user1);

    // Fast forward time by 1 year
    start_cheat_block_timestamp(get_block_timestamp() + 365 * 24 * 60 * 60);
    let final_balance = staking.get_balance(user1);
    stop_cheat_block_timestamp();

    assert(final_balance > initial_balance, 'Staked balance should increase with interest');
}

#[test]
fn test_liquidation() {
    let (contracts, accounts) = deploy_contracts();
    let (myusd, dex, engine, oracle, staking, rate_controller) = contracts;
    let (owner, user1, user2) = accounts;

    // Setup: create a position that can be liquidated
    let collateral_amount = 1 * PRECISION; // 1 STRK
    let borrow_amount = (oracle.get_strk_usd_price() * 1000)
        / 1505; // Just under liquidation threshold

    start_cheat_caller_address(user1);
    engine.add_collateral(collateral_amount);
    engine.mint_myusd(borrow_amount);
    stop_cheat_caller_address(user1);

    // Give user2 some MyUSD for liquidation
    start_cheat_caller_address(owner);
    myusd.mint(user2, borrow_amount * 10);
    stop_cheat_caller_address(owner);

    start_cheat_caller_address(user2);
    myusd.approve(engine.contract_address(), borrow_amount * 10);
    stop_cheat_caller_address(user2);

    // Test liquidation
    start_cheat_caller_address(user2);
    engine.liquidate(user1);
    stop_cheat_caller_address(user2);

    assert(
        engine.get_user_debt_shares(user1) == 0, 'User debt should be cleared after liquidation',
    );
}

// Helper function to deploy all contracts
fn deploy_contracts() -> (
    (
        MyUSDDispatcher,
        DEXDispatcher,
        MyUSDEngineDispatcher,
        OracleDispatcher,
        MyUSDStakingDispatcher,
        RateControllerDispatcher,
    ),
    (ContractAddress, ContractAddress, ContractAddress),
) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy RateController first (we'll use placeholder addresses)
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![owner.into()]).unwrap();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy DEX
    let dex_class = declare("DEX");
    let dex = dex_class.deploy(@array![myusd.contract_address().into()]).unwrap();

    // Deploy Oracle
    let oracle_class = declare("Oracle");
    let default_price = 2000 * PRECISION; // $2000 default
    let oracle = oracle_class
        .deploy(@array![dex.contract_address().into(), default_price.into()])
        .unwrap();

    // Deploy MyUSDStaking
    let staking_class = declare("MyUSDStaking");
    let staking = staking_class
        .deploy(
            @array![
                owner.into(), myusd.contract_address().into(),
                owner.into(), // placeholder for engine
                rate_controller.contract_address().into(),
            ],
        )
        .unwrap();

    // Deploy MyUSDEngine
    let engine_class = declare("MyUSDEngine");
    let engine = engine_class
        .deploy(
            @array![
                owner.into(), oracle.contract_address().into(), myusd.contract_address().into(),
                staking.contract_address().into(), rate_controller.contract_address().into(),
            ],
        )
        .unwrap();

    // Initialize DEX with liquidity
    start_cheat_caller_address(owner);
    let strk_amount = 1000 * PRECISION;
    let myusd_amount = oracle.get_strk_usd_price() * 1000;

    // Add collateral and mint MyUSD for DEX initialization
    engine.add_collateral(strk_amount);
    engine.mint_myusd(myusd_amount);

    // Initialize DEX
    myusd.approve(dex.contract_address(), myusd_amount);
    dex.init(myusd_amount, strk_amount);
    stop_cheat_caller_address(owner);

    ((myusd, dex, engine, oracle, staking, rate_controller), (owner, user1, user2))
}

