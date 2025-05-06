use contracts::Staker::{IStakerDispatcher, IStakerDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address, start_cheat_block_timestamp_global};
use starknet::{ContractAddress, get_block_timestamp};

const RECIPIENT: ContractAddress = 'RECIPIENT'.try_into().unwrap();

// Should deploy the MockSTRKToken contract
fn deploy_mock_strk_token() -> ContractAddress {
    let INITIAL_SUPPLY: u256 = 100000000000000000000; // 100_STRK_IN_FRI
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(RECIPIENT);
    declare_and_deploy("MockSTRKToken", calldata)
}

// Should deploy the Staker contract along with the External contract and the mock STRK token
// contract
fn deploy_staker_contract() -> ContractAddress {
    let strk_token_address = deploy_mock_strk_token();
    let external_address = declare_and_deploy("ExampleExternalContract", array![]);
    let mut calldata = array![];
    calldata.append_serde(strk_token_address);
    calldata.append_serde(external_address);
    let staker_contract_address = declare_and_deploy("Staker", calldata);
    println!("-- Staker contract deployed on: 0x{:x}", staker_contract_address);
    staker_contract_address
}

#[test]
fn test_deploy_mock_strk_token() {
    let INITIAL_BALANCE: u256 = 10000000000000000000; // 10_STRK_IN_FRI
    let contract_address = deploy_mock_strk_token();
    let token_dispatcher = IERC20Dispatcher { contract_address };
    assert(token_dispatcher.balance_of(RECIPIENT) == INITIAL_BALANCE, 'Balance should be > 0');
}

// Staker contract balance should go up by the staked amount
#[test]
fn test_stake_functionality() {
    let staker_contract_address = deploy_staker_contract();
    let staker_dispatcher = IStakerDispatcher { contract_address: staker_contract_address };
    let token_dispatcher = staker_dispatcher.token_dispatcher();

    let tester_address = RECIPIENT;
    println!("-- Tester address: 0x{:x}", tester_address);
    let starting_balance = staker_dispatcher.balances(tester_address);
    println!("-- Starting balance in Staker contract: {:?} fri", starting_balance);

    println!("-- Staking 0.1 STRK ...");
    let amount_to_stake: u256 = 100_000_000_000_000_000; // 0.1_STRK_IN_FRI
    let strk_token_address = token_dispatcher.contract_address;
    // Change the caller address of the STRK_token_contract to the tester_address
    cheat_caller_address(strk_token_address, tester_address, CheatSpan::TargetCalls(1));
    // Approve the staker contract to spend the amount_to_stake
    token_dispatcher.approve(staker_contract_address, amount_to_stake);
    // Check if the allowance is set
    assert(
        token_dispatcher.allowance(tester_address, staker_contract_address) == amount_to_stake,
        'Allowance not set',
    );
    // Change the caller address of the staker_contract to the tester_address
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    // Stake the amount_to_stake
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 0.1 STRK");
    let expected_balance = starting_balance + amount_to_stake;
    let new_balance = staker_dispatcher.balances(tester_address);
    println!("-- New balance in Staker contract: {:?} fri", new_balance);
    assert(new_balance == expected_balance, 'Balance increased in stake');
}

