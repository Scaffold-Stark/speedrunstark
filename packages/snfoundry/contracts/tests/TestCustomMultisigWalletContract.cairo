
use starknet::ContractAddress;
use starknet::account::Call;

pub type TransactionID = felt252;
pub type TransactionState = contracts::CustomInterfaceMultisigComponent::TransactionState;


use contracts::CustomInterfaceMultisigComponent::{IMultisigDispatcher,IMultisigDispatcherTrait};
use contracts::CustomMultisigWallet::{IMultisigWalletDispatcher,IMultisigWalletDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, 
                  cheat_caller_address,
                  spy_events,
                  EventSpyAssertionsTrait,
                  set_balance,
                  Token};

use test_event_utils::{build_quorum_updated_event,
                build_signer_events,
                build_confirm_revoked_event,
                build_tx_submitted_event,
                build_tx_confirmed_event,
                build_tx_executed_event,
                build_signer_removed_event
            };

/// OWNER and SIGNERS 
const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();

const SIGNER1: ContractAddress = 'SIGNER1'.try_into().unwrap();
const SIGNER2: ContractAddress = 'SIGNER2'.try_into().unwrap();
const SIGNER3: ContractAddress = 'SIGNER3'.try_into().unwrap();
const SIGNER4: ContractAddress = 'SIGNER4'.try_into().unwrap();

const NEWSIGNER: ContractAddress = 'NEWSIGNER'.try_into().unwrap();
const NEWSIGNER2: ContractAddress ='NEWSIGNER2'.try_into().unwrap();
// random guy who try to mess things up.
const RANDOM_ENTITY: ContractAddress = 'RANDOM_ENTITY'.try_into().unwrap();

fn create_signer_array()-> Array<ContractAddress>{
    let mut calldata:Array<ContractAddress> = array![];
    calldata.append(SIGNER1);
    calldata.append(SIGNER2);
    calldata.append(SIGNER3);
    calldata
}

fn create_newsigners_array()-> Array<ContractAddress>{
    let mut new_signers:Array<ContractAddress> = array![];
    new_signers.append(NEWSIGNER);
    new_signers.append(NEWSIGNER2);
    new_signers
}

fn create_replaceablesigners_array() -> Array<ContractAddress>{
    let mut replaceable_signers:Array<ContractAddress> = array![];
    replaceable_signers.append(SIGNER3);
    replaceable_signers.append(SIGNER4);
    replaceable_signers
}
#[derive(Drop)]
enum FunctionName {
    AddSigner,
    RemoveSigner,
    QuorumUpdate,
    ReplaceSigner,
}
// simple selector encoding.
fn selector_for(function: FunctionName) -> felt252 {
    match function {
        FunctionName::AddSigner => selector!("add_signer"),
        FunctionName::RemoveSigner => selector!("remove_signer"),
        FunctionName::QuorumUpdate => selector!("change_quorum"),
        FunctionName::ReplaceSigner => selector!("replace_signer"),
    }
}
//mainly used for add_signer-remove_signer batch calls.
fn create_batch_call(to: ContractAddress, func_name:FunctionName,address_array:Array<ContractAddress>) -> Array<Call> {
    let mut quorum = 1_u32;
    let signers = address_array;
    let mut calls: Array<Call> = array![];
    let selector = selector_for(func_name);

    for i in 0..signers.len() {
        let mut calldata = array![];
        calldata.append_serde(quorum);
        calldata.append_serde(*signers.at(i));
        calls.append(Call {
            to: to,
            selector: selector,
            calldata: calldata.span(),
        });  
    }
    calls
}

fn deploy_custom_multisig_wallet() ->IMultisigDispatcher{
    let mut calldata = array![];
    //initial quorum should be 1 cause we set 1 signer at a time.
    let quorum:u32= 1;
    let signer:ContractAddress= OWNER;
    calldata.append_serde(quorum);
    calldata.append_serde(signer);
    
    let custom_multisig_wallet_address = declare_and_deploy("CustomMultisigWallet",calldata);
    // lets set stark balance for our custom wallet;
    set_balance(
        custom_multisig_wallet_address,
        1000000000000000_u256,
        Token::STRK
    );
    IMultisigDispatcher{contract_address:custom_multisig_wallet_address}
}

