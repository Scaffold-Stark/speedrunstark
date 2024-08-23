use core::clone::Clone;
use contracts::YourCollectible::{
    IYourCollectibleDispatcher, IYourCollectibleDispatcherTrait, IERC721Dispatcher,
    IERC721DispatcherTrait, IERC721EnumerableDispatcher, IERC721EnumerableDispatcherTrait,
    IERC721MetadataDispatcher, IERC721MetadataDispatcherTrait
};

use contracts::mock_contracts::Receiver;
use openzeppelin::tests::utils;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait};
use starknet::ContractAddress;
use starknet::contract_address_const;

// Should deploy the contract
fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    println!("Contract deployed on: {:?}", contract_address);
    contract_address
}

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn NEW_OWNER() -> ContractAddress {
    contract_address_const::<'NEW_OWNER'>()
}
fn deploy_receiver() -> ContractAddress {
    let contract = declare("Receiver").unwrap();
    let mut calldata = array![];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    println!("Receiver deployed on: {:?}", contract_address);
    contract_address
}

#[test]
// Test mint two items and transfer the last item
fn test_mint_item() {
    // Should be able to mint an NFT
    let contract_address = deploy_contract("YourCollectible");
    let dispatcher = IYourCollectibleDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };
    let tester_address = deploy_receiver();
    println!("Tester address: {:?}", tester_address);
    let starting_balance = erc721.balance_of(tester_address);
    println!("Starting balance: {:?}", starting_balance);
    println!("Minting...");
    let url: ByteArray = "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr";
    let token_id = dispatcher.mint_item(tester_address, url.clone());
    let expected_token_id = 1;
    assert(token_id == expected_token_id, 'Token ID must be 1');
    println!("Item minted! Token ID: {:?}", token_id);
    let new_balance = erc721.balance_of(tester_address);
    assert(new_balance == starting_balance + 1, 'Balance must be increased by 1');
    println!("New balance: {:?}", new_balance);

    // Should track tokens of owner by index
    let erc721Enumerable = IERC721EnumerableDispatcher { contract_address };
    let index = new_balance - 1;
    let token = erc721Enumerable.token_of_owner_by_index(tester_address, index);
    println!("token of owner by index {:?}", token);
    assert(token > 0, 'Token must be greater than zero');
    println!("Token of owner({:?}) by index({:?}): {:?}", tester_address, index, token);

    // mint another item
    let url2: ByteArray = "QmVHi3c4qkZcH3cJynzDXRm5n7dzc9R9TUtUcfnWQvhdcw";
    let token_id = dispatcher.mint_item(tester_address, url2);
    let expected_token_id = 2;
    assert(token_id == expected_token_id, 'Token ID must be 2');
    println!("Item minted! Token ID: {:?}", token_id);
    let new_balance = erc721.balance_of(tester_address);
    assert(new_balance == starting_balance + 2, 'Balance must be increased by 2');
    println!("New balance: {:?}", new_balance);

    // transfer item
    let new_owner = NEW_OWNER();
    println!("new_owner address: {:?}", new_owner);
    let starting_balance = erc721.balance_of(new_owner);
    println!("Starting balance new_owner: {:?}", starting_balance);

    erc721.transfer_from(tester_address, new_owner, 1);
    let balance_new_owner = erc721.balance_of(new_owner);
    assert(balance_new_owner == starting_balance + 1, 'Balance must be increased by 1');
    println!("New balance new_owner: {:?}", balance_new_owner);

    let balance_tester = erc721.balance_of(tester_address);
    assert(balance_tester == new_balance - 1, 'Balance must be decreased by 1');
    println!("New balance tester: {:?}", balance_tester);

    let erc721Metadata = IERC721MetadataDispatcher { contract_address };
    let token_uri = erc721Metadata.token_uri(1);
    println!("Token URI: {:?}", token_uri);

    // owner_of
    let owner = erc721.owner_of(1);
    assert(owner == new_owner, 'Owner must be new_owner');

    let owner = erc721.owner_of(2);
    assert(owner == tester_address, 'Owner must be tester_address');

    let index = erc721Enumerable.token_of_owner_by_index(new_owner, 0);
    println!("token of owner by index {:?}", index);
    assert(index == 1, 'Token must be 1');

    let index = erc721Enumerable.token_of_owner_by_index(tester_address, 0);
    println!("token of owner by index {:?}", index);
    assert(index == 2, 'Token must be 2');
}


#[test]
// Test: mint one item and transfer it to another account
fn test_mint_item2() {
    // Should be able to mint an NFT
    let contract_address = deploy_contract("YourCollectible");
    let dispatcher = IYourCollectibleDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };
    let tester_address = deploy_receiver();
    println!("Tester address: {:?}", tester_address);
    let starting_balance = erc721.balance_of(tester_address);
    println!("Starting balance: {:?}", starting_balance);
    println!("Minting...");
    let url: ByteArray = "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr";
    let token_id = dispatcher.mint_item(tester_address, url.clone());
    let expected_token_id = 1;
    assert(token_id == expected_token_id, 'Token ID must be 1');
    println!("Item minted! Token ID: {:?}", token_id);
    let new_balance = erc721.balance_of(tester_address);
    assert(new_balance == starting_balance + 1, 'Balance must be increased by 1');
    println!("New balance: {:?}", new_balance);

    // Should track tokens of owner by index
    let erc721Enumerable = IERC721EnumerableDispatcher { contract_address };
    let index = new_balance - 1;
    let token = erc721Enumerable.token_of_owner_by_index(tester_address, index);
    println!("token of owner by index {:?}", token);
    assert(token > 0, 'Token must be greater than zero');
    println!("Token of owner({:?}) by index({:?}): {:?}", tester_address, index, token);

    // transfer item
    let new_owner = NEW_OWNER();
    println!("new_owner address: {:?}", new_owner);
    let starting_balance = erc721.balance_of(new_owner);
    println!("Starting balance new_owner: {:?}", starting_balance);

    erc721.transfer_from(tester_address, new_owner, 1);
    let balance_new_owner = erc721.balance_of(new_owner);
    assert(balance_new_owner == starting_balance + 1, 'Balance must be increased by 1');
    println!("New balance new_owner: {:?}", balance_new_owner);

    let balance_tester = erc721.balance_of(tester_address);
    assert(balance_tester == new_balance - 1, 'Balance must be decreased by 1');
    println!("New balance tester: {:?}", balance_tester);

    let erc721Metadata = IERC721MetadataDispatcher { contract_address };
    let token_uri = erc721Metadata.token_uri(1);
    println!("Token URI: {:?}", token_uri);

    // owner_of
    let owner = erc721.owner_of(1);
    assert(owner == new_owner, 'Owner must be new_owner');

    let index = erc721Enumerable.token_of_owner_by_index(new_owner, 0);
    println!("token of owner by index {:?}", index);
    assert(index == 1, 'Token must be 1');
}
