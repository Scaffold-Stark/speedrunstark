use contracts::balloons::{IBalloonsDispatcher, IBalloonsDispatcherTrait};
use contracts::dex::{IDexDispatcher, IDexDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address};
use starknet::ContractAddress;

const INITIAL_BAL_SUPPLY: u256 = 1_000_000_000_000_000_000_000; // 1000_BAL_IN_FRI
const INITIAL_STRK_SUPPLY: u256 = 5_000_000_000_000_000_000; // 5_STRK_IN_FRI
const INITIAL_RECIPIENT_SUPPLY: u256 = 1_000_000_000_000_000_000_000; // 1000_STRK_IN_FRI
const ONE_TOKEN_UNIT: u256 = 1_000_000_000_000_000_000; // 1_TOKE_UNIT_IN_FRI
const TEN_TOKEN_UNIT: u256 = 10_000_000_000_000_000_000; // 10_TOKE_UNIT_IN_FRI

/// Returns the contract address of the owner.
///
/// Returns:
///     ContractAddress: The address of the owner.
const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();
/// Returns the contract address of the recipient.
///
/// Returns:
///     ContractAddress: The address of the recipient.
const RECIPIENT: ContractAddress = 'RECIPIENT'.try_into().unwrap();
/// Returns the contract address of the second recipient.
///
/// Returns:
///     ContractAddress: The address of the second recipient.
const RECIPIENT2: ContractAddress = 'RECIPIENT2'.try_into().unwrap();

/// Returns the contract address of the third recipient.
///
/// Returns:
///     ContractAddress: The address of the third recipient.
const RECIPIENT3: ContractAddress = 'RECIPIENT3'.try_into().unwrap();

/// Returns the contract address of another entity.
///
/// Returns:
///     ContractAddress: The address of another entity.
const OTHER: ContractAddress = 'OTHER'.try_into().unwrap();

