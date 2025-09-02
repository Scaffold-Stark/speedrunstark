use starknet::ContractAddress;

#[starknet::interface]
pub trait IBalloons<T> {
    /// Returns the balance of the specified account.
    ///
    /// Args:
    ///     self: The contract state.
    ///     account: The address of the account.
    ///
    /// Returns:
    ///     u256: The balance of the account.
    fn balance_of(self: @T, account: ContractAddress) -> u256;

    /// Returns the total supply of tokens.
    ///
    /// Args:
    ///     self: The contract state.
    ///
    /// Returns:
    ///     u256: The total supply of tokens.
    fn total_supply(self: @T) -> u256;

    /// Transfers tokens to the specified recipient.
    ///
    /// Args:
    ///     self: The contract state.
    ///     recipient: The address of the recipient.
    ///     amount: The amount of tokens to transfer.
    ///
    /// Returns:
    ///     bool: True if the transfer was successful, false otherwise.
    fn transfer(ref self: T, recipient: ContractAddress, amount: u256) -> bool;

    /// Approves the specified spender to spend tokens on behalf of the caller.
    ///
    /// Args:
    ///     self: The contract state.
    ///     spender: The address of the spender.
    ///     amount: The amount of tokens to approve.
    ///
    /// Returns:
    ///     bool: True if the approval was successful, false otherwise.
    fn approve(ref self: T, spender: ContractAddress, amount: u256) -> bool;

    /// Transfers tokens from one account to another.
    ///
    /// Args:
    ///     self: The contract state.
    ///     sender: The address of the sender.
    ///     recipient: The address of the recipient.
    ///     amount: The amount of tokens to transfer.
    ///
    /// Returns:
    ///     bool: True if the transfer was successful, false otherwise.
    fn transfer_from(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;

    /// Returns the remaining number of tokens that the spender is allowed to spend on behalf of the
    /// owner.
    ///
    /// Args:
    ///     self: The contract state.
    ///     owner: The address of the owner.
    ///     spender: The address of the spender.
    ///
    /// Returns:
    ///     u256: The remaining number of tokens.
    fn allowance(self: @T, owner: ContractAddress, spender: ContractAddress) -> u256;
}

#[starknet::contract]
mod Balloons {
    use openzeppelin_token::erc20::interface::IERC20;
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use super::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

    impl ERC20ImmutableConfig of ERC20Component::ImmutableConfig {
        const DECIMALS: u8 = 18;
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    // Todo Checkpoint 1: Edit the constructor to mint the initial supply of tokens to the
    // recipient.
    /// Constructor for the Balloons contract.
    ///
    /// Initializes the ERC20 token with a name and symbol, and mints the initial supply to the
    /// recipient.
    ///
    /// Args:
    ///     self: The contract state.
    ///     initial_supply: The initial supply of tokens to mint.
    ///     recipient: The address of the recipient to receive the initial supply.
    #[constructor]
    fn constructor(ref self: ContractState, initial_supply: u256, recipient: ContractAddress) {
        let name = "Balloons";
        let symbol = "BAL";
        self.erc20.initializer(name, symbol);
        // Mint the initial supply of tokens to the recipient
    }

    #[abi(embed_v0)]
    impl IBalloonsImpl of IERC20<ContractState> {
        /// Returns the balance of the specified account.
        ///
        /// Args:
        ///     self: The contract state.
        ///     account: The address of the account.
        ///
        /// Returns:
        ///     u256: The balance of the account.
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        /// Returns the total supply of tokens.
        ///
        /// Args:
        ///     self: The contract state.
        ///
        /// Returns:
        ///     u256: The total supply of tokens.
        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        /// Transfers tokens to the specified recipient.
        ///
        /// Args:
        ///     self: The contract state.
        ///     recipient: The address of the recipient.
        ///     amount: The amount of tokens to transfer.
        ///
        /// Returns:
        ///     bool: True if the transfer was successful, false otherwise.
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            self.erc20.transfer(recipient, amount)
        }

        /// Approves the specified spender to spend tokens on behalf of the caller.
        ///
        /// Args:
        ///     self: The contract state.
        ///     spender: The address of the spender.
        ///     amount: The amount of tokens to approve.
        ///
        /// Returns:
        ///     bool: True if the approval was successful, false otherwise.
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            self.erc20.approve(spender, amount)
        }

        /// Transfers tokens from one account to another.
        ///
        /// Args:
        ///     self: The contract state.
        ///     sender: The address of the sender.
        ///     recipient: The address of the recipient.
        ///     amount: The amount of tokens to transfer.
        ///
        /// Returns:
        ///     bool: True if the transfer was successful, false otherwise.
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> bool {
            self.erc20.transfer_from(sender, recipient, amount)
        }

        /// Returns the remaining number of tokens that the spender is allowed to spend on behalf of
        /// the owner.
        ///
        /// Args:
        ///     self: The contract state.
        ///     owner: The address of the owner.
        ///     spender: The address of the spender.
        ///
        /// Returns:
        ///     u256: The remaining number of tokens.
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress,
        ) -> u256 {
            self.erc20.allowance(owner, spender)
        }
    }
}
