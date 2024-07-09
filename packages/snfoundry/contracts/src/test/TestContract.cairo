use contracts::Staker::{IStakerDispatcherTrait, IStakerDispatcher};
use contracts::mock_contracts::MockETHToken;
use openzeppelin::tests::utils::constants::RECIPIENT;
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, cheat_block_timestamp_global, CheatSpan
};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

// Should deploy the MockETHToken contract
fn deploy_mock_eth_token() -> ContractAddress {
    let erc20_class_hash = declare("MockETHToken").unwrap();
    let INITIAL_SUPPLY: u256 = 100000000000000000000; // 100_ETH_IN_WEI
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(RECIPIENT());
    let (eth_token_address, _) = erc20_class_hash.deploy(@calldata).unwrap();
    eth_token_address
}
// Should deploy the Staker contract along with the External contract and the mock ETH token contract
fn deploy_staker_contract() -> ContractAddress {
    let eth_token_address = deploy_mock_eth_token();
    let external_class_hash = declare("ExampleExternalContract").unwrap();
    let (external_address, _) = external_class_hash.deploy(@array![]).unwrap();
    let staker_class_hash = declare("Staker").unwrap();
    let mut calldata = array![];
    calldata.append_serde(eth_token_address);
    calldata.append_serde(external_address);
    let (staker_contract_address, _) = staker_class_hash.deploy(@calldata).unwrap();
    println!("-- Staker contract deployed on: {:?}", staker_contract_address);
    staker_contract_address
}

#[test]
fn test_deploy_mock_eth_token() {
    let INITIAL_BALANCE: u256 = 10000000000000000000; // 10_ETH_IN_WEI
    let contract_address = deploy_mock_eth_token();
    let eth_token_dispatcher = IERC20CamelDispatcher { contract_address };
    assert(eth_token_dispatcher.balanceOf(RECIPIENT()) == INITIAL_BALANCE, 'Balance should be > 0');
}

// Staker contract balance should go up by the staked amount
#[test]
fn test_stake_functionality() {
    let staker_contract_address = deploy_staker_contract();
    let staker_dispatcher = IStakerDispatcher { contract_address: staker_contract_address };
    let eth_token_dispatcher = staker_dispatcher.eth_token_dispatcher();

    let tester_address = RECIPIENT();
    println!("-- Tester address: {:?}", tester_address);
    let starting_balance = staker_dispatcher.balances(tester_address);
    println!("-- Starting balance in Staker contract: {:?} wei", starting_balance);

    println!("-- Staking 0.1 ETH ...");
    let amount_to_stake: u256 = 100_000_000_000_000_000; // 0.1_ETH_IN_WEI
    let eth_token_address = eth_token_dispatcher.contract_address;
    // Change the caller address of the ETH_token_contract to the tester_address
    cheat_caller_address(eth_token_address, tester_address, CheatSpan::TargetCalls(1));
    // Approve the staker contract to spend the amount_to_stake
    eth_token_dispatcher.approve(staker_contract_address, amount_to_stake);
    // Check if the allowance is set
    assert(
        eth_token_dispatcher.allowance(tester_address, staker_contract_address) == amount_to_stake,
        'Allowance not set'
    );
    // Change the caller address of the staker_contract to the tester_address
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    // Stake the amount_to_stake
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 0.1 ETH");
    let expected_balance = starting_balance + amount_to_stake;
    let new_balance = staker_dispatcher.balances(tester_address);
    println!("-- New balance in Staker contract: {:?} wei", new_balance);
    assert_eq!(new_balance, expected_balance, "Balance should be increased by the stake amount");
}

