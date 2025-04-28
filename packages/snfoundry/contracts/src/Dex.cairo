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
    fn getLiquidity(self: @TContractState, lp_address: ContractAddress) -> u256;

    /// Returns the total liquidity in the DEX.
    ///
    /// Args:
    ///     self: The contract state.
    ///
    /// Returns:
    ///     u256: The total liquidity amount.
    fn getTotalLiquidity(self: @TContractState) -> u256;

    /// Swaps STRK for tokens.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_input: The amount of STRK to swap.
    ///
    /// Returns:
    ///     u256: The amount of tokens received.
    fn strkToToken(ref self: TContractState, strk_input: u256) -> u256;

    /// Swaps tokens for STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     token_input: The amount of tokens to swap.
    ///
    /// Returns:
    ///     u256: The amount of STRK received.
    fn tokenToStrk(ref self: TContractState, token_input: u256) -> u256;

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
    fn getDepositTokenAmount(self: @TContractState, strk_amount: u256) -> u256;

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
    use contracts::Balloons::{IBalloonsDispatcher, IBalloonsDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{get_caller_address, get_contract_address};
    use starknet::storage::{Map, StorageMapReadAccess,StorageMapWriteAccess};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress};
    use super::{IDex};

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
        StrkToTokenSwap: StrkToTokenSwap,
        TokenToStrkSwap: TokenToStrkSwap,
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
    ) {
        self.ownable.initializer(get_caller_address());
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
            let total_liquidity = self.total_liquidity.read();
            assert(total_liquidity == 0, 'DEX-Init:already has liquidity');

            let contract_address = get_contract_address();
            let caller = get_caller_address();
            let strk_token_contract = self.strk_token.read();
            assert(
                strk_token_contract.transfer_from(caller, contract_address, strk),
                'Transfer STRK failed',
            );
            self.total_liquidity.write(strk);
            self.liquidity.write(caller, strk);

            let token_contract = self.token.read();
            assert(
                token_contract.transfer_from(caller, contract_address, tokens),
                'Transfer token failed',
            );
            (tokens, strk)
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
            let x_input_with_fee = x_input * 997_u256;
            let numerator = x_input_with_fee * y_reserves;
            let denominator = (x_reserves * 1000_u256) + x_input_with_fee;
            numerator / denominator
        }

        // Todo Checkpoint 5:  Implement your function getLiquidity here.
        /// Returns the liquidity for the specified address.
        ///
        /// Args:
        ///     self: The contract state.
        ///     lp_address: The address of the liquidity provider.
        ///
        /// Returns:
        ///     u256: The liquidity amount.
        fn getLiquidity(self: @ContractState, lp_address: ContractAddress) -> u256 {
            self.liquidity.read(lp_address)
        }

        // Todo Checkpoint 5:  Implement your function getTotalLiquidity here.
        /// Returns the total liquidity in the DEX.
        ///
        /// Args:
        ///     self: The contract state.
        ///
        /// Returns:
        ///     u256: The total liquidity amount.
        fn getTotalLiquidity(self: @ContractState) -> u256 {
            self.total_liquidity.read()
        }

        // Todo Checkpoint 4:  Implement your function strkToToken here.
        /// Swaps STRK for tokens.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_input: The amount of STRK to swap.
        ///
        /// Returns:
        ///     u256: The amount of tokens received.
        fn strkToToken(ref self: ContractState, strk_input: u256) -> u256 {
            assert(strk_input > 0, 'Cannot swap 0 strk');
            let caller = get_caller_address();
            let strk_balance = self.strk_token.read().balance_of(caller);
            assert(strk_balance > 0, 'Insufficient strk balance');
            let contract_address = get_contract_address();
            assert(
                self.strk_token.read().allowance(caller, contract_address) >= strk_input,
                'Insufficient allowance',
            );

            let token_reserve = self.token.read().balance_of(contract_address);
            let strk_reserve = self.strk_token.read().balance_of(contract_address);

            let tokens_bought = self.price(strk_input, strk_reserve - strk_input, token_reserve);

            assert(
                self.strk_token.read().transfer_from(caller, contract_address, strk_input),
                'STRK transfer failed',
            );
            assert(self.token.read().transfer(caller, tokens_bought), 'Token transfer failed');

            self
                .emit(
                    StrkToTokenSwap {
                        swapper: caller, token_output: tokens_bought, strk_input: strk_input,
                    },
                );

            tokens_bought
        }

        // Todo Checkpoint 4:  Implement your function tokenToStrk here.
        /// Swaps tokens for STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     token_input: The amount of tokens to swap.
        ///
        /// Returns:
        ///     u256: The amount of STRK received.
        fn tokenToStrk(ref self: ContractState, token_input: u256) -> u256 {
            assert(token_input > 0, 'Cannot swap 0 tokens');
            let caller = get_caller_address();
            let contract_address = get_contract_address();

            let token_contract = self.token.read();
            assert(token_contract.balance_of(caller) >= token_input, 'Insufficient token balance');
            assert(
                token_contract.allowance(caller, contract_address) >= token_input,
                'Insufficient allowance',
            );

            let token_reserve = token_contract.balance_of(contract_address);
            let strk_output = self
                .price(
                    token_input, token_reserve, self.strk_token.read().balance_of(contract_address),
                );

            assert(
                token_contract.transfer_from(caller, contract_address, token_input),
                'Failed to transfer tokens',
            );
            assert(
                self.strk_token.read().transfer(caller, strk_output),
                'Failed to transfer STRK to user',
            );

            self
                .emit(
                    TokenToStrkSwap {
                        swapper: caller, tokens_input: token_input, strk_output: strk_output,
                    },
                );

            strk_output
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
            assert(strk_amount > 0, 'Deposit must greater than 0');
            let caller = get_caller_address();
            let contract_address = get_contract_address();

            let strk_reserve = self.strk_token.read().balance_of(contract_address) - strk_amount;
            let token_reserve = self.token.read().balance_of(contract_address);
            let token_amount = (strk_amount * token_reserve / strk_reserve) + 1;
            let liquidity_minted = strk_amount * self.total_liquidity.read() / strk_reserve;

            self.liquidity.write(caller, self.liquidity.read(caller) + liquidity_minted);
            self.total_liquidity.write(self.total_liquidity.read() + liquidity_minted);
            assert(
                self.strk_token.read().transfer_from(caller, contract_address, strk_amount),
                'strk transfer failed',
            );
            assert(
                self.token.read().transfer_from(caller, contract_address, token_amount),
                'token transfer failed',
            );

            self
                .emit(
                    LiquidityProvided {
                        liquidity_provider: caller,
                        liquidity_minted,
                        strk_input: strk_amount,
                        tokens_input: token_amount,
                    },
                );

            liquidity_minted
        }

        // Todo Checkpoint 5:  Implement your function getDepositTokenAmount here.
        /// get deposit token amount when deposit strk_amount STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_amount: The amount of STRK to deposit.
        ///
        /// Returns:
        ///     u256: The token_amount of deposit.
        fn getDepositTokenAmount(self: @ContractState, strk_amount: u256) -> u256 {
            assert(strk_amount > 0, 'Deposit must greater than 0');
            let contract_address = get_contract_address();

            let strk_reserve = self.strk_token.read().balance_of(contract_address) - strk_amount;
            let token_reserve = self.token.read().balance_of(contract_address);
            let token_amount = (strk_amount * token_reserve / strk_reserve) + 1;
            token_amount
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
            let caller = get_caller_address();
            let caller_liquidity = self.liquidity.read(caller);
            assert(caller_liquidity >= amount, 'Insufficient liquidity');

            let contract_address = get_contract_address();
            let strk_balance = self.strk_token.read().balance_of(contract_address);
            let token_balance = self.token.read().balance_of(contract_address);

            let strk_withdrawn = amount * strk_balance / self.total_liquidity.read();
            let token_amount = amount * token_balance / self.total_liquidity.read();

            self.liquidity.write(caller, caller_liquidity - amount);
            self.total_liquidity.write(self.total_liquidity.read() - amount);

            assert(self.strk_token.read().transfer(caller, strk_withdrawn), 'strk transfer failed');
            assert(self.token.read().transfer(caller, token_amount), 'Token transfer failed');

            self
                .emit(
                    LiquidityRemoved {
                        liquidity_remover: caller,
                        liquidity_withdrawn: amount,
                        tokens_output: token_amount,
                        strk_output: strk_withdrawn,
                    },
                );

            (strk_withdrawn, token_amount)
        }
    }
}
