use contracts::YourCollectible::{
    IYourCollectibleDispatcher, IYourCollectibleDispatcherTrait, IERC721Dispatcher,
    IERC721DispatcherTrait, IERC721EnumerableDispatcher, IERC721EnumerableDispatcherTrait
};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait};
use starknet::ContractAddress;

// Should deploy the contract
fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    println!("Contract deployed on: {:?}", contract_address);
    contract_address
}

#[test]
fn test_mint_item() {
    // Should be able to mint an NFT
    let contract_address = deploy_contract("YourCollectible");
    let dispatcher = IYourCollectibleDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };
    let tester_address = OWNER();
    println!("Tester address: {:?}", tester_address);
    let starting_balance = erc721.balance_of(tester_address);
    println!("Starting balance: {:?}", starting_balance);
    println!("Minting...");
    let url: ByteArray = "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr";
    let token_id = dispatcher.mint_item(tester_address, url);
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
    assert(token > 0, 'Token must be greater than zero');
    println!("Token of owner({:?}) by index({:?}): {:?}", tester_address, index, token);
}