#[test]
fn test_add_signer_batch(){
    // build event observer;
    let mut spy = spy_events();
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    // create batch call
    let signers = create_signer_array();
    let calls = create_batch_call(multisig_dispatcher.contract_address,FunctionName::AddSigner,signers.clone());
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let batch_tx_id = multisig_dispatcher.submit_transaction_batch(calls.clone(),1);
    multisig_dispatcher.confirm_transaction(batch_tx_id);
    multisig_dispatcher.execute_transaction_batch(calls.clone(),1);

    let signer_events = build_signer_events(signers,multisig_dispatcher.contract_address);
    spy.assert_emitted(@signer_events);
    
    let new_signers = multisig_dispatcher.get_signers();
    assert_eq!(new_signers.len(),4,"signers count wrong");
    
}
#[test]
fn test_get_quorum(){
let multisig_dispatcher = deploy_custom_multisig_wallet();
let quorum = multisig_dispatcher.get_quorum();
assert_eq!(quorum,1,"wrong quorum!");
}

#[test]
fn test_transfer_funds(){
let multisig_dispatcher = deploy_custom_multisig_wallet();
// to use transfer_funds we need to wrap the contract with IMultisigWalletDispatcher
let multisig_wallet_dispatcher = IMultisigWalletDispatcher{contract_address:multisig_dispatcher.contract_address};

// no need to assert cause oz package will revert in case of 0 
multisig_wallet_dispatcher.transfer_funds(
    RANDOM_ENTITY,
    1000000000000000_u256
);
}

#[test]
fn test_is_signer(){
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    let is_signer = multisig_dispatcher.is_signer(OWNER);
    assert_eq!(is_signer,true,"invalid signer response!");
}

#[test]
fn test_get_signers(){
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    let signers = multisig_dispatcher.get_signers();
    assert_eq!(*signers.at(0),OWNER,"invalid signer");
}

#[test]
fn test_is_confirmed(){
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    // create batch call
    let signers = create_signer_array();
    let calls = create_batch_call(multisig_dispatcher.contract_address,FunctionName::AddSigner,signers);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(2));
    let batch_tx_id = multisig_dispatcher.submit_transaction_batch(calls.clone(),1);
    multisig_dispatcher.confirm_transaction(batch_tx_id);
    let tx_confirmed = multisig_dispatcher.is_confirmed(batch_tx_id);
    assert_eq!(tx_confirmed,true,"tx not confirmed!");
}

#[test]
fn test_is_executed(){
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    // create batch call
    let signers = create_signer_array();
    let calls = create_batch_call(multisig_dispatcher.contract_address,FunctionName::AddSigner,signers);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let batch_tx_id = multisig_dispatcher.submit_transaction_batch(calls.clone(),1);
    multisig_dispatcher.confirm_transaction(batch_tx_id);
    multisig_dispatcher.execute_transaction_batch(calls.clone(),1);
    let tx_executed = multisig_dispatcher.is_executed(batch_tx_id);
    assert_eq!(tx_executed,true,"tx not executed!");
}

#[test]
fn test_hash_transaction(){
let multisig_dispatcher = deploy_custom_multisig_wallet();
    let to = multisig_dispatcher.contract_address;
    let selector = selector_for(FunctionName::QuorumUpdate);
    let mut calldata = array![];
    let new_quorum = 4_u32 ;
    calldata.append_serde(new_quorum);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    let tx_id = multisig_dispatcher.submit_transaction(to,selector,calldata.clone(),0);
    let tx_hash = multisig_dispatcher.hash_transaction(to,selector,calldata.clone(),0);
    assert_eq!(tx_id,tx_hash,"invalid hashing");
}

#[test]
fn test_hash_transaction_batch(){
   let multisig_dispatcher = deploy_custom_multisig_wallet();
    // create batch call
    let signers = create_signer_array();
    let calls = create_batch_call(multisig_dispatcher.contract_address,FunctionName::AddSigner,signers);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    let batch_tx_id = multisig_dispatcher.submit_transaction_batch(calls.clone(),1);
    let batch_hash = multisig_dispatcher.hash_transaction_batch(calls.clone(),1);
    assert_eq!(batch_tx_id,batch_hash,"invalid batch_hashing");
}

#[test]
fn test_get_transaction_state(){
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    let signers = create_signer_array();
    let to = multisig_dispatcher.contract_address;
    let selector = selector_for(FunctionName::AddSigner);
    let mut calldata = array![];
    let new_quorum = 2_u32 ;
    let new_signer = *signers.at(0);
    calldata.append_serde(new_quorum);
    calldata.append_serde(new_signer);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    let tx_id = multisig_dispatcher.submit_transaction(to,selector,calldata.clone(),0);
    let tx_state_pending = multisig_dispatcher.get_transaction_state(tx_id);
    assert_eq!(tx_state_pending,TransactionState::Pending,"invalid state");
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    multisig_dispatcher.confirm_transaction(tx_id);
    let tx_state_confirmed = multisig_dispatcher.get_transaction_state(tx_id);
    assert_eq!(tx_state_confirmed,TransactionState::Confirmed,"invalid state");
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    multisig_dispatcher.execute_transaction(to,selector,calldata.clone(),0);
    let tx_state_executed = multisig_dispatcher.get_transaction_state(tx_id);
    assert_eq!(tx_state_executed,TransactionState::Executed,"invalid state");
}

