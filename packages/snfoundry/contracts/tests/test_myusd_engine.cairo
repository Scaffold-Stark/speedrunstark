use contracts::DEX::{DEXDispatcher, DEXDispatcherTrait};
use contracts::MyUSD::{MyUSDDispatcher, MyUSDDispatcherTrait};
use contracts::MyUSDEngine::{MyUSDEngineDispatcher, MyUSDEngineDispatcherTrait};
use contracts::MyUSDStaking::{MyUSDStakingDispatcher, MyUSDStakingDispatcherTrait};
use contracts::Oracle::{OracleDispatcher, OracleDispatcherTrait};
use contracts::RateController::{RateControllerDispatcher, RateControllerDispatcherTrait};
use core::traits::TryInto;
use snforge_std::{
    ContractClassTrait, declare, start_cheat_block_timestamp, start_cheat_caller_address,
    stop_cheat_block_timestamp, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

// Constants
const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
const COLLATERAL_AMOUNT: u256 = 10 * PRECISION; // 10 STRK
const BORROW_AMOUNT: u256 = 5000 * PRECISION; // 5000 MyUSD

#[test]
fn test_engine_deployment() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    assert(engine.get_borrow_rate() == 0, 'Engine should start with 0 borrow rate');
    assert(engine.get_user_collateral(user1) == 0, 'User should start with 0 collateral');
    assert(engine.get_user_debt_shares(user1) == 0, 'User should start with 0 debt');
}

#[test]
fn test_add_collateral() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_collateral(user1) == COLLATERAL_AMOUNT, 'User collateral should be set');
}

#[test]
fn test_add_collateral_zero_amount() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    start_cheat_caller_address(user1);
    // This should emit an error event
    engine.add_collateral(0);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_collateral(user1) == 0, 'User collateral should remain 0');
}

#[test]
fn test_withdraw_collateral() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral first
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    // Withdraw collateral
    start_cheat_caller_address(user1);
    engine.withdraw_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_collateral(user1) == 0, 'User collateral should be withdrawn');
}

#[test]
fn test_withdraw_collateral_insufficient() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral first
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    // Try to withdraw more than deposited
    start_cheat_caller_address(user1);
    // This should emit an error event
    engine.withdraw_collateral(COLLATERAL_AMOUNT * 2);
    stop_cheat_caller_address(user1);

    assert(
        engine.get_user_collateral(user1) == COLLATERAL_AMOUNT,
        'User collateral should remain unchanged',
    );
}

#[test]
fn test_mint_myusd() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral first
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    // Mint MyUSD
    start_cheat_caller_address(user1);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_debt_shares(user1) == BORROW_AMOUNT, 'User debt shares should be set');
}

#[test]
fn test_mint_myusd_zero_amount() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral first
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    // Try to mint 0 amount
    start_cheat_caller_address(user1);
    // This should emit an error event
    engine.mint_myusd(0);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_debt_shares(user1) == 0, 'User debt shares should remain 0');
}

#[test]
fn test_repay_up_to() {
    let (engine, accounts) = deploy_engine();
    let (myusd, engine, accounts) = deploy_engine_with_myusd();
    let (owner, user1, user2) = accounts;

    // Setup: add collateral and borrow
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    // Repay
    start_cheat_caller_address(user1);
    myusd.approve(engine.contract_address(), BORROW_AMOUNT);
    engine.repay_up_to(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    assert(engine.get_user_debt_shares(user1) == 0, 'User debt should be repaid');
}

#[test]
fn test_repay_up_to_partial() {
    let (engine, accounts) = deploy_engine();
    let (myusd, engine, accounts) = deploy_engine_with_myusd();
    let (owner, user1, user2) = accounts;

    // Setup: add collateral and borrow
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    // Repay partial amount
    let repay_amount = BORROW_AMOUNT / 2;
    start_cheat_caller_address(user1);
    myusd.approve(engine.contract_address(), repay_amount);
    engine.repay_up_to(repay_amount);
    stop_cheat_caller_address(user1);

    assert(
        engine.get_user_debt_shares(user1) == repay_amount, 'User debt should be partially repaid',
    );
}

#[test]
fn test_calculate_collateral_value() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    stop_cheat_caller_address(user1);

    let collateral_value = engine.calculate_collateral_value(user1);
    assert(collateral_value > 0, 'Collateral value should be calculated');
}

#[test]
fn test_get_current_debt_value() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral and borrow
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    let debt_value = engine.get_current_debt_value(user1);
    assert(debt_value > 0, 'Debt value should be calculated');
}

#[test]
fn test_calculate_position_ratio() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral and borrow
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    let position_ratio = engine.calculate_position_ratio(user1);
    assert(position_ratio > 0, 'Position ratio should be calculated');
}

#[test]
fn test_is_liquidatable() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    // Add collateral and borrow
    start_cheat_caller_address(user1);
    engine.add_collateral(COLLATERAL_AMOUNT);
    engine.mint_myusd(BORROW_AMOUNT);
    stop_cheat_caller_address(user1);

    let is_liquidatable = engine.is_liquidatable(user1);
    // Should be false initially (safe position)
    assert(is_liquidatable == false, 'Position should not be liquidatable initially');
}

#[test]
fn test_set_borrow_rate() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    let new_rate = 500; // 5%
    start_cheat_caller_address(owner);
    engine.set_borrow_rate(new_rate);
    stop_cheat_caller_address(owner);

    assert(engine.get_borrow_rate() == new_rate, 'Borrow rate should be set');
}

#[test]
fn test_set_borrow_rate_unauthorized() {
    let (engine, accounts) = deploy_engine();
    let (owner, user1, user2) = accounts;

    let new_rate = 500; // 5%
    start_cheat_caller_address(user1);
    // This should emit an error event
    engine.set_borrow_rate(new_rate);
    stop_cheat_caller_address(user1);

    assert(engine.get_borrow_rate() == 0, 'Borrow rate should remain unchanged');
}

// Helper function to deploy MyUSDEngine
fn deploy_engine() -> (MyUSDEngineDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy dependencies
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    let dex_class = declare("DEX");
    let dex = dex_class.deploy(@array![myusd.contract_address().into()]).unwrap();

    let oracle_class = declare("Oracle");
    let default_price = 2000 * PRECISION; // $2000 default
    let oracle = oracle_class
        .deploy(@array![dex.contract_address().into(), default_price.into()])
        .unwrap();

    let staking_class = declare("MyUSDStaking");
    let staking = staking_class
        .deploy(
            @array![
                owner.into(), myusd.contract_address().into(),
                owner.into(), // placeholder for engine
                owner.into() // placeholder for rate controller
            ],
        )
        .unwrap();

    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class
        .deploy(@array![owner.into(), owner.into()])
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

    (engine, (owner, user1, user2))
}

// Helper function to deploy MyUSDEngine with MyUSD token
fn deploy_engine_with_myusd() -> (
    MyUSDDispatcher, MyUSDEngineDispatcher, (ContractAddress, ContractAddress, ContractAddress),
) {
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
    let oracle = oracle_class
        .deploy(@array![dex.contract_address().into(), default_price.into()])
        .unwrap();

    let staking_class = declare("MyUSDStaking");
    let staking = staking_class
        .deploy(
            @array![
                owner.into(), myusd.contract_address().into(),
                owner.into(), // placeholder for engine
                owner.into() // placeholder for rate controller
            ],
        )
        .unwrap();

    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class
        .deploy(@array![owner.into(), owner.into()])
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

    (myusd, engine, (owner, user1, user2))
}

