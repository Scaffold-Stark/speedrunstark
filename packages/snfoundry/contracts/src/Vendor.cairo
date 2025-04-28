use starknet::ContractAddress;
#[starknet::interface]
pub trait IVendor<T> {
    fn buy_tokens(ref self: T, strk_amount_fri: u256);
    fn withdraw(ref self: T);
    fn sell_tokens(ref self: T, amount_tokens: u256);
    fn tokens_per_strk(self: @T) -> u256;
    fn your_token(self: @T) -> ContractAddress;
    fn strk_token(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod Vendor {
    use contracts::YourToken::{IYourTokenDispatcher, IYourTokenDispatcherTrait};
    use core::traits::TryInto;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_access::ownable::interface::IOwnable;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{get_caller_address, get_contract_address};
    use super::{ContractAddress, IVendor};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // ToDo Checkpoint 2: Define const TokensPerStrk

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        strk_token: IERC20Dispatcher,
        your_token: IYourTokenDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        BuyTokens: BuyTokens,
        SellTokens: SellTokens,
    }

    #[derive(Drop, starknet::Event)]
    struct BuyTokens {
        buyer: ContractAddress,
        strk_amount: u256,
        tokens_amount: u256,
    }

    //  ToDo Checkpoint 3: Define the event SellTokens
    #[derive(Drop, starknet::Event)]
    struct SellTokens {}

    #[constructor]
    // Todo Checkpoint 2: Edit the constructor to initialize the owner of the contract.
    fn constructor(
        ref self: ContractState,
        strk_token_address: ContractAddress,
        your_token_address: ContractAddress,
    ) {
        self.strk_token.write(IERC20Dispatcher { contract_address: strk_token_address });
        self.your_token.write(IYourTokenDispatcher { contract_address: your_token_address });
        // ToDo Checkpoint 2: Initialize the owner of the contract here.
    }
    #[abi(embed_v0)]
    impl VendorImpl of IVendor<ContractState> {
        // ToDo Checkpoint 2: Implement your function buy_tokens here.
        fn buy_tokens(
            ref self: ContractState, strk_amount_fri: u256,
        ) { // Note: In UI and Debug contract `buyer` should call `approve`` before to `transfer` the amount to the `Vendor` contract.
        }

        // ToDo Checkpoint 2: Implement your function withdraw here.
        fn withdraw(ref self: ContractState) {}

        // ToDo Checkpoint 3: Implement your function sell_tokens here.
        fn sell_tokens(ref self: ContractState, amount_tokens: u256) {}

        // ToDo Checkpoint 2: Modify to return the amount of tokens per 1 STRK.
        fn tokens_per_strk(self: @ContractState) -> u256 {
            0
        }

        fn your_token(self: @ContractState) -> ContractAddress {
            self.your_token.read().contract_address
        }

        fn strk_token(self: @ContractState) -> ContractAddress {
            self.strk_token.read().contract_address
        }
    }
}
