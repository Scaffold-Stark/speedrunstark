use contracts::DiceGame::{IDiceGameDispatcher, IDiceGameDispatcherTrait, DiceGame};
use contracts::RiggedRoll::{IRiggedRollDispatcher, IRiggedRollDispatcherTrait};

use contracts::mock_contracts::MockETHToken;
use keccak::keccak_u256s_le_inputs;
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::cheatcodes::events::EventsFilterTrait;
use snforge_std::{
    declare, ContractClassTrait, spy_events, EventSpyAssertionsTrait, EventSpyTrait, Event,
    cheat_caller_address, cheat_block_timestamp, CheatSpan
};
use starknet::{ContractAddress, get_contract_address, get_block_number, get_caller_address};
use starknet::{contract_address_const, get_block_timestamp};

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

const ROLL_DICE_AMOUNT: u256 = 2000000000000000; // 0.002_ETH_IN_WEI
// Should deploy the MockETHToken contract
fn deploy_mock_eth_token() -> ContractAddress {
    let erc20_class_hash = declare("MockETHToken").unwrap();
    let INITIAL_SUPPLY: u256 = 100000000000000000000; // 100_ETH_IN_WEI
    let reciever = OWNER();
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(reciever);
    let (eth_token_address, _) = erc20_class_hash.deploy(@calldata).unwrap();
    eth_token_address
}

// Should deploy the DiceGame contract
fn deploy_dice_game_contract() -> ContractAddress {
    let eth_token_address = deploy_mock_eth_token();
    let dice_game_class_hash = declare("DiceGame").unwrap();
    let mut calldata = array![];
    calldata.append_serde(eth_token_address);
    let (dice_game_contract_address, _) = dice_game_class_hash.deploy(@calldata).unwrap();
    println!("-- Dice Game contract deployed on: {:?}", dice_game_contract_address);
    dice_game_contract_address
}

fn deploy_rigged_roll_contract() -> ContractAddress {
    let dice_game_contract_address = deploy_dice_game_contract();
    let rigged_roll_class_hash = declare("RiggedRoll").unwrap();
    let mut calldata = array![];
    calldata.append_serde(dice_game_contract_address);
    calldata.append_serde(OWNER());
    let (rigged_roll_contract_address, _) = rigged_roll_class_hash.deploy(@calldata).unwrap();
    println!("-- Rigged Roll contract deployed on: {:?}", rigged_roll_contract_address);
    rigged_roll_contract_address
}

fn get_roll(get_roll_less_than_5: bool, rigged_roll_dispatcher: IRiggedRollDispatcher) -> u256 {
    let mut expected_roll = 0;
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();
    let dice_game_contract_address = dice_game_dispatcher.contract_address;
    let tester_address = OWNER();
    while true {
        let prev_block: u256 = get_block_number().into() - 1;
        let array = array![prev_block, dice_game_dispatcher.nonce()];
        expected_roll = keccak_u256s_le_inputs(array.span()) % 16;
        println!("-- Produced roll: {:?}", expected_roll);
        if expected_roll <= 5 == get_roll_less_than_5 {
            break;
        }
        let eth_token_dispatcher = dice_game_dispatcher.eth_token_dispatcher();
        cheat_caller_address(
            eth_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1)
        );
        eth_token_dispatcher.approve(dice_game_contract_address, ROLL_DICE_AMOUNT);
        cheat_caller_address(dice_game_contract_address, tester_address, CheatSpan::TargetCalls(1));
        dice_game_dispatcher.roll_dice(ROLL_DICE_AMOUNT);
    };
    expected_roll
}
#[test]
fn test_deploy_dice_game() {
    deploy_dice_game_contract();
}

#[test]
fn test_deploy_rigged_roll() {
    deploy_rigged_roll_contract();
}

