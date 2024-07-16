use starknet::ContractAddress;
#[starknet::interface]
pub trait IVendor<T> {
    fn buy_tokens(ref self: T, eth_amount_wei: u256);
    fn withdraw(ref self: T);
    fn sell_tokens(ref self: T, amount_tokens: u256);
    fn send_tokens(ref self: T, to: ContractAddress, amount_tokens: u256);
    fn tokens_per_eth(self: @T) -> u256;
    fn your_token(self: @T) -> ContractAddress;
    fn eth_token(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod Vendor {
    use contracts::YourToken::{IYourTokenDispatcher, IYourTokenDispatcherTrait};
    use core::traits::TryInto;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::interface::IOwnable;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use starknet::{get_caller_address, get_contract_address};
    use super::{ContractAddress, IVendor};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    const TokensPerEth: u256 = 100;
    const ETH_CONTRACT_ADDRESS: felt252 =
        0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7;

    #[storage]
    struct Storage {
        eth_token: IERC20CamelDispatcher,
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
        eth_amount: u256,
        tokens_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct SellTokens {
        #[key]
        seller: ContractAddress,
        tokens_amount: u256,
        eth_amount: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        eth_token_address: ContractAddress,
        your_token_address: ContractAddress,
        owner: ContractAddress
    ) {}

    #[abi(embed_v0)]
    impl VendorImpl of IVendor<ContractState> {
        fn buy_tokens(ref self: ContractState, eth_amount_wei: u256) {}

        fn withdraw(ref self: ContractState) {}

        fn sell_tokens(ref self: ContractState, amount_tokens: u256) {}

        fn send_tokens(ref self: ContractState, to: ContractAddress, amount_tokens: u256) {
            let sent = self.your_token.read().transfer(to, amount_tokens);
            assert(sent, 'Token Transfer failed');
        }

        fn tokens_per_eth(self: @ContractState) -> u256 {
            TokensPerEth
        }

        fn your_token(self: @ContractState) -> ContractAddress {
            self.your_token.read().contract_address
        }

        fn eth_token(self: @ContractState) -> ContractAddress {
            self.eth_token.read().contract_address
        }
    }
}

