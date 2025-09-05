
// ## EXAMPLE TESTS FOR MULISIG WALLET TESTING
use starknet::ContractAddress;
use starknet::account::Call;

pub type TransactionID = felt252;
pub type TransactionState = openzeppelin_governance::multisig::interface::TransactionState;

use openzeppelin_governance::multisig::interface::{
                             IMultisigDispatcher,
                             IMultisigDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address,spy_events,EventSpyAssertionsTrait };


use test_event_utils::{build_quorum_updated_event,
                build_signer_events,
                build_confirm_revoked_event,
                build_tx_submitted_event,
                build_tx_confirmed_event,
                build_tx_executed_event,
                build_signer_removed_event
            };

/// SIGNERS 
const SIGNER1: ContractAddress = 'SIGNER1'.try_into().unwrap();
const SIGNER2: ContractAddress = 'SIGNER2'.try_into().unwrap();
const SIGNER3: ContractAddress = 'SIGNER3'.try_into().unwrap();
const SIGNER4: ContractAddress = 'SIGNER4'.try_into().unwrap();

const NEWSIGNER: ContractAddress = 'NEWSIGNER'.try_into().unwrap();
const NEWSIGNER2: ContractAddress ='NEWSIGNER2'.try_into().unwrap();

fn create_signers_array()-> Array<ContractAddress>{
    let mut signers:Array<ContractAddress> = array![];
    signers.append(SIGNER1);
    signers.append(SIGNER2);
    signers.append(SIGNER3);
    signers.append(SIGNER4);
    signers
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

fn deploy_multisig_wallet() -> IMultisigDispatcher{
   let signers = create_signers_array();
    
    let quorum:u32= signers.len();
    let mut constructor_calldata = array![];
    constructor_calldata.append_serde(quorum);
    constructor_calldata.append_serde(signers);
    
    let multisig_wallet_address = declare_and_deploy("MultisigWallet",constructor_calldata);
    IMultisigDispatcher{contract_address:multisig_wallet_address}
}
#[test]
fn test_deploy_multisig(){
    // lets set event observer;
    let mut spy = spy_events();
    // test quorum and signers 
    let multisig_wallet_dispatcher = deploy_multisig_wallet();
    let signers = create_signers_array();
    let expected_quorum = signers.len();
    // lets build events 
    let signers_event = build_signer_events(signers.clone(),multisig_wallet_dispatcher.contract_address);
    let quorum_update_event = build_quorum_updated_event(multisig_wallet_dispatcher.contract_address,0,expected_quorum);
    // lets spy on those events.
    spy.assert_emitted(@signers_event);
    spy.assert_emitted(@quorum_update_event);

    let get_signers_array = multisig_wallet_dispatcher.get_signers();
    let current_quorum = multisig_wallet_dispatcher.get_quorum();

    assert_eq!(expected_quorum,current_quorum,"quorum incorrect!");
    assert_eq!(multisig_wallet_dispatcher.is_signer(SIGNER1),true,"incorrect signer!");

    for i in 0..signers.len() {
        assert_eq!(signers.at(i),get_signers_array.at(i),"signers not correct!");
    }
}

#[test]
fn test_single_transaction(){
    // lets set event observer;
    let mut spy = spy_events();
    // this test's demonstrates single transaction effects. 
    let multisig_wallet_dispatcher = deploy_multisig_wallet();
    let signers = create_signers_array();
    let new_quorum = 2_u32;
    // lets create the call for submission.
    let to = multisig_wallet_dispatcher.contract_address;
    let selector = selector!("change_quorum");
    let mut calldata = array![];
    calldata.append_serde(new_quorum);
    let salt:felt252 = 0 ;
    // lets submit the transaction
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    let tx_id = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata.span(),salt);
    let tx_submitted_event = build_tx_submitted_event(multisig_wallet_dispatcher.contract_address,tx_id,*signers.at(0));
    spy.assert_emitted(@tx_submitted_event);
    // check tx hashing 
    let tx_hash = multisig_wallet_dispatcher.hash_transaction(to,selector,calldata.span(),salt);
    assert_eq!(tx_hash,tx_id,"incorrect hashing!");

    // check tx state.
    let tx_state = multisig_wallet_dispatcher.get_transaction_state(tx_id);
    assert_eq!(tx_state,TransactionState::Pending,"incorrect tx state");
   
    // now we confirm the transaction -> Dont forget we set old quorum to 4 so we need to confirm all of them.
    for i in 0..signers.len(){
        cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(i), CheatSpan::TargetCalls(1));
        multisig_wallet_dispatcher.confirm_transaction(tx_id);
    } 
    // lets test is_confirmed and is_confrimed_by functions.
    let is_confirmed = multisig_wallet_dispatcher.is_confirmed(tx_id);
    let is_confirmed_by= multisig_wallet_dispatcher.is_confirmed_by(tx_id,*signers.at(0));
    let get_transaction_confirmations = multisig_wallet_dispatcher.get_transaction_confirmations(tx_id);

    assert_eq!(is_confirmed,true,"tx not confirmed!");
    assert_eq!(is_confirmed_by,true,"tx not confirmed by signer!");
    assert_eq!(get_transaction_confirmations,signers.len(),"incorrect confirmation count!");

    // one of the signer changes his/her mind and revokes his confirmation.
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    multisig_wallet_dispatcher.revoke_confirmation(tx_id);
    let new_confrimation_count = multisig_wallet_dispatcher.get_transaction_confirmations(tx_id);
    assert_eq!(new_confrimation_count,signers.len()-1,"incorrect confirmation count!");
    let revoke_event = build_confirm_revoked_event(multisig_wallet_dispatcher.contract_address,tx_id,*signers.at(0));
    spy.assert_emitted(@revoke_event);
    // other signers beat up revoker and force him to confirm it😆😆😆
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    multisig_wallet_dispatcher.confirm_transaction(tx_id);
    let tx_confirmed_event = build_tx_confirmed_event(multisig_wallet_dispatcher.contract_address,tx_id,*signers.at(0));
    spy.assert_emitted(@tx_confirmed_event);
    // tx confirmed but not executed yet.
    let is_executed = multisig_wallet_dispatcher.is_executed(tx_id);
    assert_eq!(is_executed,false,"incorrect execution state!");

    // after the confirmations we can execute tx by any of the signers.
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    multisig_wallet_dispatcher.execute_transaction(to,selector,calldata.span(),salt);
    let tx_executed_event = build_tx_executed_event(multisig_wallet_dispatcher.contract_address,tx_id);
    spy.assert_emitted(@tx_executed_event);
    // after execution we can check our new quorum.
    let quorum = multisig_wallet_dispatcher.get_quorum();
    assert_eq!(new_quorum,quorum,"incorrect quorum!");

    // lets replace signer 
    let old_signer = *signers.at(3);
    let new_signer = NEWSIGNER;
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    let replace_signer_selector = selector!("replace_signer");
    let mut replace_signer_calldata = array![];
    replace_signer_calldata.append_serde(old_signer);
    replace_signer_calldata.append_serde(new_signer);

    let replace_signer_tx_id = multisig_wallet_dispatcher.submit_transaction(
        to,
        replace_signer_selector,
        replace_signer_calldata.span(),
        0);
    // confirm tx.    
    for i in 0..signers.len(){
        cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(i), CheatSpan::TargetCalls(1));
        multisig_wallet_dispatcher.confirm_transaction(replace_signer_tx_id);
    } 
    // execute 
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    multisig_wallet_dispatcher.execute_transaction(to,replace_signer_selector,replace_signer_calldata.span(),0);
    let signer_removed_event = build_signer_removed_event(multisig_wallet_dispatcher.contract_address,old_signer);
    spy.assert_emitted(@signer_removed_event);
    // test effect
    let get_latest_signers = multisig_wallet_dispatcher.get_signers();
    for i in 0..get_latest_signers.len(){
     println!("Signers: {:?}", get_latest_signers.at(i));
    }
   
    assert_eq!(*get_latest_signers.at(3),new_signer,"incorrect signer!");

}

