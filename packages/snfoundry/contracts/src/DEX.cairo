use starknet::ContractAddress;

#[starknet::interface]
pub trait IDEX<TContractState> {
    fn init(ref self: TContractState, tokens: u256, strk_amount: u256) -> u256;
    fn price(self: @TContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256;
    fn current_price(self: @TContractState) -> u256;
    fn calculate_x_input(
        self: @TContractState, y_output: u256, x_reserves: u256, y_reserves: u256,
    ) -> u256;
    fn swap(ref self: TContractState, input_amount: u256, strk_amount: u256) -> u256;
    fn deposit(ref self: TContractState, strk_amount: u256) -> u256;
    fn withdraw(ref self: TContractState, amount: u256) -> (u256, u256);

    // View functions
    fn total_liquidity(self: @TContractState) -> u256;
    fn liquidity(self: @TContractState, user: ContractAddress) -> u256;
}

#[starknet::contract]
pub mod DEX {
    use openzeppelin_interfaces::token::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use super::IDEX;

    pub const FELT_STRK_CONTRACT: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Swap: Swap,
        PriceUpdated: PriceUpdated,
        LiquidityProvided: LiquidityProvided,
        LiquidityRemoved: LiquidityRemoved,
    }

    #[derive(Drop, starknet::Event)]
    struct Swap {
        #[key]
        swapper: ContractAddress,
        #[key]
        input_token: ContractAddress,
        #[key]
        input_amount: u256,
        #[key]
        output_token: ContractAddress,
        #[key]
        output_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PriceUpdated {
        #[key]
        price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct LiquidityProvided {
        #[key]
        liquidity_provider: ContractAddress,
        #[key]
        liquidity_minted: u256,
        #[key]
        strk_input: u256,
        #[key]
        tokens_input: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct LiquidityRemoved {
        #[key]
        liquidity_remover: ContractAddress,
        #[key]
        liquidity_withdrawn: u256,
        #[key]
        tokens_output: u256,
        #[key]
        strk_output: u256,
    }

    #[storage]
    struct Storage {
        token: ContractAddress, // MyUSD token address
        total_liquidity: u256,
        liquidity: Map<ContractAddress, u256>,
    }

    // Constants
    const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

    // Custom errors
    mod Errors {
        pub const ALREADY_HAS_LIQUIDITY: felt252 = 'DEX: init - already has liq';
        pub const TRANSFER_FAILED: felt252 = 'DEX: transfer failed';
        pub const CANNOT_SWAP_ZERO_STRK: felt252 = 'cannot swap 0 STRK';
        pub const CANNOT_SWAP_ZERO_TOKENS: felt252 = 'cannot swap 0 tokens';
        pub const INSUFFICIENT_TOKEN_BALANCE: felt252 = 'insufficient token balance';
        pub const INSUFFICIENT_ALLOWANCE: felt252 = 'insufficient allowance';
        pub const MUST_SEND_VALUE: felt252 = 'Must send value when deposit';
        pub const INSUFFICIENT_LIQUIDITY: felt252 = 'sender lacks liquidity';
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_addr: ContractAddress) {
        self.token.write(token_addr);
        self.total_liquidity.write(0);
    }

    #[abi(embed_v0)]
    impl DEXImpl of IDEX<ContractState> {
        /// Initialize the DEX with initial liquidity
        /// @param tokens: Amount of MyUSD tokens to deposit
        /// @param strk_amount: Amount of STRK to deposit
        fn init(ref self: ContractState, tokens: u256, strk_amount: u256) -> u256 {
            assert(self.total_liquidity.read() == 0, Errors::ALREADY_HAS_LIQUIDITY);

            let caller = get_caller_address();
            let contract_addr = get_contract_address();

            // Transfer STRK from caller to contract
            let strk_dispatcher = self._get_strk_dispatcher();
            let success = strk_dispatcher.transfer_from(caller, contract_addr, strk_amount);
            assert(success, Errors::TRANSFER_FAILED);

            // Set total liquidity to STRK amount
            self.total_liquidity.write(strk_amount);
            self.liquidity.write(caller, strk_amount);

            // Transfer MyUSD tokens from caller to contract
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let success = token_dispatcher.transfer_from(caller, contract_addr, tokens);
            assert(success, Errors::TRANSFER_FAILED);

            self.emit(PriceUpdated { price: self.current_price() });
            self.total_liquidity.read()
        }

        /// Calculate output amount given input and reserves (constant product formula)
        fn price(self: @ContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256 {
            let numerator = x_input * y_reserves;
            let denominator = x_reserves + x_input;
            numerator / denominator
        }

        /// Get current price of STRK in MyUSD
        fn current_price(self: @ContractState) -> u256 {
            let strk_balance = self._get_strk_balance_internal();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_balance = token_dispatcher.balance_of(get_contract_address());

            // Use PRECISION (1e18) as input
            self.price(PRECISION, strk_balance, token_balance)
        }

        /// Calculate required input given desired output
        fn calculate_x_input(
            self: @ContractState, y_output: u256, x_reserves: u256, y_reserves: u256,
        ) -> u256 {
            let numerator = y_output * x_reserves;
            let denominator = y_reserves - y_output;
            (numerator / denominator) + 1
        }

        /// Swap STRK for MyUSD or MyUSD for STRK
        /// @param input_amount: Amount to swap
        /// @param strk_amount: If > 0, swaps STRK to token; if 0, swaps token to STRK
        fn swap(ref self: ContractState, input_amount: u256, strk_amount: u256) -> u256 {
            let output_amount = if strk_amount > 0 && input_amount == strk_amount {
                // STRK to Token swap
                self._strk_to_token(strk_amount)
            } else {
                // Token to STRK swap
                self._token_to_strk(input_amount)
            };

            self.emit(PriceUpdated { price: self.current_price() });
            output_amount
        }

        /// Add liquidity to the pool
        /// @param strk_amount: Amount of STRK to deposit
        fn deposit(ref self: ContractState, strk_amount: u256) -> u256 {
            assert(strk_amount > 0, Errors::MUST_SEND_VALUE);

            let caller = get_caller_address();
            let contract_addr = get_contract_address();

            // Get reserves (subtract strk_amount)
            let strk_reserve = self._get_strk_balance_internal();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_reserve = token_dispatcher.balance_of(contract_addr);

            // Calculate required token deposit
            let token_deposit = ((strk_amount * token_reserve) / strk_reserve) + 1;

            // Validate balances and allowances
            assert(
                token_dispatcher.balance_of(caller) >= token_deposit,
                Errors::INSUFFICIENT_TOKEN_BALANCE,
            );
            assert(
                token_dispatcher.allowance(caller, contract_addr) >= token_deposit,
                Errors::INSUFFICIENT_ALLOWANCE,
            );

            // Calculate liquidity to mint
            let liquidity_minted = (strk_amount * self.total_liquidity.read()) / strk_reserve;
            let current_liquidity = self.liquidity.read(caller);
            self.liquidity.write(caller, current_liquidity + liquidity_minted);
            self.total_liquidity.write(self.total_liquidity.read() + liquidity_minted);

            // Transfer STRK from caller to contract
            let strk_dispatcher = self._get_strk_dispatcher();
            let success = strk_dispatcher.transfer_from(caller, contract_addr, strk_amount);
            assert(success, Errors::TRANSFER_FAILED);

            // Transfer MyUSD tokens from caller to contract
            let success = token_dispatcher.transfer_from(caller, contract_addr, token_deposit);
            assert(success, Errors::TRANSFER_FAILED);

            self
                .emit(
                    LiquidityProvided {
                        liquidity_provider: caller,
                        liquidity_minted,
                        strk_input: strk_amount,
                        tokens_input: token_deposit,
                    },
                );

            token_deposit
        }

        /// Remove liquidity from the pool
        fn withdraw(ref self: ContractState, amount: u256) -> (u256, u256) {
            let caller = get_caller_address();
            let user_liquidity = self.liquidity.read(caller);
            assert(user_liquidity >= amount, Errors::INSUFFICIENT_LIQUIDITY);

            let strk_reserve = self._get_strk_balance_internal();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_reserve = token_dispatcher.balance_of(get_contract_address());

            // Calculate amounts to withdraw
            let strk_withdrawn = (amount * strk_reserve) / self.total_liquidity.read();
            let token_amount = (amount * token_reserve) / self.total_liquidity.read();

            // Update state
            self.liquidity.write(caller, user_liquidity - amount);
            self.total_liquidity.write(self.total_liquidity.read() - amount);

            // Transfer STRK to caller
            let strk_dispatcher = self._get_strk_dispatcher();
            let success = strk_dispatcher.transfer(caller, strk_withdrawn);
            assert(success, Errors::TRANSFER_FAILED);

            // Transfer MyUSD tokens to caller
            let success = token_dispatcher.transfer(caller, token_amount);
            assert(success, Errors::TRANSFER_FAILED);

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

        fn total_liquidity(self: @ContractState) -> u256 {
            self.total_liquidity.read()
        }

        fn liquidity(self: @ContractState, user: ContractAddress) -> u256 {
            self.liquidity.read(user)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Swap STRK for MyUSD tokens
        fn _strk_to_token(ref self: ContractState, strk_amount: u256) -> u256 {
            assert(strk_amount > 0, Errors::CANNOT_SWAP_ZERO_STRK);

            let caller = get_caller_address();
            let contract_addr = get_contract_address();

            // Get reserves (subtract strk_amount)
            let strk_reserve = self._get_strk_balance_internal();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_reserve = token_dispatcher.balance_of(contract_addr);

            // Calculate token output
            let token_output = self.price(strk_amount, strk_reserve, token_reserve);

            // Transfer STRK from caller to contract
            let strk_dispatcher = self._get_strk_dispatcher();
            let success = strk_dispatcher.transfer_from(caller, contract_addr, strk_amount);
            assert(success, Errors::TRANSFER_FAILED);

            // Transfer MyUSD tokens to caller
            let success = token_dispatcher.transfer(caller, token_output);
            assert(success, Errors::TRANSFER_FAILED);

            // Use address(0) equivalent for STRK
            let zero_address: ContractAddress = 0.try_into().unwrap();

            self
                .emit(
                    Swap {
                        swapper: caller,
                        input_token: zero_address,
                        input_amount: strk_amount,
                        output_token: self.token.read(),
                        output_amount: token_output,
                    },
                );

            token_output
        }

        /// Swap MyUSD tokens for STRK
        fn _token_to_strk(ref self: ContractState, token_input: u256) -> u256 {
            assert(token_input > 0, Errors::CANNOT_SWAP_ZERO_TOKENS);

            let caller = get_caller_address();
            let contract_addr = get_contract_address();

            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };

            // Validate token balance and allowance
            assert(
                token_dispatcher.balance_of(caller) >= token_input,
                Errors::INSUFFICIENT_TOKEN_BALANCE,
            );
            assert(
                token_dispatcher.allowance(caller, contract_addr) >= token_input,
                Errors::INSUFFICIENT_ALLOWANCE,
            );

            // Get reserves
            let token_reserve = token_dispatcher.balance_of(contract_addr);
            let strk_reserve = self._get_strk_balance_internal();

            // Calculate STRK output
            let strk_output = self.price(token_input, token_reserve, strk_reserve);

            // Transfer MyUSD tokens from caller to contract
            let success = token_dispatcher.transfer_from(caller, contract_addr, token_input);
            assert(success, Errors::TRANSFER_FAILED);

            // Transfer STRK to caller
            let strk_dispatcher = self._get_strk_dispatcher();
            let success = strk_dispatcher.transfer(caller, strk_output);
            assert(success, Errors::TRANSFER_FAILED);

            // Use address(0) for STRK output
            let zero_address: ContractAddress = 0.try_into().unwrap();

            self
                .emit(
                    Swap {
                        swapper: caller,
                        input_token: self.token.read(),
                        input_amount: token_input,
                        output_token: zero_address,
                        output_amount: strk_output,
                    },
                );

            strk_output
        }

        /// Get actual STRK balance from the STRK contract
        fn _get_strk_balance_internal(self: @ContractState) -> u256 {
            let strk_dispatcher = self._get_strk_dispatcher();
            strk_dispatcher.balance_of(get_contract_address())
        }

        /// Get STRK ERC20 dispatcher
        fn _get_strk_dispatcher(self: @ContractState) -> IERC20Dispatcher {
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            IERC20Dispatcher { contract_address: strk_contract_address }
        }
    }
}
