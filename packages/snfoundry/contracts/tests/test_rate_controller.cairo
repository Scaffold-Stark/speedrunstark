use snforge_std::{declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address};
use starknet::{ContractAddress, contract_address_const};
use core::traits::TryInto;

use contracts::{
    MyUSD::MyUSDDispatcher, MyUSD::MyUSDDispatcherTrait,
    MyUSDEngine::MyUSDEngineDispatcher, MyUSDEngine::MyUSDEngineDispatcherTrait,
    MyUSDStaking::MyUSDStakingDispatcher, MyUSDStaking::MyUSDStakingDispatcherTrait,
    RateController::RateControllerDispatcher, RateController::RateControllerDispatcherTrait,
};

// Constants
const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

#[test]
fn test_rate_controller_deployment() {
    let (rate_controller, accounts) = deploy_rate_controller();
    let (owner, user1, user2) = accounts;

    // Rate controller should be deployed successfully
    assert(rate_controller.contract_address() != 0.try_into().unwrap(), 'Rate controller should be deployed');
}

#[test]
fn test_set_borrow_rate() {
    let (rate_controller, engine, accounts) = deploy_rate_controller_with_engine();
    let (owner, user1, user2) = accounts;

    let new_rate = 500; // 5%
    rate_controller.set_borrow_rate(new_rate);

    assert(engine.get_borrow_rate() == new_rate, 'Borrow rate should be set');
}

#[test]
fn test_set_savings_rate() {
    let (rate_controller, staking, accounts) = deploy_rate_controller_with_staking();
    let (owner, user1, user2) = accounts;

    let new_rate = 300; // 3%
    rate_controller.set_savings_rate(new_rate);

    assert(staking.savings_rate() == new_rate, 'Savings rate should be set');
}

#[test]
fn test_set_borrow_rate_multiple_times() {
    let (rate_controller, engine, accounts) = deploy_rate_controller_with_engine();
    let (owner, user1, user2) = accounts;

    // Set initial rate
    let rate1 = 400; // 4%
    rate_controller.set_borrow_rate(rate1);
    assert(engine.get_borrow_rate() == rate1, 'First rate should be set');

    // Change rate
    let rate2 = 600; // 6%
    rate_controller.set_borrow_rate(rate2);
    assert(engine.get_borrow_rate() == rate2, 'Second rate should be set');

    // Change rate again
    let rate3 = 800; // 8%
    rate_controller.set_borrow_rate(rate3);
    assert(engine.get_borrow_rate() == rate3, 'Third rate should be set');
}

#[test]
fn test_set_savings_rate_multiple_times() {
    let (rate_controller, staking, accounts) = deploy_rate_controller_with_staking();
    let (owner, user1, user2) = accounts;

    // Set initial rate
    let rate1 = 200; // 2%
    rate_controller.set_savings_rate(rate1);
    assert(staking.savings_rate() == rate1, 'First rate should be set');

    // Change rate
    let rate2 = 400; // 4%
    rate_controller.set_savings_rate(rate2);
    assert(staking.savings_rate() == rate2, 'Second rate should be set');

    // Change rate again
    let rate3 = 600; // 6%
    rate_controller.set_savings_rate(rate3);
    assert(staking.savings_rate() == rate3, 'Third rate should be set');
}

#[test]
fn test_set_rates_zero() {
    let (rate_controller, engine, staking, accounts) = deploy_rate_controller_with_both();
    let (owner, user1, user2) = accounts;

    // Set rates to zero
    rate_controller.set_borrow_rate(0);
    rate_controller.set_savings_rate(0);

    assert(engine.get_borrow_rate() == 0, 'Borrow rate should be 0');
    assert(staking.savings_rate() == 0, 'Savings rate should be 0');
}

#[test]
fn test_set_rates_high_values() {
    let (rate_controller, engine, staking, accounts) = deploy_rate_controller_with_both();
    let (owner, user1, user2) = accounts;

    // Set high rates
    let high_borrow_rate = 5000; // 50%
    let high_savings_rate = 4000; // 40%

    rate_controller.set_borrow_rate(high_borrow_rate);
    rate_controller.set_savings_rate(high_savings_rate);

    assert(engine.get_borrow_rate() == high_borrow_rate, 'High borrow rate should be set');
    assert(staking.savings_rate() == high_savings_rate, 'High savings rate should be set');
}

#[test]
fn test_rate_controller_integration() {
    let (rate_controller, engine, staking, accounts) = deploy_rate_controller_with_both();
    let (owner, user1, user2) = accounts;

    // Set borrow rate first
    let borrow_rate = 1000; // 10%
    rate_controller.set_borrow_rate(borrow_rate);
    assert(engine.get_borrow_rate() == borrow_rate, 'Borrow rate should be set');

    // Set savings rate (should be less than borrow rate)
    let savings_rate = 800; // 8%
    rate_controller.set_savings_rate(savings_rate);
    assert(staking.savings_rate() == savings_rate, 'Savings rate should be set');

    // Verify both rates are set correctly
    assert(engine.get_borrow_rate() == borrow_rate, 'Borrow rate should remain set');
    assert(staking.savings_rate() == savings_rate, 'Savings rate should remain set');
}