//    Call{
//         to:wallet_dispatcher.contract_address,
//         selector:selector!("change_quorum"),
//         calldata:quorum_calldata.span(),
//     };
#[test]
fn test_batch_transaction(){
    // this test'll demonstrate batch transaction effects. 
    let multisig_wallet_dispatcher = deploy_multisig_wallet();
    let signers = create_signers_array();
    // batch tx requires calls to be structored as starknet::account::Call;
    let mut batch_call:Array<Call> = array![];
    // add_signer 
    let mut calldata_add_signers = array![];
    // lets keep quorum same so we can test it with array.
    calldata_add_signers.append_serde(4);
    let new_signers = create_newsigners_array();
    calldata_add_signers.append_serde(new_signers);
    let add_signers_call = Call{
                        to:multisig_wallet_dispatcher.contract_address,
                        selector:selector!("add_signers"),
                        calldata:calldata_add_signers.span(),
    };

    let mut calldata_remove_signers = array![];
    calldata_remove_signers.append_serde(2);
    let replaceable_signers = create_replaceablesigners_array();
    calldata_remove_signers.append_serde(replaceable_signers);
    let remove_signers_call = Call{
                        to:multisig_wallet_dispatcher.contract_address,
                        selector:selector!("remove_signers"),
                        calldata:calldata_remove_signers.span(),
    };

    // finaly append the calls
    batch_call.append(add_signers_call);
    batch_call.append(remove_signers_call);
    let salt = 0;
    
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
    let tx_batch_id = multisig_wallet_dispatcher.submit_transaction_batch(batch_call.span(),salt);
    // lets check tx batch hash;
    let tx_batch_hash = multisig_wallet_dispatcher.hash_transaction_batch(batch_call.span(),salt);
    assert_eq!(tx_batch_id,tx_batch_hash,"incorrect batch hashing!");
    // now we confirm the transaction -> Dont forget we set old quorum to 4 so we need to confirm all of them.
    for i in 0..signers.len(){
        cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(i), CheatSpan::TargetCalls(1));
        multisig_wallet_dispatcher.confirm_transaction(tx_batch_id);
    } 
      cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(1));
       multisig_wallet_dispatcher.execute_transaction_batch(batch_call.span(),0);
    // batch execution confirmed so lets check new quorum it should be 2 
    let latest_quorum = multisig_wallet_dispatcher.get_quorum();
    assert_eq!(latest_quorum,2,"incorrect quorum!");
    let get_signers = multisig_wallet_dispatcher.get_signers();
    assert_eq!(get_signers.at(3),@NEWSIGNER,"incorrect signer!");

}
// PANIC TESTS
// STARTS HERE ------------------------------------------------------------------>
#[test]
#[should_panic(expected: 'Multisig: not a signer')]
fn test_cannot_submit_tx_unauthorized() {
   let multisig_wallet_dispatcher = deploy_multisig_wallet();
    let new_quorum = 2_u32;
    // lets create the call for submission.
    let to = multisig_wallet_dispatcher.contract_address;
    let selector = selector!("change_quorum");
    let mut calldata = array![];
    calldata.append_serde(new_quorum);
    let salt:felt252 = 0 ;
    // lets submit the transaction
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, NEWSIGNER, CheatSpan::TargetCalls(1));
    // its gonna fail so we dont need the id 
    let _ = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata.span(),salt);
}
#[test]
#[should_panic(expected: 'Multisig: tx already exists')]
fn test_cannot_submit_tx_twice() {
    let multisig_wallet_dispatcher = deploy_multisig_wallet();
    let signers = create_signers_array();
    let new_quorum = 2_u32;
    // lets create the call for submission.
    let to = multisig_wallet_dispatcher.contract_address;
    let selector = selector!("change_quorum");
    let mut calldata = array![];
    calldata.append_serde(new_quorum);
    let salt:felt252 = 0 ;
    // lets submit the transaction
    cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(2));
    let _ = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata.span(),salt);
    let _ = multisig_wallet_dispatcher.submit_transaction(to,selector,calldata.span(),salt); //-> gonna fail 
}

