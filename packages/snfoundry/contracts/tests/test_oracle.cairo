use snforge_std::{declare, ContractClassTrait};
use starknet::{ContractAddress, contract_address_const};
use core::traits::TryInto;

use contracts::{
    MyUSD::MyUSDDispatcher, MyUSD::MyUSDDispatcherTrait,
    DEX::DEXDispatcher, DEX::DEXDispatcherTrait,
    Oracle::OracleDispatcher, Oracle::OracleDispatcherTrait,
};

// Constants
const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
const DEFAULT_PRICE: u256 = 2000 * PRECISION; // $2000 default

#[test]
fn test_oracle_deployment() {
    let (oracle, accounts) = deploy_oracle();
    let (owner, user1, user2) = accounts;

    assert(oracle.get_strk_usd_price() == DEFAULT_PRICE, 'Oracle should return default USD price');
}

#[test]
fn test_oracle_get_strk_myusd_price() {
    let (oracle, dex, accounts) = deploy_oracle_with_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX to get a price
    start_cheat_caller_address(owner);
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();
    
    let initial_myusd = 2000000 * PRECISION; // 2M MyUSD
    let initial_strk = 1000 * PRECISION; // 1000 STRK
    
    myusd.mint(owner, initial_myusd);
    myusd.approve(dex.contract_address(), initial_myusd);
    dex.init(initial_myusd, initial_strk);
    stop_cheat_caller_address(owner);

    let price = oracle.get_strk_myusd_price();
    assert(price > 0, 'Oracle should return STRK/MyUSD price from DEX');
}

#[test]
fn test_oracle_get_strk_myusd_price_fallback() {
    let (oracle, accounts) = deploy_oracle();
    let (owner, user1, user2) = accounts;

    // When DEX returns 0 price, should fallback to default
    let price = oracle.get_strk_myusd_price();
    assert(price == DEFAULT_PRICE, 'Oracle should fallback to default price when DEX returns 0');
}

#[test]
fn test_oracle_get_strk_usd_price() {
    let (oracle, accounts) = deploy_oracle();
    let (owner, user1, user2) = accounts;

    let usd_price = oracle.get_strk_usd_price();
    assert(usd_price == DEFAULT_PRICE, 'Oracle should return default USD price');
}

#[test]
fn test_oracle_price_consistency() {
    let (oracle, dex, accounts) = deploy_oracle_with_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();
    
    let initial_myusd = 2000000 * PRECISION; // 2M MyUSD
    let initial_strk = 1000 * PRECISION; // 1000 STRK
    
    myusd.mint(owner, initial_myusd);
    myusd.approve(dex.contract_address(), initial_myusd);
    dex.init(initial_myusd, initial_strk);
    stop_cheat_caller_address(owner);

    // Get price multiple times
    let price1 = oracle.get_strk_myusd_price();
    let price2 = oracle.get_strk_myusd_price();
    let price3 = oracle.get_strk_myusd_price();

    assert(price1 == price2, 'Price should be consistent');
    assert(price2 == price3, 'Price should be consistent');
}

#[test]
fn test_oracle_with_different_dex_prices() {
    let (oracle, dex, accounts) = deploy_oracle_with_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX with different ratios
    start_cheat_caller_address(owner);
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();
    
    let initial_myusd = 1000000 * PRECISION; // 1M MyUSD (lower)
    let initial_strk = 1000 * PRECISION; // 1000 STRK
    
    myusd.mint(owner, initial_myusd);
    myusd.approve(dex.contract_address(), initial_myusd);
    dex.init(initial_myusd, initial_strk);
    stop_cheat_caller_address(owner);

    let price1 = oracle.get_strk_myusd_price();

    // Change DEX liquidity to affect price
    start_cheat_caller_address(user1);
    dex.deposit(500 * PRECISION); // Add more STRK
    stop_cheat_caller_address(user1);

    let price2 = oracle.get_strk_myusd_price();

    assert(price1 != price2, 'Price should change when DEX liquidity changes');
}

#[test]
fn test_oracle_usd_price_unchanged() {
    let (oracle, dex, accounts) = deploy_oracle_with_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();
    
    let initial_myusd = 2000000 * PRECISION; // 2M MyUSD
    let initial_strk = 1000 * PRECISION; // 1000 STRK
    
    myusd.mint(owner, initial_myusd);
    myusd.approve(dex.contract_address(), initial_myusd);
    dex.init(initial_myusd, initial_strk);
    stop_cheat_caller_address(owner);

    // USD price should remain constant regardless of DEX changes
    let usd_price1 = oracle.get_strk_usd_price();
    
    start_cheat_caller_address(user1);
    dex.deposit(1000 * PRECISION);
    stop_cheat_caller_address(user1);
    
    let usd_price2 = oracle.get_strk_usd_price();

    assert(usd_price1 == usd_price2, 'USD price should remain constant');
    assert(usd_price1 == DEFAULT_PRICE, 'USD price should be default price');
}

#[test]
fn test_oracle_edge_cases() {
    let (oracle, accounts) = deploy_oracle();
    let (owner, user1, user2) = accounts;

    // Test with zero address DEX (should fallback to default)
    let price = oracle.get_strk_myusd_price();
    assert(price == DEFAULT_PRICE, 'Should fallback to default with zero DEX price');

    // Test USD price
    let usd_price = oracle.get_strk_usd_price();
    assert(usd_price == DEFAULT_PRICE, 'USD price should be default');
}

#[test]
fn test_oracle_multiple_calls() {
    let (oracle, dex, accounts) = deploy_oracle_with_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();
    
    let initial_myusd = 2000000 * PRECISION; // 2M MyUSD
    let initial_strk = 1000 * PRECISION; // 1000 STRK
    
    myusd.mint(owner, initial_myusd);
    myusd.approve(dex.contract_address(), initial_myusd);
    dex.init(initial_myusd, initial_strk);
    stop_cheat_caller_address(owner);

    // Make multiple calls
    let prices = array![
        oracle.get_strk_myusd_price(),
        oracle.get_strk_myusd_price(),
        oracle.get_strk_myusd_price(),
        oracle.get_strk_myusd_price(),
        oracle.get_strk_myusd_price()
    ];

    // All prices should be the same
    assert(prices[0] == prices[1], 'Prices should be consistent');
    assert(prices[1] == prices[2], 'Prices should be consistent');
    assert(prices[2] == prices[3], 'Prices should be consistent');
    assert(prices[3] == prices[4], 'Prices should be consistent');
}

// Helper function to deploy Oracle
fn deploy_oracle() -> (OracleDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy DEX with zero address (will return 0 price)
    let zero_address = 0.try_into().unwrap();

    // Deploy Oracle
    let oracle_class = declare("Oracle");
    let oracle = oracle_class.deploy(@array![zero_address.into(), DEFAULT_PRICE.into()]).unwrap();

    (oracle, (owner, user1, user2))
}

// Helper function to deploy Oracle with DEX
fn deploy_oracle_with_dex() -> (OracleDispatcher, DEXDispatcher, (ContractAddress, ContractAddress, ContractAddress)) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy DEX
    let dex_class = declare("DEX");
    let dex = dex_class.deploy(@array![myusd.contract_address().into()]).unwrap();

    // Deploy Oracle
    let oracle_class = declare("Oracle");
    let oracle = oracle_class.deploy(@array![dex.contract_address().into(), DEFAULT_PRICE.into()]).unwrap();

    (oracle, dex, (owner, user1, user2))
}