#[test]
fn test_rate_controller_sequential_updates() {
    let (rate_controller, engine, staking, accounts) = deploy_rate_controller_with_both();
    let (owner, user1, user2) = accounts;

    // Sequential updates
    rate_controller.set_borrow_rate(500);
    rate_controller.set_savings_rate(300);
    assert(engine.get_borrow_rate() == 500, 'Borrow rate should be 500');
    assert(staking.savings_rate() == 300, 'Savings rate should be 300');

    rate_controller.set_borrow_rate(700);
    rate_controller.set_savings_rate(500);
    assert(engine.get_borrow_rate() == 700, 'Borrow rate should be 700');
    assert(staking.savings_rate() == 500, 'Savings rate should be 500');

    rate_controller.set_borrow_rate(1000);
    rate_controller.set_savings_rate(800);
    assert(engine.get_borrow_rate() == 1000, 'Borrow rate should be 1000');
    assert(staking.savings_rate() == 800, 'Savings rate should be 800');
}

#[test]
fn test_rate_controller_edge_cases() {
    let (rate_controller, engine, staking, accounts) = deploy_rate_controller_with_both();
    let (owner, user1, user2) = accounts;

    // Test with maximum reasonable values
    let max_rate = 10000; // 100%
    rate_controller.set_borrow_rate(max_rate);
    rate_controller.set_savings_rate(max_rate);

    assert(engine.get_borrow_rate() == max_rate, 'Max borrow rate should be set');
    assert(staking.savings_rate() == max_rate, 'Max savings rate should be set');
}

// Helper function to deploy RateController
fn deploy_rate_controller() -> (RateControllerDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy RateController with placeholder addresses
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![owner.into(), owner.into()]).unwrap();

    (rate_controller, (owner, user1, user2))
}

// Helper function to deploy RateController with MyUSDEngine
fn deploy_rate_controller_with_engine() -> (RateControllerDispatcher, MyUSDEngineDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
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
    let oracle = oracle_class.deploy(@array![dex.contract_address().into(), default_price.into()]).unwrap();

    let staking_class = declare("MyUSDStaking");
    let staking = staking_class.deploy(@array![
        owner.into(),
        myusd.contract_address().into(),
        owner.into(), // placeholder for engine
        owner.into()  // placeholder for rate controller
    ]).unwrap();

    // Deploy MyUSDEngine
    let engine_class = declare("MyUSDEngine");
    let engine = engine_class.deploy(@array![
        owner.into(),
        oracle.contract_address().into(),
        myusd.contract_address().into(),
        staking.contract_address().into(),
        owner.into() // placeholder for rate controller
    ]).unwrap();

    // Deploy RateController
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![
        engine.contract_address().into(),
        staking.contract_address().into()
    ]).unwrap();

    (rate_controller, engine, (owner, user1, user2))
}

// Helper function to deploy RateController with MyUSDStaking
fn deploy_rate_controller_with_staking() -> (RateControllerDispatcher, MyUSDStakingDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy MyUSDStaking
    let staking_class = declare("MyUSDStaking");
    let staking = staking_class.deploy(@array![
        owner.into(),
        myusd.contract_address().into(),
        owner.into(), // placeholder for engine
        owner.into()  // placeholder for rate controller
    ]).unwrap();

    // Deploy RateController
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![
        owner.into(), // placeholder for engine
        staking.contract_address().into()
    ]).unwrap();

    (rate_controller, staking, (owner, user1, user2))
}

// Helper function to deploy RateController with both MyUSDEngine and MyUSDStaking
fn deploy_rate_controller_with_both() -> (RateControllerDispatcher, MyUSDEngineDispatcher, MyUSDStakingDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
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
    let oracle = oracle_class.deploy(@array![dex.contract_address().into(), default_price.into()]).unwrap();

    // Deploy MyUSDStaking
    let staking_class = declare("MyUSDStaking");
    let staking = staking_class.deploy(@array![
        owner.into(),
        myusd.contract_address().into(),
        owner.into(), // placeholder for engine
        owner.into()  // placeholder for rate controller
    ]).unwrap();

    // Deploy MyUSDEngine
    let engine_class = declare("MyUSDEngine");
    let engine = engine_class.deploy(@array![
        owner.into(),
        oracle.contract_address().into(),
        myusd.contract_address().into(),
        staking.contract_address().into(),
        owner.into() // placeholder for rate controller
    ]).unwrap();

    // Deploy RateController
    let rate_controller_class = declare("RateController");
    let rate_controller = rate_controller_class.deploy(@array![
        engine.contract_address().into(),
        staking.contract_address().into()
    ]).unwrap();

    (rate_controller, engine, staking, (owner, user1, user2))
}