#[test]
#[should_panic(expected: 'Multisig: tx not found')]
fn test_cannot_confirm_nonexistent_tx() {
let multisig_wallet_dispatcher = deploy_multisig_wallet();
let signers = create_signers_array();
cheat_caller_address(multisig_wallet_dispatcher.contract_address, *signers.at(0), CheatSpan::TargetCalls(2));
let _ = multisig_wallet_dispatcher.confirm_transaction(0); // gonna fail
}
// ENDS HERE --------------------------------------------------------------------<

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

// pub trait IMultisig<TState> {
//  ✅ fn get_quorum(self: @TState) -> u32;
//  ✅ fn is_signer(self: @TState, signer: ContractAddress) -> bool;
//  ✅ fn get_signers(self: @TState) -> Span<ContractAddress>;
//  ✅ fn is_confirmed(self: @TState, id: TransactionID) -> bool;
//  ✅ fn is_confirmed_by(self: @TState, id: TransactionID, signer: ContractAddress) -> bool;
//  ✅ fn is_executed(self: @TState, id: TransactionID) -> bool;
//      fn get_submitted_block(self: @TState, id: TransactionID) -> u64;
//  ✅ fn get_transaction_state(self: @TState, id: TransactionID) -> TransactionState;
//  ✅ fn get_transaction_confirmations(self: @TState, id: TransactionID) -> u32;
//  ✅ fn hash_transaction(
//         self: @TState,
//         to: ContractAddress,
//         selector: felt252,
//         calldata: Span<felt252>,
//         salt: felt252,
//     ) -> TransactionID;
//  ✅ fn hash_transaction_batch(self: @TState, calls: Span<Call>, salt: felt252) -> TransactionID;

//  ✅ fn add_signers(ref self: TState, new_quorum: u32, signers_to_add: Span<ContractAddress>);
//  ✅ fn remove_signers(ref self: TState, new_quorum: u32, signers_to_remove: Span<ContractAddress>);
//     fn replace_signer(
//         ref self: TState, signer_to_remove: ContractAddress, signer_to_add: ContractAddress,
//     );
//  ✅ fn change_quorum(ref self: TState, new_quorum: u32);
//  ✅ fn submit_transaction(
//         ref self: TState,
//         to: ContractAddress,
//         selector: felt252,
//         calldata: Span<felt252>,
//         salt: felt252,
//      ) -> TransactionID;
//  ✅  fn submit_transaction_batch(
//         ref self: TState, calls: Span<Call>, salt: felt252,
//       ) -> TransactionID;
//  ✅  fn confirm_transaction(ref self: TState, id: TransactionID);
//  ✅  fn revoke_confirmation(ref self: TState, id: TransactionID);
//  ✅  fn execute_transaction(
//         ref self: TState,
//         to: ContractAddress,
//         selector: felt252,
//         calldata: Span<felt252>,
//         salt: felt252,
//     );
//   ✅ fn execute_transaction_batch(ref self: TState, calls: Span<Call>, salt: felt252);
// }