// If enough is staked and time has passed, the external contract should be completed
#[test]
fn test_execute_functionality() {
    let staker_contract_address = deploy_staker_contract();
    let staker_dispatcher = IStakerDispatcher { contract_address: staker_contract_address };
    let token_dispatcher = staker_dispatcher.token_dispatcher();

    let tester_address = RECIPIENT;
    println!("-- Tester address: 0x{:x}", tester_address);
    let starting_balance = staker_dispatcher.balances(tester_address);
    println!("-- Starting balance in Staker contract: {:?} fri", starting_balance);

    println!("-- Staking 0.1 STRK ...");
    let amount_to_stake: u256 = 100_000_000_000_000_000; // 0.1_STRK_IN_FRI
    let strk_token_address = token_dispatcher.contract_address;
    // Change the caller address of the STRK_token_contract to the tester_address
    cheat_caller_address(strk_token_address, tester_address, CheatSpan::TargetCalls(1));
    // Approve the staker contract to spend the amount_to_stake
    token_dispatcher.approve(staker_contract_address, amount_to_stake);
    // Check if the allowance is set
    assert(
        token_dispatcher.allowance(tester_address, staker_contract_address) == amount_to_stake,
        'Allowance not set',
    );
    // Change the caller address of the staker_contract to the tester_address
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    // Stake the amount_to_stake
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 0.1 STRK");
    let expected_balance = starting_balance + amount_to_stake;
    let new_balance = staker_dispatcher.balances(tester_address);
    println!("-- New balance in Staker contract: {:?} fri", new_balance);
    assert(new_balance == expected_balance, 'Balance increased in stake');

    // Increase the block_timestamp by 15 seconds
    start_cheat_block_timestamp_global(get_block_timestamp() + 15);
    let time_left = staker_dispatcher.time_left();
    println!("-- Time left: {:?} seconds", time_left);
    assert(time_left == 45, 'There is 45 seconds');

    println!("-- Staking a full STRK ...");
    let amount_to_stake: u256 = 1_000_000_000_000_000_000; // 1_STRK_IN_FRI
    cheat_caller_address(strk_token_address, tester_address, CheatSpan::TargetCalls(1));
    token_dispatcher.approve(staker_contract_address, amount_to_stake);
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 1 STRK");

    // Increase the block_timestamp by 45 seconds
    start_cheat_block_timestamp_global(get_block_timestamp() + 45);
    let time_left = staker_dispatcher.time_left();
    println!("-- Time left: {:?} seconds", time_left);
    assert(time_left == 0, 'Time should be up now');

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
    let token_dispatcher = staker_dispatcher.token_dispatcher();

    let tester_address = RECIPIENT;
    println!("-- Tester address: 0x{:x}", tester_address);
    let starting_balance = staker_dispatcher.balances(tester_address);
    println!("-- Starting balance in Staker contract: {:?} fri", starting_balance);

    println!("-- Staking 0.1 STRK ...");
    let amount_to_stake: u256 = 100_000_000_000_000_000; // 0.1_STRK_IN_FRI
    let strk_token_address = token_dispatcher.contract_address;
    // Change the caller address of the STRK_token_contract to the tester_address
    cheat_caller_address(strk_token_address, tester_address, CheatSpan::TargetCalls(1));
    // Approve the staker contract to spend the amount_to_stake
    token_dispatcher.approve(staker_contract_address, amount_to_stake);
    // Check if the allowance is set
    assert(
        token_dispatcher.allowance(tester_address, staker_contract_address) == amount_to_stake,
        'Allowance not set',
    );
    // Change the caller address of the staker_contract to the tester_address
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    // Stake the amount_to_stake
    staker_dispatcher.stake(amount_to_stake);
    println!("-- Staked 0.1 STRK");
    let expected_balance = starting_balance + amount_to_stake;
    let new_balance = staker_dispatcher.balances(tester_address);
    println!("-- New balance in Staker contract: {:?} fri", new_balance);
    assert(new_balance == expected_balance, 'Balance increased in stake');

    // Increase the block_timestamp by 60 seconds
    start_cheat_block_timestamp_global(get_block_timestamp() + 60);
    let time_left = staker_dispatcher.time_left();
    println!("-- Time left: {:?} seconds", time_left);
    assert(time_left == 0, 'Time should be up now');

    println!("-- Calling execute function ...");
    staker_dispatcher.execute();
    println!("-- Execute function called successfully");

    let result = staker_dispatcher.completed();
    println!("-- External contract completed: {:?}", result);
    assert(!result, 'Complete should be false');

    let starting_balance = token_dispatcher.balance_of(tester_address);
    println!("-- Calling withdraw function ...");
    cheat_caller_address(staker_contract_address, tester_address, CheatSpan::TargetCalls(1));
    staker_dispatcher.withdraw();
    println!("-- Withdraw function called successfully");
    let ending_balance = token_dispatcher.balance_of(tester_address);
    assert(ending_balance == starting_balance + amount_to_stake, 'Balance increased in stake');
}