#[test]
fn test_quorum_change(){
    // create event observer 
    let mut spy = spy_events();
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    // create batch call
    let signers = create_signer_array();
    let calls = create_batch_call(multisig_dispatcher.contract_address,FunctionName::AddSigner,signers);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let batch_tx_id = multisig_dispatcher.submit_transaction_batch(calls.clone(),1);
    multisig_dispatcher.confirm_transaction(batch_tx_id);
    multisig_dispatcher.execute_transaction_batch(calls.clone(),1);
      let new_signers = multisig_dispatcher.get_signers();
    assert_eq!(new_signers.len(),4,"signers count wrong");
    // lets change quorum to 4 -> signer amount.
    let to = multisig_dispatcher.contract_address;
    let selector = selector_for(FunctionName::QuorumUpdate);
    let mut calldata = array![];
    let new_quorum = 4_u32 ;
    calldata.append_serde(new_quorum);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let tx_id = multisig_dispatcher.submit_transaction(to,selector,calldata.clone(),0);
    multisig_dispatcher.confirm_transaction(tx_id);
    multisig_dispatcher.execute_transaction(to,selector,calldata.clone(),0);
    // events
    let tx_submitted_event = build_tx_submitted_event(multisig_dispatcher.contract_address,tx_id,OWNER);
    let confirm_tx_event = build_tx_confirmed_event(multisig_dispatcher.contract_address,tx_id,OWNER);
    let quorum_update_event = build_quorum_updated_event(multisig_dispatcher.contract_address,1,4);
    let tx_executed_event = build_tx_executed_event(multisig_dispatcher.contract_address,tx_id);
    
    spy.assert_emitted(@tx_submitted_event);
    spy.assert_emitted(@confirm_tx_event);
    spy.assert_emitted(@tx_executed_event);
    spy.assert_emitted(@quorum_update_event);

    let updated_quorum = multisig_dispatcher.get_quorum();
    assert_eq!(updated_quorum,new_quorum,"Wrong quorum value!");   
}
#[test]
fn test_remove_signer(){
    // create event observer 
    let mut spy = spy_events();
    let multisig_dispatcher = deploy_custom_multisig_wallet();
    // create batch call
    let signers = create_signer_array();
    let calls = create_batch_call(multisig_dispatcher.contract_address,FunctionName::AddSigner,signers.clone());
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let batch_tx_id = multisig_dispatcher.submit_transaction_batch(calls.clone(),1);
    multisig_dispatcher.confirm_transaction(batch_tx_id);
    multisig_dispatcher.execute_transaction_batch(calls.clone(),1);
      let new_signers = multisig_dispatcher.get_signers();
    assert_eq!(new_signers.len(),4,"signers count wrong");
    // lets remove signer 
    let to = multisig_dispatcher.contract_address;
    let selector = selector_for(FunctionName::RemoveSigner);
    let mut calldata_rsigner = array![];
    let new_quorum = 3 ;
    let removed_signer = *signers.clone().at(2);
    calldata_rsigner.append_serde(new_quorum);
    calldata_rsigner.append_serde(removed_signer);
    cheat_caller_address(multisig_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(5));
    let tx_id = multisig_dispatcher.submit_transaction(to,selector,calldata_rsigner.clone(),0);
    multisig_dispatcher.confirm_transaction(tx_id);
    //just to see event we gonna revoke it 
    multisig_dispatcher.revoke_confirmation(tx_id);
    // to complete execution confirm again
    multisig_dispatcher.confirm_transaction(tx_id);
    multisig_dispatcher.execute_transaction(to,selector,calldata_rsigner.clone(),0);

    let confirmation_revoked_event = build_confirm_revoked_event(multisig_dispatcher.contract_address,tx_id,OWNER);
    let remove_signer_event = build_signer_removed_event(multisig_dispatcher.contract_address,removed_signer);
    
    spy.assert_emitted(@confirmation_revoked_event);
    spy.assert_emitted(@remove_signer_event);

    let is_removed = multisig_dispatcher.is_signer(removed_signer);
    assert_eq!(!is_removed,true,"signer not removed!");
}