/// Deploys the MockSTRKToken contract and initializes balances for recipients.
///
/// Returns:
///     ContractAddress: The address of the deployed MockSTRKToken contract.
fn deploy_mock_strk_token() -> ContractAddress {
    let mut calldata = array![];
    calldata.append_serde(INITIAL_RECIPIENT_SUPPLY);
    calldata.append_serde(RECIPIENT);
    let strk_token_address = declare_and_deploy("MockSTRKToken", calldata);
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    let mut receipent_strk_balance = strk_token_dispatcher.balance_of(RECIPIENT);
    println!("-- RECIPIENT STRK token balance: {:?} STRK in fri", receipent_strk_balance);
    assert(receipent_strk_balance == INITIAL_RECIPIENT_SUPPLY, 'Balance should be 1000 STRK');
    // Transfer 5 STRK to RECIPIENT2 and RECIPIENT3
    cheat_caller_address(strk_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.transfer(RECIPIENT2, INITIAL_STRK_SUPPLY);
    receipent_strk_balance = strk_token_dispatcher.balance_of(RECIPIENT2);
    println!("-- RECIPIENT2 BAL token balance: {:?} STRK in fri", receipent_strk_balance);
    cheat_caller_address(strk_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.transfer(RECIPIENT3, INITIAL_STRK_SUPPLY);
    receipent_strk_balance = strk_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- RECIPIENT3 BAL token balance: {:?} STRK in fri", receipent_strk_balance);

    println!("-- Dex contract deployed on: 0x{:x}", strk_token_address);
    strk_token_address
}

/// Deploys the Balloons contract and initializes balances for recipients.
///
/// Returns:
///     ContractAddress: The address of the deployed Balloons contract.
fn deploy_balloons_token() -> ContractAddress {
    let mut calldata = array![];
    calldata.append_serde(INITIAL_RECIPIENT_SUPPLY);
    calldata.append_serde(RECIPIENT);
    let balloons_token_address = declare_and_deploy("Balloons", calldata);
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    let mut receipent_bal_balance = balloons_token_dispatcher.balance_of(RECIPIENT);
    println!("-- RECIPIENT BAL token balance: {:?} BAL in FRI", receipent_bal_balance);
    assert(receipent_bal_balance == INITIAL_BAL_SUPPLY, 'Balance should be 1000 BAL');
    // Transfer 5 BAL to RECIPIENT2 and RECIPIENT3
    cheat_caller_address(balloons_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    balloons_token_dispatcher.transfer(RECIPIENT2, TEN_TOKEN_UNIT);
    receipent_bal_balance = balloons_token_dispatcher.balance_of(RECIPIENT2);
    println!("-- RECIPIENT2 BAL token balance: {:?} BAL in FRI", receipent_bal_balance);
    cheat_caller_address(balloons_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    balloons_token_dispatcher.transfer(RECIPIENT3, TEN_TOKEN_UNIT);
    receipent_bal_balance = balloons_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- RECIPIENT3 BAL token balance: {:?} BAL in FRI", receipent_bal_balance);

    println!("-- Balloons contract deployed on: 0x{:x}", balloons_token_address);
    balloons_token_address
}

/// Deploys the Dex contract and initializes it with STRK and BAL balances.
///
/// Returns:
///     (ContractAddress, ContractAddress, ContractAddress): The addresses of the deployed Dex,
///     STRK, and Balloons contracts.
fn deploy_dex_contract() -> (ContractAddress, ContractAddress, ContractAddress) {
    let strk_token_address = deploy_mock_strk_token();
    let balloons_token_address = deploy_balloons_token();
    let mut calldata = array![];
    calldata.append_serde(strk_token_address);
    calldata.append_serde(balloons_token_address);
    calldata.append_serde(OWNER);
    let dex_contract_address = declare_and_deploy("Dex", calldata);
    println!("-- Dex contract deployed on: 0x{:x}", dex_contract_address);

    // Initial STRK and BAL to dex contract
    // Change the caller address to RECIPIENT
    cheat_caller_address(balloons_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    balloons_token_dispatcher.approve(dex_contract_address, INITIAL_STRK_SUPPLY);

    cheat_caller_address(strk_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    strk_token_dispatcher.approve(dex_contract_address, INITIAL_STRK_SUPPLY);

    cheat_caller_address(dex_contract_address, RECIPIENT, CheatSpan::TargetCalls(1));
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    let (bal_balance, strk_balance) = dex_dispatcher.init(INITIAL_STRK_SUPPLY, INITIAL_STRK_SUPPLY);
    assert(bal_balance == INITIAL_STRK_SUPPLY, 'Balance should be 5 BAL');
    assert(strk_balance == INITIAL_STRK_SUPPLY, 'Balance should be 5 STRK');
    println!("-- Dex BAL token balance: {:?} BAL in FRI", bal_balance);
    println!("-- Dex STRK token balance: {:?} STRK in FRI", strk_balance);
    (dex_contract_address, strk_token_address, balloons_token_address)
}

/// Tests the deployment of the MockSTRKToken contract.
#[test]
fn test_deploy_mock_strk_token() {
    deploy_mock_strk_token();
}

/// Tests the deployment of the Balloons contract.
#[test]
fn test_deploy_balloons_token() {
    deploy_balloons_token();
}

/// Tests the deployment of the Dex contract.
#[test]
fn test_deploy_dex() {
    deploy_dex_contract();
}
/// Tests the price calculation of the DEX contract.
#[test]
fn test_price() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };

    // Test case 1: Calculate price with initial reserves
    let mut x_input = 1_000_000_000_000_000_000; // 1 token in FRI
    let mut x_reserves = 5_000_000_000_000_000_000;
    let mut y_reserves = 5_000_000_000_000_000_000;
    let mut y_out = dex_dispatcher.price(x_input, x_reserves, y_reserves);
    assert(y_out == 831248957812239453, 'price() is wrong');

    // Test case 2: Calculate price with updated reserves
    x_input = 1_000_000_000_000_000_000; // 1 token in FRI
    x_reserves = 10_000_000_000_000_000_000;
    y_reserves = 15_000_000_000_000_000_000;
    y_out = dex_dispatcher.price(x_input, x_reserves, y_reserves);
    assert(y_out == 1359916340820223697, 'price() is wrong');
}

/// Tests the get_liquidity function of the DEX contract.
#[test]
fn test_getLiquidity() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    let liquidity = dex_dispatcher.get_liquidity(RECIPIENT);
    assert(liquidity == INITIAL_STRK_SUPPLY, 'get_liquidity() is wrong');
}

/// Tests the strk_to_token function to ensure it reverts when sending zero STRK.
#[test]
#[should_panic(expected: ('Cannot swap 0 strk',))]
fn test_strkToToken_revert_by_sending_zero_strk() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    dex_dispatcher.strk_to_token(0);
}

/// Tests the strk_to_token function to ensure the DEX contract's STRK balance increases correctly.
#[test]
fn test_strkToToken_scenario_1() {
    let (dex_contract_address, strk_token_address, _) = deploy_dex_contract();
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };

    // Check initial DEX STRK balance
    let mut dex_strk_balance = strk_token_dispatcher.balance_of(dex_contract_address);
    println!("-- Dex STRK token balance: {:?} STRK in fri", dex_strk_balance);

    // Check initial recipient STRK balance
    let mut dex_strk_balance = strk_token_dispatcher.balance_of(RECIPIENT);
    println!(
        "-- Before strk_to_token RECIPIENT STRK token balance: {:?} STRK in fri", dex_strk_balance,
    );
    println!("-- Calling strk_to_token with a value of 1 STRK...");

    // Approve and call strk_to_token
    let mut strk_input = 1_000_000_000_000_000_000; // 1 token in fri
    cheat_caller_address(strk_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.approve(dex_contract_address, strk_input);
    cheat_caller_address(dex_contract_address, RECIPIENT, CheatSpan::TargetCalls(1));
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    let token_output = dex_dispatcher.strk_to_token(strk_input);
    println!("-- token_output: {:?} BAL in fri", token_output);

    // Check final DEX STRK balance
    dex_strk_balance = strk_token_dispatcher.balance_of(dex_contract_address);
    println!("-- Dex contract's new STRK balance: {:?} STRK in fri", dex_strk_balance);
    println!("-- Expecting final Dex balance to have increased by 1...");
    assert(dex_strk_balance == INITIAL_STRK_SUPPLY + strk_input, 'Dex balance is wrong');
}

/// Tests the strk_to_token function to ensure less BAL tokens are sent after the first trade.
#[test]
fn test_strkToToken_scenario_2() {
    let (dex_contract_address, strk_token_address, balloons_token_address) = deploy_dex_contract();
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };

    // Check initial BAL balance of recipient 2
    let receipt2_before_balance = balloons_token_dispatcher.balance_of(RECIPIENT2);
    println!("-- Recipient2 initial $BAL balance: {:?} BAL in fri", receipt2_before_balance);
    println!("-- Recipient2 calling strk_to_token with value of 1 STRK...");

    // Approve and call strk_to_token for recipient 2
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    cheat_caller_address(strk_token_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.approve(dex_contract_address, ONE_TOKEN_UNIT);
    cheat_caller_address(dex_contract_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    dex_dispatcher.strk_to_token(ONE_TOKEN_UNIT);
    let receipt2_after_balance = balloons_token_dispatcher.balance_of(RECIPIENT2);
    println!("-- Recipient2 new $BAL balance: {:?} BAL in fri", receipt2_after_balance);

    // Check initial BAL balance of recipient 3
    let receipt3_before_balance = balloons_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- Recipient3 initial $BAL balance: {:?} BAL in fri", receipt3_before_balance);
    println!("-- Recipient3 calling strk_to_token with value of 1 STRK...");

    // Approve and call strk_to_token for recipient 3
    cheat_caller_address(strk_token_address, RECIPIENT3, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.approve(dex_contract_address, ONE_TOKEN_UNIT);
    cheat_caller_address(dex_contract_address, RECIPIENT3, CheatSpan::TargetCalls(1));
    dex_dispatcher.strk_to_token(ONE_TOKEN_UNIT);
    let receipt3_after_balance = balloons_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- Recipient3 new $BAL balance: {:?} BAL in fri", receipt3_after_balance);

    println!("-- Expecting Recipient2 to have acquired more $BAL than Recipient3...");
    assert(receipt2_after_balance > receipt3_after_balance, 'strk_to_token() is wrong');
}

/// Tests the strk_to_token function to ensure tokens are transferred to the purchaser after trade.
#[test]
fn test_strkToToken_scenario_3() {
    let (dex_contract_address, strk_token_address, balloons_token_address) = deploy_dex_contract();
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };

    // Check initial BAL balance of recipient 3
    let receipt3_before_balance = balloons_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- Recipient3 initial $BAL balance: {:?} BAL in fri", receipt3_before_balance);
    println!("-- Recipient3 calling strk_to_token with value of 1 STRK...");

    // Approve and call strk_to_token for recipient 3
    cheat_caller_address(strk_token_address, RECIPIENT3, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.approve(dex_contract_address, ONE_TOKEN_UNIT);
    cheat_caller_address(dex_contract_address, RECIPIENT3, CheatSpan::TargetCalls(1));
    dex_dispatcher.strk_to_token(ONE_TOKEN_UNIT);
    let receipt3_after_balance = balloons_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- Recipient3 new $BAL balance: {:?} BAL in fri", receipt3_after_balance);
    println!("-- Expecting Recipient3's $BAL balance to increase by the correct amount...");

    // Calculate and check token difference
    let tokenDifference = receipt3_after_balance - receipt3_before_balance;
    println!("-- tokenDifference {:?}", tokenDifference);
    assert(tokenDifference == 831248957812239453, 'strk_to_token() is wrong');
}

/// Tests the token_to_strk function to ensure it reverts when sending zero tokens.
///
/// This test verifies that the `token_to_strk` function correctly reverts when
/// attempting to swap zero tokens, ensuring that the function enforces the
/// requirement of a non-zero token amount.
///
/// Expected:
///     The function should panic with the message 'Cannot swap 0 tokens'.
#[test]
#[should_panic(expected: ('Cannot swap 0 tokens',))]
fn test_tokenToStrk_revert_by_sending_zero_token() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    dex_dispatcher.token_to_strk(0);
}

/// Tests the token_to_strk function to ensure the DEX contract's BAL balance increases correctly.
///
/// This test verifies that the `token_to_strk` function correctly increases the DEX
/// contract's BAL balance by the expected amount when a token swap is performed.
///
/// Expected:
///     The DEX contract's BAL balance should increase by the token input amount.
#[test]
fn test_tokenToStrk_scenario_1() {
    let (dex_contract_address, _, balloons_token_address) = deploy_dex_contract();
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    let mut dex_token_balance = balloons_token_dispatcher.balance_of(dex_contract_address);
    println!("-- Dex BAL token balance: {:?} BAL in FRI", dex_token_balance);
    let mut dex_token_balance = balloons_token_dispatcher.balance_of(RECIPIENT);
    println!(
        "-- Before token_to_strk RECIPIENT BAL token balance: {:?} BAL in fri", dex_token_balance,
    );
    println!("-- Calling token_to_strk with a value of 1 BAL...");

    let mut token_input = 1_000_000_000_000_000_000; // 1 token in FRI
    cheat_caller_address(balloons_token_address, RECIPIENT, CheatSpan::TargetCalls(1));
    balloons_token_dispatcher.approve(dex_contract_address, token_input);

    cheat_caller_address(dex_contract_address, RECIPIENT, CheatSpan::TargetCalls(1));
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    let token_output = dex_dispatcher.token_to_strk(token_input);
    println!("-- token_output: {:?} STRK in fri", token_output);

    dex_token_balance = balloons_token_dispatcher.balance_of(dex_contract_address);
    println!("-- Dex contract's new BAL balance: {:?} STRK in FRI", dex_token_balance);
    println!("-- Expecting final Dex balance to have increased by 1...");
    assert(dex_token_balance == INITIAL_STRK_SUPPLY + token_input, 'Dex token balance is wrong');
}

/// Tests the token_to_strk function to ensure less STRK tokens are sent after the first trade.
///
/// This test verifies that the `token_to_strk` function correctly sends fewer STRK
/// tokens after the first trade, ensuring that the function handles subsequent
/// trades with updated reserves.
///
/// Expected:
///     The second recipient should receive fewer STRK tokens than the first recipient.
#[test]
fn test_tokenToStrk_scenario_2() {
    let (dex_contract_address, strk_token_address, balloons_token_address) = deploy_dex_contract();
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    let receipt2_strk_before_ballance = strk_token_dispatcher.balance_of(RECIPIENT2);
    println!("-- Recipient2 initial STRK balance: {:?} STRK in fri", receipt2_strk_before_ballance);
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    println!("-- Recipient2 calling token_to_strk with value of 1 BAL...");

    cheat_caller_address(balloons_token_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    balloons_token_dispatcher.approve(dex_contract_address, ONE_TOKEN_UNIT);

    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    cheat_caller_address(dex_contract_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    dex_dispatcher.token_to_strk(ONE_TOKEN_UNIT);
    let receipt2_after_ballance = strk_token_dispatcher.balance_of(RECIPIENT2);
    println!("-- Recipient2 new STRK balance: {:?} STRK in fri", receipt2_after_ballance);

    let receipt3_before_ballance = strk_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- Recipient3 initial STRK balance: {:?} STRK in fri", receipt3_before_ballance);
    println!("-- Recipient3 calling token_to_strk with value of 1 BAL...");

    cheat_caller_address(balloons_token_address, RECIPIENT3, CheatSpan::TargetCalls(1));
    balloons_token_dispatcher.approve(dex_contract_address, ONE_TOKEN_UNIT);
    cheat_caller_address(dex_contract_address, RECIPIENT3, CheatSpan::TargetCalls(1));
    dex_dispatcher.token_to_strk(ONE_TOKEN_UNIT);
    let receipt3_after_ballance = strk_token_dispatcher.balance_of(RECIPIENT3);
    println!("-- Recipient3 new STRK balance: {:?} STRK in fri", receipt3_after_ballance);

    println!("-- Expecting Recipient2 to have aquired more STRK than Recipient3...");
    assert(receipt2_after_ballance > receipt3_after_ballance, 'token_to_strk() is wrong');
}

/// Tests the deposit function to ensure it reverts when depositing zero STRK.
///
/// This test verifies that the `deposit` function correctly reverts when
/// attempting to deposit zero STRK, ensuring that the function enforces the
/// requirement of a non-zero deposit amount.
///
/// Expected:
///     The function should panic with the message 'Deposit must greater than 0'.
#[test]
#[should_panic(expected: ('Deposit must greater than 0',))]
fn test_deposit_with_zero_strk() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    dex_dispatcher.deposit(0);
}

/// Tests the deposit function to ensure liquidity increases in the pool when STRK is deposited.
///
/// This test verifies that the `deposit` function correctly increases the total
/// liquidity in the pool when STRK is deposited, and that the liquidity provided
/// by the recipient is updated accordingly.
///
/// Expected:
///     The total liquidity should increase by the expected amount, and the recipient's
///     liquidity should be updated.
#[test]
fn test_deposit() {
    let (dex_contract_address, strk_token_address, balloons_token_address) = deploy_dex_contract();
    println!("-- Approving 100 STRK and 10 BAL...");
    cheat_caller_address(strk_token_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    strk_token_dispatcher.approve(dex_contract_address, 100_000_000_000_000_000_000);
    cheat_caller_address(balloons_token_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    balloons_token_dispatcher.approve(dex_contract_address, 10_000_000_000_000_000_000);

    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    let liquidity_start = dex_dispatcher.get_total_liquidity();
    println!("-- Starting Dex liquidity: {:?} STRK in fri", liquidity_start);
    let receipient2Liquidity = dex_dispatcher.get_liquidity(RECIPIENT2);
    println!(
        "-- Expecting receipient2's liquidity to be 0. Liquidity: {:?} STRK in FRI",
        receipient2Liquidity,
    );
    assert(receipient2Liquidity == 0, 'Liquidity should be 0');
    println!("-- Calling deposit function and deposit 3 STRK...");
    cheat_caller_address(dex_contract_address, RECIPIENT2, CheatSpan::TargetCalls(1));
    let liquidity_minted = dex_dispatcher.deposit(3_000_000_000_000_000_000);
    println!("-- Liquidity_minted: {:?} STRK in fri", liquidity_minted);
    let liquidity_end = dex_dispatcher.get_total_liquidity();
    println!(
        "-- Final liquidity should increase by 7.5.   Final liquidity:{:?} STRK in FRI",
        liquidity_end,
    );
    assert(liquidity_end == liquidity_start + 3_000_000_000_000_000_000, 'deposit() is wrong');
    let receipient2_liquidity = dex_dispatcher.get_liquidity(RECIPIENT2);
    println!(
        "-- Receipient2's liquidity provided should be 7.5.  LP:{:?} STRK in FRI",
        receipient2_liquidity,
    );
    assert(receipient2_liquidity == 3_000_000_000_000_000_000, 'RECIPIENT2 lp should be 3');
}

/// Tests the withdraw function to ensure it reverts when the sender does not have enough liquidity.
///
/// This test verifies that the `withdraw` function correctly reverts when
/// attempting to withdraw more liquidity than the sender possesses, ensuring
/// that the function enforces the requirement of sufficient liquidity.
///
/// Expected:
///     The function should panic with the message 'Insufficient liquidity'.
#[test]
#[should_panic(expected: ('Insufficient liquidity',))]
fn test_withdraw_with_not_enough_liquidity() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };
    dex_dispatcher.withdraw(INITIAL_RECIPIENT_SUPPLY);
}

/// Tests the withdraw function to ensure 1 STRK and 1 BAL are withdrawn when the pool is at a 1:1
/// ratio.
///
/// This test verifies that the `withdraw` function correctly withdraws 1 STRK and
/// 1 BAL when the pool is at a 1:1 ratio, ensuring that the function handles
/// withdrawals with the correct token amounts.
///
/// Expected:
///     The recipient's STRK and BAL balances should increase by 1.
#[test]
fn test_withdraw_ratio_1_1() {
    let (dex_contract_address, strk_token_address, balloons_token_address) = deploy_dex_contract();
    let balloons_token_dispatcher = IBalloonsDispatcher {
        contract_address: balloons_token_address,
    };
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };

    // Get starting liquidity
    let starting_liquidity = dex_dispatcher.get_total_liquidity();
    println!("-- Starting liquidity: {:?} STRK in fri", starting_liquidity);

    // Get recipient's initial BAL balance
    let recipient_balloons_balance_before = balloons_token_dispatcher.balance_of(RECIPIENT);
    println!(
        "-- Receipient's starting $BAL balance: {:?} BAL in FRI", recipient_balloons_balance_before,
    );

    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    let strk_balance_before = strk_token_dispatcher.balance_of(RECIPIENT);
    println!("-- Receipient's starting STRK balance: {:?} STRK in fri", strk_balance_before);

    println!("-- Calling withdraw with value of 1 STRK...");
    // Withdraw 1 STRK worth of liquidity
    cheat_caller_address(dex_contract_address, RECIPIENT, CheatSpan::TargetCalls(1));
    dex_dispatcher.withdraw(ONE_TOKEN_UNIT);

    // Get recipient's BAL balance after withdrawal
    let recipient_balloons_balance_after = balloons_token_dispatcher.balance_of(RECIPIENT);
    println!("-- Receipient's new $BAL balance: {:?} BAL in FRI", recipient_balloons_balance_after);
    println!("-- Expecting the balance to have increased by 1 BAL");

    // Check BAL balance increased by 1
    assert(
        recipient_balloons_balance_after == recipient_balloons_balance_before + ONE_TOKEN_UNIT,
        'BAL should increase by 1',
    );

    // Check STRK withdrawn amount
    let strk_balance_after = strk_token_dispatcher.balance_of(RECIPIENT);
    println!("-- Receipient's new STRK balance: {:?} STRK in fri", strk_balance_after);
    println!("-- Expecting the balance to have increased by 1 STRK");
    // Verify both STRK and BAL withdrawn amounts are equal to 1
    assert(
        strk_balance_after == strk_balance_before + ONE_TOKEN_UNIT, 'STRK withdrawn should be 1',
    );
    assert(
        recipient_balloons_balance_after == recipient_balloons_balance_before + ONE_TOKEN_UNIT,
        'BAL withdrawn should be 1',
    );
}

/// Tests the withdraw function to ensure total liquidity decreases.
///
/// This test verifies that the `withdraw` function correctly decreases the total
/// liquidity in the pool when STRK is withdrawn, ensuring that the function
/// handles liquidity updates correctly.
///
/// Expected:
///     The total liquidity should decrease by the withdrawn amount.
#[test]
fn test_withdraw_decrease_liquidity() {
    let (dex_contract_address, _, _) = deploy_dex_contract();
    let dex_dispatcher = IDexDispatcher { contract_address: dex_contract_address };

    // Get initial total liquidity
    let total_lp_before = dex_dispatcher.get_total_liquidity();
    println!("-- Initial liquidity: {:?} STRK in fri", total_lp_before);

    println!("-- Calling withdraw with 1 STRK...");
    cheat_caller_address(dex_contract_address, RECIPIENT, CheatSpan::TargetCalls(1));
    dex_dispatcher.withdraw(ONE_TOKEN_UNIT);

    // Get final total liquidity
    let total_lp_after = dex_dispatcher.get_total_liquidity();
    println!("-- Final liquidity: {:?} STRK in fri", total_lp_after);

    // Verify liquidity decreased
    assert(total_lp_after < total_lp_before, 'Total liquidity should decrease');

    // Calculate and verify burned amount
    let liquidity_burned = total_lp_before - total_lp_after;
    println!("-- Liquidity removed: {:?} STRK in FRI", liquidity_burned);
    assert(liquidity_burned == ONE_TOKEN_UNIT, 'Incorrect liquidity burned');
}
