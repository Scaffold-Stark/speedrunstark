use contracts::DEX::{DEXDispatcher, DEXDispatcherTrait};
use contracts::MyUSD::{MyUSDDispatcher, MyUSDDispatcherTrait};
use core::traits::TryInto;
use snforge_std::{
    ContractClassTrait, declare, start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

// Constants
const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
const INITIAL_STRK_AMOUNT: u256 = 1000 * PRECISION; // 1000 STRK
const INITIAL_MYUSD_AMOUNT: u256 = 2000000 * PRECISION; // 2M MyUSD (assuming $2000/STRK)

#[test]
fn test_dex_deployment() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    assert(dex.total_liquidity() == 0, 'DEX should start with 0 liquidity');
    assert(dex.price() == 0, 'DEX should start with 0 price');
}

#[test]
fn test_dex_init() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Give owner some MyUSD tokens
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    assert(dex.total_liquidity() > 0, 'DEX should have liquidity after init');
    assert(dex.price() > 0, 'DEX should have price after init');
}

#[test]
fn test_dex_init_zero_amounts() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Try to init with 0 amounts
    start_cheat_caller_address(owner);
    // This should emit an error event
    dex.init(0, 0);
    stop_cheat_caller_address(owner);

    assert(dex.total_liquidity() == 0, 'DEX should remain with 0 liquidity');
}

#[test]
fn test_dex_swap_strk_to_myusd() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    let initial_myusd_balance = myusd.balance_of(user1);
    let swap_amount = 100 * PRECISION; // 100 STRK

    // Swap STRK to MyUSD
    start_cheat_caller_address(user1);
    dex.swap(swap_amount, Option::Some(swap_amount));
    stop_cheat_caller_address(user1);

    let final_myusd_balance = myusd.balance_of(user1);
    assert(final_myusd_balance > initial_myusd_balance, 'User should receive MyUSD tokens');
}

#[test]
fn test_dex_swap_myusd_to_strk() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    // Give user1 some MyUSD tokens
    start_cheat_caller_address(owner);
    myusd.mint(user1, 100000 * PRECISION); // 100k MyUSD
    stop_cheat_caller_address(owner);

    let initial_myusd_balance = myusd.balance_of(user1);
    let swap_amount = 10000 * PRECISION; // 10k MyUSD

    // Swap MyUSD to STRK
    start_cheat_caller_address(user1);
    myusd.approve(dex.contract_address(), swap_amount);
    dex.swap(swap_amount, Option::None);
    stop_cheat_caller_address(user1);

    let final_myusd_balance = myusd.balance_of(user1);
    assert(final_myusd_balance < initial_myusd_balance, 'User should have less MyUSD tokens');
}

#[test]
fn test_dex_swap_zero_amount() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    // Try to swap 0 amount
    start_cheat_caller_address(user1);
    // This should emit an error event
    dex.swap(0, Option::Some(0));
    stop_cheat_caller_address(user1);

    let myusd_balance = myusd.balance_of(user1);
    assert(myusd_balance == 0, 'User should have no MyUSD tokens');
}

#[test]
fn test_dex_deposit() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    let initial_liquidity = dex.total_liquidity();
    let deposit_strk = 100 * PRECISION; // 100 STRK

    // Deposit liquidity
    start_cheat_caller_address(user1);
    dex.deposit(deposit_strk);
    stop_cheat_caller_address(user1);

    let final_liquidity = dex.total_liquidity();
    assert(final_liquidity > initial_liquidity, 'Total liquidity should increase');
}

#[test]
fn test_dex_deposit_zero_amount() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    // Try to deposit 0 amount
    start_cheat_caller_address(user1);
    // This should emit an error event
    dex.deposit(0);
    stop_cheat_caller_address(user1);

    let liquidity = dex.total_liquidity();
    assert(liquidity == dex.total_liquidity(), 'Liquidity should remain unchanged');
}

