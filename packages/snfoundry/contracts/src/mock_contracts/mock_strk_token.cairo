#[starknet::contract]
pub mod MockSTRKToken {
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::ContractAddress;

    // Import the ERC20 component and event from OpenZeppelin's ERC20 implementation
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    // Embed the ERC20 implementation ABI
    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    impl ERC20ImmutableConfig of ERC20Component::ImmutableConfig {
        const DECIMALS: u8 = 18;
    }

    // Define the storage structure for the contract
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    // Define the events emitted by the contract
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    /// Constructor for the MockSTRKToken contract.
    ///
    /// Initializes the ERC20 token with a name and symbol, and mints the initial supply to the
    /// recipient.
    ///
    /// Args:
    ///     self (ContractState): The contract state.
    ///     initial_supply (u256): The initial supply of tokens to mint.
    ///     recipient (ContractAddress): The address of the recipient to receive the initial supply.
    #[constructor]
    fn constructor(ref self: ContractState, initial_supply: u256, recipient: ContractAddress) {
        let name = "MockSTRK";
        let symbol = "STRK";

        // Initialize the ERC20 token with the specified name and symbol
        self.erc20.initializer(name, symbol);
        // Mint the initial supply of tokens to the recipient
        self.erc20.mint(recipient, initial_supply);
    }
}
