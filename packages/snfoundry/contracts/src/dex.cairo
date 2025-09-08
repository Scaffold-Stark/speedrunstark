use starknet::ContractAddress;

#[starknet::interface]
pub trait IDex<TContractState> {
    /// Initializes the DEX with the specified amounts of tokens and STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     tokens: The amount of tokens to initialize the DEX with.
    ///     strk: The amount of STRK to initialize the DEX with.
    ///
    /// Returns:
    ///     (u256, u256): The amounts of tokens and STRK initialized.
    fn init(ref self: TContractState, tokens: u256, strk: u256) -> (u256, u256);

    /// Calculates the price based on the input amount and reserves.
    ///
    /// Args:
    ///     self: The contract state.
    ///     x_input: The input amount of tokens.
    ///     x_reserves: The reserve amount of tokens.
    ///     y_reserves: The reserve amount of STRK.
    ///
    /// Returns:
    ///     u256: The output amount of STRK.
    fn price(self: @TContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256;

    /// Returns the liquidity for the specified address.
    ///
    /// Args:
    ///     self: The contract state.
    ///     lp_address: The address of the liquidity provider.
    ///
    /// Returns:
    ///     u256: The liquidity amount.
    fn get_liquidity(self: @TContractState, lp_address: ContractAddress) -> u256;

    /// Returns the total liquidity in the DEX.
    ///
    /// Args:
    ///     self: The contract state.
    ///
    /// Returns:
    ///     u256: The total liquidity amount.
    fn get_total_liquidity(self: @TContractState) -> u256;

    /// Swaps STRK for tokens.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_input: The amount of STRK to swap.
    ///
    /// Returns:
    ///     u256: The amount of tokens received.
    fn strk_to_token(ref self: TContractState, strk_input: u256) -> u256;

    /// Swaps tokens for STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     token_input: The amount of tokens to swap.
    ///
    /// Returns:
    ///     u256: The amount of STRK received.
    fn token_to_strk(ref self: TContractState, token_input: u256) -> u256;

    /// Deposits STRK and tokens into the liquidity pool.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_amount: The amount of STRK to deposit.
    ///
    /// Returns:
    ///     u256: The amount of liquidity minted.
    fn deposit(ref self: TContractState, strk_amount: u256) -> u256;

    /// get deposit token amount when deposit strk_amount STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_amount: The amount of STRK to deposit.
    ///
    /// Returns:
    ///     u256: The token amount of the deposit.
    fn get_deposit_token_amount(self: @TContractState, strk_amount: u256) -> u256;

    /// Withdraws STRK and tokens from the liquidity pool.
    ///
    /// Args:
    ///     self: The contract state.
    ///     amount: The amount of liquidity to withdraw.
    ///
    /// Returns:
    ///     (u256, u256): The amounts of STRK and tokens withdrawn.
    fn withdraw(ref self: TContractState, amount: u256) -> (u256, u256);
}

#[starknet::contract]
mod Dex {
    use contracts::balloons::{IBalloonsDispatcher, IBalloonsDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use super::IDex;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    const TokensPerStrk: u256 = 100;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        strk_token: IERC20Dispatcher,
        token: IBalloonsDispatcher,
        total_liquidity: u256,
        liquidity: Map<ContractAddress, u256>,
    }

    // Todo Checkpoint 4:  Define the events.
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        LiquidityProvided: LiquidityProvided,
        LiquidityRemoved: LiquidityRemoved,
    }

    /// Event emitted when a STRK to token swap occurs.
    #[derive(Drop, starknet::Event)]
    struct StrkToTokenSwap {
        swapper: ContractAddress,
        token_output: u256,
        strk_input: u256,
    }

    /// Event emitted when a token to STRK swap occurs.
    #[derive(Drop, starknet::Event)]
    struct TokenToStrkSwap {
        swapper: ContractAddress,
        tokens_input: u256,
        strk_output: u256,
    }

    /// Event emitted when liquidity is provided to the DEX.
    #[derive(Drop, starknet::Event)]
    struct LiquidityProvided {
        liquidity_provider: ContractAddress,
        liquidity_minted: u256,
        strk_input: u256,
        tokens_input: u256,
    }

