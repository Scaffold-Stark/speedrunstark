use contracts::YourCollectible::{
    IYourCollectibleDispatcher, IYourCollectibleDispatcherTrait, IERC721Dispatcher,
    IERC721DispatcherTrait, IERC721EnumerableDispatcher, IERC721EnumerableDispatcherTrait
};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait, load, map_entry_address};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_mint_item() {
    let contract_address = deploy_contract("YourCollectible");
    let dispatcher = IYourCollectibleDispatcher { contract_address };
    let url: ByteArray = "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr";
    let token_id = dispatcher.mint_item(OWNER(), url);
    let expected_token_id = 1;
    assert_eq!(token_id, expected_token_id);
}

#[test]
fn track_tokens_of_owner_by_index() {
    let contract_address = deploy_contract("YourCollectible");
    let dispatcher = IYourCollectibleDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };
    let erc721Enumerable = IERC721EnumerableDispatcher { contract_address };
    let url: ByteArray = "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr";
    dispatcher.mint_item(OWNER(), url);
    let starting_balance = erc721.balance_of(OWNER());
    let token = erc721Enumerable.token_of_owner_by_index(OWNER(), starting_balance - 1);

    assert(token == 1, 'Token must be 1');
}
