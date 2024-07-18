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
    ) {
        self.eth_token.write(IERC20CamelDispatcher { contract_address: eth_token_address });
        self.your_token.write(IYourTokenDispatcher { contract_address: your_token_address });
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl VendorImpl of IVendor<ContractState> {
        fn buy_tokens(ref self: ContractState, eth_amount_wei: u256) {
            assert(eth_amount_wei > 0, 'Amount must be greater than 0');
            let tokens_to_buy = eth_amount_wei * TokensPerEth;
            let vendor_token_balance = self.your_token.read().balance_of(get_contract_address());
            assert(vendor_token_balance >= tokens_to_buy, 'NOT ENOUGHT TOKENS');
            //call fn approve() on UI 
            self
                .eth_token
                .read()
                .transferFrom(get_caller_address(), get_contract_address(), eth_amount_wei);
            let sent = self.your_token.read().transfer(get_caller_address(), tokens_to_buy);
            assert(sent, 'Token Transfer failed');
            self
                .emit(
                    BuyTokens {
                        buyer: get_caller_address(),
                        eth_amount: eth_amount_wei,
                        tokens_amount: tokens_to_buy,
                    }
                );
        }

        fn withdraw(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let balance = self.eth_token.read().balanceOf(get_contract_address());
            let sent = self.eth_token.read().transfer(self.ownable.owner(), balance);
            assert(sent, 'Eth Transfer failed');
        }

        fn sell_tokens(ref self: ContractState, amount_tokens: u256) {
            assert(amount_tokens > 0, 'Amount must be greater than 0');
            let eth_amount_wei = amount_tokens / TokensPerEth;
            let contract_eth_balance = self.eth_token.read().balanceOf(get_caller_address());
            assert(contract_eth_balance >= eth_amount_wei, 'NOT Enough tokens');
            // call fn approve() on UI 
            let sent = self
                .your_token
                .read()
                .transfer_from(get_caller_address(), get_contract_address(), amount_tokens);
            assert(sent, 'Tokens Transfer failed');

            let sent = self.eth_token.read().transfer(get_caller_address(), eth_amount_wei);
            assert(sent, 'Eth Transfer failed');
            self
                .emit(
                    SellTokens {
                        seller: get_caller_address(),
                        tokens_amount: amount_tokens,
                        eth_amount: eth_amount_wei,
                    }
                );
        }

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

