use starknet::ContractAddress;

#[starknet::interface]
pub trait IMyUSD<TContractState> {
    // MyUSD specific functions
    fn mint_to(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn burn_from(ref self: TContractState, account: ContractAddress, amount: u256);

    // Overridden ERC20 functions with custom logic
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn total_supply(self: @TContractState) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;

    fn set_staking_contract(ref self: TContractState, staking_contract: ContractAddress);
    fn set_engine_contract(ref self: TContractState, engine_contract: ContractAddress);

    // Getters for contract addresses
    fn staking_contract(self: @TContractState) -> ContractAddress;
    fn engine_contract(self: @TContractState) -> ContractAddress;
}

// Interface for MyUSDStaking contract
#[starknet::interface]
pub trait IMyUSDStaking<TContractState> {
    fn total_shares(self: @TContractState) -> u256;
    fn get_shares_value(self: @TContractState, shares: u256) -> u256;
}

#[starknet::contract]
pub mod MyUSD {
    use core::num::traits::Zero;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::IERC20;
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};
    use crate::MyUSDStaking::{IMyUSDStakingDispatcher, IMyUSDStakingDispatcherTrait};
    use super::IMyUSD;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // External
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    // Internal implementations
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        staking_contract: ContractAddress,
        engine_contract: ContractAddress,
    }

    // Custom errors
    mod Errors {
        pub const INVALID_AMOUNT: felt252 = 'MyUSD: Invalid amount';
        pub const INSUFFICIENT_BALANCE: felt252 = 'MyUSD: Insufficient balance';
        pub const INSUFFICIENT_ALLOWANCE: felt252 = 'MyUSD: Insufficient allowance';
        pub const INVALID_ADDRESS: felt252 = 'MyUSD: Invalid address';
        pub const NOT_AUTHORIZED: felt252 = 'MyUSD: Not authorized';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Initialize ERC20
        self.erc20.initializer("MyUSD", "MyUSD");

        // Initialize Ownable
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl MyUSDImpl of IMyUSD<ContractState> {
        /// Burns tokens from an account (only callable by engine contract)
        /// Equivalent to Solidity's burnFrom with authorization check
        fn burn_from(ref self: ContractState, account: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self.engine_contract.read(), Errors::NOT_AUTHORIZED);

            // Check allowance (mimics ERC20Burnable behavior)
            let current_allowance = self.erc20.allowance(account, caller);
            assert(current_allowance >= amount, Errors::INSUFFICIENT_ALLOWANCE);

            // Update allowance
            self.erc20._approve(account, caller, current_allowance - amount);

            // Burn tokens
            self.erc20.burn(account, amount);
        }

        /// Mints tokens to an address (only callable by engine contract)
        fn mint_to(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();

            // Only the engine contract can mint
            assert(caller == self.engine_contract.read(), Errors::NOT_AUTHORIZED);

            // Validate inputs
            assert(!to.is_zero(), Errors::INVALID_ADDRESS);
            assert(amount > 0, Errors::INVALID_AMOUNT);

            // Mint tokens
            self.erc20.mint(to, amount);
            true
        }

        /// Overrides balanceOf to handle virtual balances for staking
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let staking_contract = self.staking_contract.read();

            // For normal accounts, return standard balance
            if account != staking_contract {
                return self.erc20.balance_of(account);
            }

            // For the staking contract, return the value of the shares
            let staking = IMyUSDStakingDispatcher { contract_address: staking_contract };
            let total_shares = staking.total_shares();
            staking.get_shares_value(total_shares)
        }

        /// Overrides totalSupply to handle virtual balances for staking
        fn total_supply(self: @ContractState) -> u256 {
            let staking_contract = self.staking_contract.read();
            let staking = IMyUSDStakingDispatcher { contract_address: staking_contract };

            let total_shares = staking.total_shares();
            let staked_total_supply = staking.get_shares_value(total_shares);

            self.erc20.total_supply() + staked_total_supply
        }

        /// Overrides transfer to use custom _update logic
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._update(sender, recipient, amount);
            true
        }

        /// Overrides transfer_from to use custom _update logic
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> bool {
            let caller = get_caller_address();

            // Check and update allowance
            let current_allowance = self.erc20.allowance(sender, caller);
            assert(current_allowance >= amount, Errors::INSUFFICIENT_ALLOWANCE);
            self.erc20._approve(sender, caller, current_allowance - amount);

            self._update(sender, recipient, amount);
            true
        }

        fn set_staking_contract(ref self: ContractState, staking_contract: ContractAddress) {
            self.ownable.assert_only_owner();
            self.staking_contract.write(staking_contract);
        }

        fn set_engine_contract(ref self: ContractState, engine_contract: ContractAddress) {
            self.ownable.assert_only_owner();
            self.engine_contract.write(engine_contract);
        }

        fn staking_contract(self: @ContractState) -> ContractAddress {
            self.staking_contract.read()
        }

        fn engine_contract(self: @ContractState) -> ContractAddress {
            self.engine_contract.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Custom _update function to handle virtual balances for staking
        /// If staking contract is transferring, burn or mint since its balance is virtual
        fn _update(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, value: u256,
        ) {
            let staking_contract = self.staking_contract.read();

            if from == staking_contract {
                // Staking contract is sending: mint to recipient
                self.erc20.mint(to, value);
            } else if to == staking_contract {
                // Sending to staking contract: burn from sender
                self.erc20.burn(from, value);
            } else {
                // Standard transfer between normal accounts
                let from_balance = self.erc20.balance_of(from);
                assert(from_balance >= value, Errors::INSUFFICIENT_BALANCE);

                self.erc20.update(from, to, value);
            }
        }
    }
}