// If enough is staked and time has passed, the external contract should be completed
#[test]
fn test_execute_functionality() {
    let staker_contract_address = deploy_staker_contract();
    let staker_dispatcher = IStakerDispatcher { contract_address: staker_contract_address };
    let eth_token_dispatcher = staker_dispatcher.eth_token_dispatcher();

    let tester_address = RECIPIENT();
    println!("-- Tester address: {:?}", tester_address);
    let starting_balance = staker_dispatcher.balances(tester_address);
    println!("-- Starting balance in Staker contract: {:?} wei", starting_balance);

    println!("-- Staking 0.1 ETH ...");
    let amount_to_stake: u256 = 100_000_000_000_000_000; // 0.1_ETH_IN_WEI
    let eth_token_address = eth_token_dispatcher.contract_address;
    // Change the caller address of the ETH_token_contract to the tester_address
    cheat_caller_address(eth_token_address, tester_address, CheatSpan::TargetCalls(1));
    // Approve the staker contract to spend the amount_to_stake
    eth_token_dispatcher.approve(staker_contract_address, amount_to_stake);
    // Check if the allowance is set
    assert(
        eth_token_dispatcher.allowance(tester_address, staker_contract_address) == amount_to_stake,
        'Allowance not set'
    );
    // Change the caller address of the staker_contract to the tester_address
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    // Stake the amount_to_stake
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 0.1 ETH");
    let expected_balance = starting_balance + amount_to_stake;
    let new_balance = staker_dispatcher.balances(tester_address);
    println!("-- New balance in Staker contract: {:?} wei", new_balance);
    assert_eq!(new_balance, expected_balance, "Balance should be increased by the stake amount");

    // Increase the block_timestamp by 15 seconds
    cheat_block_timestamp_global(get_block_timestamp() + 15);
    let time_left = staker_dispatcher.time_left();
    println!("-- Time left: {:?} seconds", time_left);
    assert_eq!(time_left, 15, "There should be 15 seconds left");

    println!("-- Staking a full ETH ...");
    let amount_to_stake: u256 = 1_000_000_000_000_000_000; // 1_ETH_IN_WEI
    cheat_caller_address(eth_token_address, tester_address, CheatSpan::TargetCalls(1));
    eth_token_dispatcher.approve(staker_contract_address, amount_to_stake);
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 1 ETH");

    // Increase the block_timestamp by 15 seconds
    cheat_block_timestamp_global(get_block_timestamp() + 15);
    let time_left = staker_dispatcher.time_left();
    println!("-- Time left: {:?} seconds", time_left);
    assert_eq!(time_left, 0, "Time should be up now");

    println!("-- Calling execute function ...");
    staker_dispatcher.execute();
    println!("-- Execute function called successfully");
    let result = staker_dispatcher.completed();
    println!("-- External contract completed: {:?}", result);
    assert(result, 'Should be completed');
}

// If not enough is staked and time has passed, the external contract should not be completed
// And the Staker contract should be open for withdrawal
#[test]
fn test_withdraw_functionality() {
    let staker_contract_address = deploy_staker_contract();
    let staker_dispatcher = IStakerDispatcher { contract_address: staker_contract_address };
    let eth_token_dispatcher = staker_dispatcher.eth_token_dispatcher();

    let tester_address = RECIPIENT();
    println!("-- Tester address: {:?}", tester_address);
    let starting_balance = staker_dispatcher.balances(tester_address);
    println!("-- Starting balance in Staker contract: {:?} wei", starting_balance);

    println!("-- Staking 0.1 ETH ...");
    let amount_to_stake: u256 = 100_000_000_000_000_000; // 0.1_ETH_IN_WEI
    let eth_token_address = eth_token_dispatcher.contract_address;
    // Change the caller address of the ETH_token_contract to the tester_address
    cheat_caller_address(eth_token_address, tester_address, CheatSpan::TargetCalls(1));
    // Approve the staker contract to spend the amount_to_stake
    eth_token_dispatcher.approve(staker_contract_address, amount_to_stake);
    // Check if the allowance is set
    assert(
        eth_token_dispatcher.allowance(tester_address, staker_contract_address) == amount_to_stake,
        'Allowance not set'
    );
    // Change the caller address of the staker_contract to the tester_address
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    // Stake the amount_to_stake
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 0.1 ETH");
    let expected_balance = starting_balance + amount_to_stake;
    let new_balance = staker_dispatcher.balances(tester_address);
    println!("-- New balance in Staker contract: {:?} wei", new_balance);
    assert_eq!(new_balance, expected_balance, "Balance should be increased by the stake amount");

    // Increase the block_timestamp by 30 seconds
    cheat_block_timestamp_global(get_block_timestamp() + 30);
    let time_left = staker_dispatcher.time_left();
    println!("-- Time left: {:?} seconds", time_left);
    assert_eq!(time_left, 0, "Time should be up now");

    println!("-- Calling execute function ...");
    staker_dispatcher.execute();
    println!("-- Execute function called successfully");

    let result = staker_dispatcher.completed();
    println!("-- External contract completed: {:?}", result);
    assert(!result, 'Complete should be false');

    let starting_balance = eth_token_dispatcher.balanceOf(tester_address);
    println!("-- Calling withdraw function ...");
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    staker_dispatcher.withdraw();
    println!("-- Withdraw function called successfully");
    let ending_balance = eth_token_dispatcher.balanceOf(tester_address);
    assert_eq!(
        ending_balance,
        starting_balance + amount_to_stake,
        "Balance should be increased by the stake amount"
    );
}