    /// Event emitted when liquidity is removed from the DEX.
    #[derive(Drop, starknet::Event)]
    struct LiquidityRemoved {
        liquidity_remover: ContractAddress,
        liquidity_withdrawn: u256,
        tokens_output: u256,
        strk_output: u256,
    }

    /// Constructor for the Dex contract.
    ///
    /// Initializes the contract with the specified STRK and token addresses.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_token_address: The address of the STRK token contract.
    ///     token_address: The address of the token contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        strk_token_address: ContractAddress,
        token_address: ContractAddress,
        owner: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.strk_token.write(IERC20Dispatcher { contract_address: strk_token_address });
        self.token.write(IBalloonsDispatcher { contract_address: token_address });
    }

    #[abi(embed_v0)]
    impl DexImpl of IDex<ContractState> {
        // Todo Checkpoint 2:  Implement your function init here.
        /// Initializes the DEX with the specified amounts of tokens and STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     tokens: The amount of tokens to initialize the DEX with.
        ///     strk: The amount of STRK to initialize the DEX with.
        ///
        /// Returns:
        ///     (u256, u256): The amounts of tokens and STRK initialized.
        fn init(ref self: ContractState, tokens: u256, strk: u256) -> (u256, u256) {
            (0, 0)
        }

        // Todo Checkpoint 3:  Implement your function price here.
        /// Calculates the price based on the input amount and reserves.
        ///
        /// Args:
        ///     self: The contract state.
        ///     x_input: The input amount of tokens.
        ///     x_reserves: The reserve amount of tokens.
        ///     y_reserves: The reserve amount of STRK.
        ///
        /// Returns:
        ///     u256: The output amount of STRK.
        fn price(self: @ContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256 {
            0
        }

        // Todo Checkpoint 5:  Implement your function get_liquidity here.
        /// Returns the liquidity for the specified address.
        ///
        /// Args:
        ///     self: The contract state.
        ///     lp_address: The address of the liquidity provider.
        ///
        /// Returns:
        ///     u256: The liquidity amount.
        fn get_liquidity(self: @ContractState, lp_address: ContractAddress) -> u256 {
            0
        }

        // Todo Checkpoint 5:  Implement your function get_total_liquidity here.
        /// Returns the total liquidity in the DEX.
        ///
        /// Args:
        ///     self: The contract state.
        ///
        /// Returns:
        ///     u256: The total liquidity amount.
        fn get_total_liquidity(self: @ContractState) -> u256 {
            0
        }

        // Todo Checkpoint 4:  Implement your function strk_to_token here.
        /// Swaps STRK for tokens.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_input: The amount of STRK to swap.
        ///
        /// Returns:
        ///     u256: The amount of tokens received.
        fn strk_to_token(ref self: ContractState, strk_input: u256) -> u256 {
            0
        }

        // Todo Checkpoint 4:  Implement your function token_to_strk here.
        /// Swaps tokens for STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     token_input: The amount of tokens to swap.
        ///
        /// Returns:
        ///     u256: The amount of STRK received.
        fn token_to_strk(ref self: ContractState, token_input: u256) -> u256 {
            0
        }

        // Todo Checkpoint 5:  Implement your function deposit here.
        /// Deposits STRK and tokens into the liquidity pool.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_amount: The amount of STRK to deposit.
        ///
        /// Returns:
        ///     u256: The amount of liquidity minted.
        fn deposit(ref self: ContractState, strk_amount: u256) -> u256 {
            0
        }

        // Todo Checkpoint 5:  Implement your function get_deposit_token_amount here.
        /// get deposit token amount when deposit strk_amount STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_amount: The amount of STRK to deposit.
        ///
        /// Returns:
        ///     u256: The token_amount of deposit.
        fn get_deposit_token_amount(self: @ContractState, strk_amount: u256) -> u256 {
            0
        }

        // Todo Checkpoint 5:  Implement your function withdraw here.
        /// Withdraws STRK and tokens from the liquidity pool.
        ///
        /// Args:
        ///     self: The contract state.
        ///     amount: The amount of liquidity to withdraw.
        ///
        /// Returns:
        ///     (u256, u256): The amounts of STRK and tokens withdrawn.
        fn withdraw(ref self: ContractState, amount: u256) -> (u256, u256) {
            (0, 0)
        }
    }
}