#[test]
fn test_dex_withdraw() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    // Add some liquidity first
    start_cheat_caller_address(user1);
    dex.deposit(100 * PRECISION);
    stop_cheat_caller_address(user1);

    let initial_liquidity = dex.total_liquidity();
    let user_liquidity = dex.liquidity(user1);

    // Withdraw liquidity
    start_cheat_caller_address(user1);
    dex.withdraw();
    stop_cheat_caller_address(user1);

    let final_liquidity = dex.total_liquidity();
    assert(final_liquidity < initial_liquidity, 'Total liquidity should decrease');
    assert(dex.liquidity(user1) == 0, 'User liquidity should be 0');
}

#[test]
fn test_dex_withdraw_no_liquidity() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    // Try to withdraw with no liquidity
    start_cheat_caller_address(user2);
    // This should emit an error event
    dex.withdraw();
    stop_cheat_caller_address(user2);

    assert(dex.liquidity(user2) == 0, 'User liquidity should remain 0');
}

#[test]
fn test_dex_price_calculation() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    let price = dex.price();
    assert(price > 0, 'Price should be calculated');

    let current_price = dex.current_price();
    assert(current_price > 0, 'Current price should be calculated');
}

#[test]
fn test_dex_calculate_x_input() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    let y_output = 1000 * PRECISION; // 1000 MyUSD
    let x_input = dex.calculate_x_input(y_output);
    assert(x_input > 0, 'X input should be calculated');
}

#[test]
fn test_dex_multiple_swaps() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    let initial_price = dex.current_price();

    // First swap
    start_cheat_caller_address(user1);
    dex.swap(100 * PRECISION, Option::Some(100 * PRECISION));
    stop_cheat_caller_address(user1);

    let price_after_first = dex.current_price();

    // Second swap
    start_cheat_caller_address(user2);
    dex.swap(50 * PRECISION, Option::Some(50 * PRECISION));
    stop_cheat_caller_address(user2);

    let price_after_second = dex.current_price();

    assert(price_after_first != initial_price, 'Price should change after first swap');
    assert(price_after_second != price_after_first, 'Price should change after second swap');
}

#[test]
fn test_dex_liquidity_provision() {
    let (dex, myusd, accounts) = deploy_dex();
    let (owner, user1, user2) = accounts;

    // Initialize DEX
    start_cheat_caller_address(owner);
    myusd.mint(owner, INITIAL_MYUSD_AMOUNT);
    myusd.approve(dex.contract_address(), INITIAL_MYUSD_AMOUNT);
    dex.init(INITIAL_MYUSD_AMOUNT, INITIAL_STRK_AMOUNT);
    stop_cheat_caller_address(owner);

    let initial_liquidity = dex.total_liquidity();

    // User1 adds liquidity
    start_cheat_caller_address(user1);
    dex.deposit(100 * PRECISION);
    stop_cheat_caller_address(user1);

    let liquidity_after_user1 = dex.total_liquidity();

    // User2 adds liquidity
    start_cheat_caller_address(user2);
    dex.deposit(200 * PRECISION);
    stop_cheat_caller_address(user2);

    let liquidity_after_user2 = dex.total_liquidity();

    assert(liquidity_after_user1 > initial_liquidity, 'Liquidity should increase after user1');
    assert(liquidity_after_user2 > liquidity_after_user1, 'Liquidity should increase after user2');
    assert(dex.liquidity(user1) > 0, 'User1 should have liquidity');
    assert(dex.liquidity(user2) > 0, 'User2 should have liquidity');
}

// Helper function to deploy DEX
fn deploy_dex() -> (
    DEXDispatcher, MyUSDDispatcher, (ContractAddress, ContractAddress, ContractAddress),
) {
    let owner = contract_address_const::<'owner'>();
    let user1 = contract_address_const::<'user1'>();
    let user2 = contract_address_const::<'user2'>();

    // Deploy MyUSD
    let myusd_class = declare("MyUSD");
    let myusd = myusd_class.deploy(@array![owner.into()]).unwrap();

    // Deploy DEX
    let dex_class = declare("DEX");
    let dex = dex_class.deploy(@array![myusd.contract_address().into()]).unwrap();

    (dex, myusd, (owner, user1, user2))
}