// PANIC TESTS
// STARTS HERE ------------------------------------------------------------------>
#[test]
#[should_panic(expected: 'Multisig: not a signer')]
fn test_cannot_submit_tx_unauthorized() {
   let multisig_wallet_dispatcher = deploy_custom_multisig_wallet();
    let new_quorum = 2_u32;
    // lets create the call for submission.
    let to = multisig_wallet_dispatcher.contract_address;
    let selector = selector!("change_quorum");
    let mut calldata = array![];
    calldata.append_serde(new_quorum);
    let salt:felt252 = 0 ;
    // lets submit the transaction
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, SIGNER1, CheatSpan::TargetCalls(1));
    // its gonna fail so we dont need the id 
    let _ = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata,salt);
}
#[test]
#[should_panic(expected: 'Multisig: tx already exists')]
fn test_cannot_submit_tx_twice() {
    let multisig_wallet_dispatcher = deploy_custom_multisig_wallet();
    let new_quorum = 2_u32;
    // lets create the call for submission.
    let to = multisig_wallet_dispatcher.contract_address;
    let selector = selector!("change_quorum");
    let mut calldata = array![];
    calldata.append_serde(new_quorum);
    let salt:felt252 = 0 ;
    // lets submit the transaction
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(2));
    let _ = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata.clone(),salt);
    let _ = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata,salt); //-> gonna fail 
}

#[test]
#[should_panic(expected: 'Multisig: tx not found')]
fn test_cannot_confirm_nonexistent_tx() {
let multisig_wallet_dispatcher = deploy_custom_multisig_wallet();
cheat_caller_address(multisig_wallet_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(2));
let _ = multisig_wallet_dispatcher.confirm_transaction(0); // gonna fail
}
// ENDS HERE --------------------------------------------------------------------<

/// TEST_EVENT_UTILS STARTS -------------------------------------------------------------------->

mod test_event_utils{
    use openzeppelin_governance::multisig::MultisigComponent::{Event as MultisigEvent,SignerAdded, 
    QuorumUpdated,
    SignerRemoved,
    TransactionSubmitted,
    TransactionConfirmed,
    TransactionExecuted,
    ConfirmationRevoked,
    CallSalt};

    use starknet::ContractAddress;

    pub fn build_signer_events(
    signers: Array<ContractAddress>,
    contract: ContractAddress,
) -> Array<(ContractAddress, MultisigEvent)> {
    let mut arr = array![];

    for i in 0..signers.len() {
        arr.append((
            contract,
            MultisigEvent::SignerAdded(SignerAdded {
                signer: *signers.at(i),
            }),
        ));
    }

    arr
}

pub fn build_quorum_updated_event(
    contract: ContractAddress,
    old: u32,
    new: u32,
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::QuorumUpdated(QuorumUpdated {
            old_quorum: old,
            new_quorum: new,
        }),
    )]
}

pub fn build_signer_removed_event(
    contract: ContractAddress,
    removed_signer: ContractAddress
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::SignerRemoved(SignerRemoved {
           signer:removed_signer
        }),
    )]
}

pub fn build_tx_submitted_event(
    contract: ContractAddress,
    tx_id:felt252,
    signer: ContractAddress
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::TransactionSubmitted(TransactionSubmitted {
           id:tx_id,
           signer:signer
        }),
    )]
}

pub fn build_tx_confirmed_event(
    contract: ContractAddress,
    tx_id:felt252,
    signer: ContractAddress
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::TransactionConfirmed (TransactionConfirmed  {
           id:tx_id,
           signer:signer
        }),
    )]
}

pub fn build_confirm_revoked_event(
    contract: ContractAddress,
    tx_id:felt252,
    signer: ContractAddress
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::ConfirmationRevoked  (ConfirmationRevoked   {
           id:tx_id,
           signer:signer
        }),
    )]
}

pub fn build_tx_executed_event(
    contract: ContractAddress,
    tx_id:felt252
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::TransactionExecuted   (TransactionExecuted    {
           id:tx_id   
        }),
    )]
}
// event CallSalt for non-zero salt.
pub fn build_call_salt_event(
    contract: ContractAddress,
    tx_id:felt252,
    salt:felt252
) -> Array<(ContractAddress, MultisigEvent)> {
    array![(
        contract,
        MultisigEvent::CallSalt(CallSalt{
           id:tx_id,
           salt:salt   
        }),
    )]
}
}
/// TEST_EVENT_UTILS ENDS ----------------------------------------------------------------------<