use contracts::dice_game::{DiceGame, IDiceGameDispatcherTrait};
use contracts::rigged_roll::{IRiggedRollDispatcher, IRiggedRollDispatcherTrait};
use core::keccak::keccak_u256s_le_inputs;
use openzeppelin_interfaces::token::erc20::IERC20DispatcherTrait;
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::cheatcodes::events::EventsFilterTrait;
use snforge_std::{
    CheatSpan, EventSpyAssertionsTrait, EventSpyTrait, cheat_caller_address, spy_events,
};
use starknet::{ContractAddress, get_block_number};

const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();

const ROLL_DICE_AMOUNT: u256 = 2000000000000000; // 0.002_STRK_IN_FRI
// Should deploy the MockSTRKToken contract
fn deploy_mock_strk_token() -> ContractAddress {
    let INITIAL_SUPPLY: u256 = 100000000000000000000; // 100_STRK_IN_FRI
    let reciever = OWNER;
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(reciever);
    declare_and_deploy("MockSTRKToken", calldata)
}

// Should deploy the DiceGame contract
fn deploy_dice_game_contract() -> ContractAddress {
    let strk_token_address = deploy_mock_strk_token();
    let mut calldata = array![];
    calldata.append_serde(strk_token_address);
    let dice_game_contract_address = declare_and_deploy("DiceGame", calldata);
    println!("-- Dice Game contract deployed on: 0x{:x}", dice_game_contract_address);
    dice_game_contract_address
}

fn deploy_rigged_roll_contract() -> ContractAddress {
    let dice_game_contract_address = deploy_dice_game_contract();
    let mut calldata = array![];
    calldata.append_serde(dice_game_contract_address);
    calldata.append_serde(OWNER);
    let rigged_roll_contract_address = declare_and_deploy("RiggedRoll", calldata);
    println!("-- Rigged Roll contract deployed on: 0x{:x}", rigged_roll_contract_address);
    rigged_roll_contract_address
}

fn get_roll(get_roll_less_than_5: bool, rigged_roll_dispatcher: IRiggedRollDispatcher) -> u256 {
    let mut expected_roll = 0;
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();
    let dice_game_contract_address = dice_game_dispatcher.contract_address;
    let tester_address = OWNER;
    while true {
        let prev_block: u256 = get_block_number().into() - 1;
        let array = array![prev_block, dice_game_dispatcher.nonce()];
        expected_roll = keccak_u256s_le_inputs(array.span()) % 16;
        println!("-- Produced roll: {:?}", expected_roll);
        if (expected_roll <= 5) == get_roll_less_than_5 {
            break;
        }
        let strk_token_dispatcher = dice_game_dispatcher.strk_token_dispatcher();
        cheat_caller_address(
            strk_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1),
        );
        strk_token_dispatcher.approve(dice_game_contract_address, ROLL_DICE_AMOUNT);
        cheat_caller_address(dice_game_contract_address, tester_address, CheatSpan::TargetCalls(1));
        dice_game_dispatcher.roll_dice(ROLL_DICE_AMOUNT);
    }
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
#[should_panic(expected: ('Not enough STRK',))]
fn test_rigged_roll_fails() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address,
    };
    let strk_amount_wei: u256 = 1000000000000000; // 0.001_STRK_IN_FRI

    let tester_address = OWNER;
    let strk_token_dispatcher = rigged_roll_dispatcher
        .dice_game_dispatcher()
        .strk_token_dispatcher();
    cheat_caller_address(
        strk_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1),
    );
    strk_token_dispatcher.approve(rigged_roll_contract_address, strk_amount_wei);
    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));
    rigged_roll_dispatcher.rigged_roll(strk_amount_wei);
}

#[test]
fn test_rigged_roll_call_dice_game() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address,
    };
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();

    let get_roll_less_than_5 = true;
    let expected_roll = get_roll(get_roll_less_than_5, rigged_roll_dispatcher);
    println!("-- Expect roll to be less than or equal to 5. DiceGame Roll:: {:?}", expected_roll);
    let tester_address = OWNER;
    let strk_token_dispatcher = dice_game_dispatcher.strk_token_dispatcher();
    cheat_caller_address(
        strk_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1),
    );
    strk_token_dispatcher.approve(rigged_roll_contract_address, ROLL_DICE_AMOUNT);

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
                            roll: expected_roll,
                        },
                    ),
                ),
            ],
        );
    let (_, event) = events.events.at(1);
    assert(event.keys.at(0) == @selector!("Winner"), 'Expected Winner event');
}

#[test]
fn test_rigged_roll_should_not_call_dice_game() {
    let rigged_roll_contract_address = deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher {
        contract_address: rigged_roll_contract_address,
    };
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();

    let get_roll_less_than_5 = false;
    let expected_roll = get_roll(get_roll_less_than_5, rigged_roll_dispatcher);
    println!("-- Expect roll to be greater than 5. DiceGame Roll:: {:?}", expected_roll);
    let tester_address = OWNER;
    let strk_token_dispatcher = dice_game_dispatcher.strk_token_dispatcher();
    cheat_caller_address(
        strk_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1),
    );
    strk_token_dispatcher.approve(rigged_roll_contract_address, ROLL_DICE_AMOUNT);

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
        contract_address: rigged_roll_contract_address,
    };

    let get_roll_less_than_5 = true;
    let expected_roll = get_roll(get_roll_less_than_5, rigged_roll_dispatcher);
    println!("-- Expect roll to be less than or equal to 5. DiceGame Roll:: {:?}", expected_roll);
    let tester_address = OWNER;
    let strk_token_dispatcher = rigged_roll_dispatcher
        .dice_game_dispatcher()
        .strk_token_dispatcher();
    cheat_caller_address(
        strk_token_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1),
    );
    strk_token_dispatcher.approve(rigged_roll_contract_address, ROLL_DICE_AMOUNT);

    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));

    rigged_roll_dispatcher.rigged_roll(ROLL_DICE_AMOUNT);

    let tester_address_prev_balance = strk_token_dispatcher.balance_of(tester_address);
    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));
    let rigged_roll_balance = strk_token_dispatcher.balance_of(rigged_roll_contract_address);

    cheat_caller_address(rigged_roll_contract_address, tester_address, CheatSpan::TargetCalls(1));
    rigged_roll_dispatcher.withdraw(tester_address, rigged_roll_balance);
    let tester_address_new_balance = strk_token_dispatcher.balance_of(tester_address);
    assert_eq!(
        tester_address_new_balance,
        tester_address_prev_balance + rigged_roll_balance,
        "Tester address should have the balance of the rigged_roll_contract_address",
    );
}