#[test]
#[should_panic(expected: ('Not enough ETH',))]
fn test_rigged_roll_fails() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address
    };
    let eth_amount_wei: u256 = 1000000000000000; // 0.001_ETH_IN_WEI

    let tester_address = OWNER();
    let eth_token_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher().eth_token_dispatcher();
    cheat_caller_address(
        eth_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1)
    );
    eth_token_dispatcher.approve(rigged_roll_contract_address, eth_amount_wei);
    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));
    rigged_roll_dispatcher.rigged_roll(eth_amount_wei);
}

#[test]
fn test_rigged_roll_call_dice_game() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address
    };
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();

    let get_roll_less_than_5 = true;
    let expected_roll = get_roll(get_roll_less_than_5, rigged_roll_dispatcher);
    println!("-- Expect roll to be less than or equal to 5. DiceGame Roll:: {:?}", expected_roll);
    let tester_address = OWNER();
    let eth_token_dispatcher = dice_game_dispatcher.eth_token_dispatcher();
    cheat_caller_address(
        eth_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1)
    );
    eth_token_dispatcher.approve(rigged_roll_contract_address, ROLL_DICE_AMOUNT);

    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));

    let mut spy = spy_events();
    rigged_roll_dispatcher.rigged_roll(ROLL_DICE_AMOUNT);

    let dice_game_contract = dice_game_dispatcher.contract_address;
    let events = spy.get_events().emitted_by(dice_game_contract);

    assert_eq!(events.events.len(), 2, "There should be two events emitted by DiceGame contract");
    spy
        .assert_emitted(
            @array![
                (
                    dice_game_contract,
                    DiceGame::Event::Roll(
                        DiceGame::Roll {
                            player: rigged_roll_contract_address,
                            amount: ROLL_DICE_AMOUNT,
                            roll: expected_roll
                        }
                    )
                )
            ]
        );
    let (_, event) = events.events.at(1);
    assert(event.keys.at(0) == @selector!("Winner"), 'Expected Winner event');
}

#[test]
fn test_rigged_roll_should_not_call_dice_game() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address
    };
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();

    let get_roll_less_than_5 = false;
    let expected_roll = get_roll(get_roll_less_than_5, rigged_roll_dispatcher);
    println!("-- Expect roll to be greater than 5. DiceGame Roll:: {:?}", expected_roll);
    let tester_address = OWNER();
    let eth_token_dispatcher = dice_game_dispatcher.eth_token_dispatcher();
    cheat_caller_address(
        eth_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1)
    );
    eth_token_dispatcher.approve(rigged_roll_contract_address, ROLL_DICE_AMOUNT);

    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));

    let mut spy = spy_events();

    rigged_roll_dispatcher.rigged_roll(ROLL_DICE_AMOUNT);

    let dice_game_contract = dice_game_dispatcher.contract_address;
    let events = spy.get_events().emitted_by(dice_game_contract);

    assert_eq!(events.events.len(), 0, "There should be no events emitted by DiceGame contract");
}

#[test]
fn test_withdraw() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address
    };

    let get_roll_less_than_5 = true;
    let expected_roll = get_roll(get_roll_less_than_5, rigged_roll_dispatcher);
    println!("-- Expect roll to be less than or equal to 5. DiceGame Roll:: {:?}", expected_roll);
    let tester_address = OWNER();
    let eth_token_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher().eth_token_dispatcher();
    cheat_caller_address(
        eth_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1)
    );
    eth_token_dispatcher.approve(rigged_roll_contract_address, ROLL_DICE_AMOUNT);

    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));

    rigged_roll_dispatcher.rigged_roll(ROLL_DICE_AMOUNT);

    let tester_address_prev_balance = eth_token_dispatcher.balanceOf(tester_address);
    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));
    let rigged_roll_balance = eth_token_dispatcher.balanceOf(rigged_roll_contract_address);

    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));
    rigged_roll_dispatcher.withdraw(tester_address, rigged_roll_balance);
    let tester_address_new_balance = eth_token_dispatcher.balanceOf(tester_address);
    assert_eq!(
        tester_address_new_balance,
        tester_address_prev_balance + rigged_roll_balance,
        "Tester address should have the balance of the rigged_roll_contract_address"
    );
}
