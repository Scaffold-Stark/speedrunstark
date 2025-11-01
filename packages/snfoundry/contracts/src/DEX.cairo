use starknet::ContractAddress;

#[starknet::interface]
pub trait IDEX<TContractState> {
    fn init(ref self: TContractState, tokens: u256, strk_amount: u256) -> u256;
    fn price(self: @TContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256;
    fn current_price(self: @TContractState) -> u256;
    fn calculate_x_input(
        self: @TContractState, y_output: u256, x_reserves: u256, y_reserves: u256,
    ) -> u256;
    fn swap(ref self: TContractState, input_amount: u256, strk_amount: Option<u256>) -> u256;
    fn deposit(ref self: TContractState, strk_amount: u256) -> u256;
    fn withdraw(ref self: TContractState, amount: u256) -> (u256, u256);

    // View functions
    fn total_liquidity(self: @TContractState) -> u256;
    fn liquidity(self: @TContractState, user: ContractAddress) -> u256;
}

#[starknet::contract]
pub mod DEX {
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
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
        strk_balance: u256,
    }

    // Constants
    const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

    #[constructor]
    fn constructor(ref self: ContractState, token_addr: ContractAddress) {
        self.token.write(token_addr);
        self.total_liquidity.write(0);
        self.strk_balance.write(0);
    }

    #[abi(embed_v0)]
    impl DEXImpl of IDEX<ContractState> {
        fn init(ref self: ContractState, tokens: u256, strk_amount: u256) -> u256 {
            assert!(self.total_liquidity.read() == 0, "DEX: init - already has liquidity");
            assert!(strk_amount > 0, "DEX: init - must provide STRK amount");

            // Transfer STRK from caller to contract
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher
                .transfer_from(get_caller_address(), get_contract_address(), strk_amount);

            // Set total liquidity to STRK amount
            self.total_liquidity.write(strk_amount);
            self.liquidity.write(get_caller_address(), strk_amount);
            self.strk_balance.write(strk_amount);

            // Transfer MyUSD tokens from caller to contract
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            token_dispatcher.transfer_from(get_caller_address(), get_contract_address(), tokens);

            self.emit(PriceUpdated { price: self.current_price() });
            self.total_liquidity.read()
        }

        fn price(self: @ContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256 {
            let numerator = x_input * y_reserves;
            let denominator = x_reserves + x_input;
            numerator / denominator
        }

        fn current_price(self: @ContractState) -> u256 {
            let strk_balance = self.strk_balance.read();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_balance = token_dispatcher.balance_of(get_contract_address());
            self.price(PRECISION, strk_balance, token_balance)
        }

        fn calculate_x_input(
            self: @ContractState, y_output: u256, x_reserves: u256, y_reserves: u256,
        ) -> u256 {
            let numerator = y_output * x_reserves;
            let denominator = y_reserves - y_output;
            (numerator / denominator) + 1
        }

        fn swap(ref self: ContractState, input_amount: u256, strk_amount: Option<u256>) -> u256 {
            let output_amount = match strk_amount {
                Option::Some(strk_amount) => {
                    // STRK to Token swap
                    assert!(strk_amount > 0, "cannot swap 0 STRK");
                    assert!(
                        input_amount == strk_amount,
                        "input_amount must equal strk_amount for STRK swap",
                    );
                    self._strk_to_token(strk_amount)
                },
                Option::None => {
                    // Token to STRK swap
                    self._token_to_strk(input_amount)
                },
            };

            self.emit(PriceUpdated { price: self.current_price() });
            output_amount
        }

        fn deposit(ref self: ContractState, strk_amount: u256) -> u256 {
            let caller = get_caller_address();
            assert!(strk_amount > 0, "Must provide STRK amount when depositing");

            let strk_reserve = self.strk_balance.read();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_reserve = token_dispatcher.balance_of(get_contract_address());

            let token_deposit = ((strk_amount * token_reserve) / strk_reserve) + 1;

            // Check balances and allowances
            assert!(
                token_dispatcher.balance_of(caller) >= token_deposit, "insufficient token balance",
            );
            assert!(
                token_dispatcher.allowance(caller, get_contract_address()) >= token_deposit,
                "insufficient allowance",
            );

            let liquidity_minted = (strk_amount * self.total_liquidity.read()) / strk_reserve;
            let current_liquidity = self.liquidity.read(caller);
            self.liquidity.write(caller, current_liquidity + liquidity_minted);
            self.total_liquidity.write(self.total_liquidity.read() + liquidity_minted);

            // Transfer STRK from caller to contract
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher.transfer_from(caller, get_contract_address(), strk_amount);

            // Transfer MyUSD tokens
            token_dispatcher.transfer_from(caller, get_contract_address(), token_deposit);

            // Update STRK balance
            self.strk_balance.write(self.strk_balance.read() + strk_amount);

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

        fn withdraw(ref self: ContractState, amount: u256) -> (u256, u256) {
            let caller = get_caller_address();
            let user_liquidity = self.liquidity.read(caller);
            assert!(
                user_liquidity >= amount,
                "withdraw: sender does not have enough liquidity to withdraw",
            );

            let strk_reserve = self.strk_balance.read();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_reserve = token_dispatcher.balance_of(get_contract_address());

            let strk_withdrawn = (amount * strk_reserve) / self.total_liquidity.read();
            let token_amount = (amount * token_reserve) / self.total_liquidity.read();

            // Update state
            self.liquidity.write(caller, user_liquidity - amount);
            self.total_liquidity.write(self.total_liquidity.read() - amount);

            // Transfer STRK
            self._transfer_strk(caller, strk_withdrawn);

            // Transfer MyUSD tokens
            token_dispatcher.transfer(caller, token_amount);

            // Update STRK balance
            self.strk_balance.write(self.strk_balance.read() - strk_withdrawn);

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
        fn _strk_to_token(ref self: ContractState, strk_amount: u256) -> u256 {
            assert!(strk_amount > 0, "cannot swap 0 STRK");

            let strk_reserve = self.strk_balance.read();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            let token_reserve = token_dispatcher.balance_of(get_contract_address());

            let token_output = self.price(strk_amount, strk_reserve, token_reserve);

            // Transfer STRK from caller to contract
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher
                .transfer_from(get_caller_address(), get_contract_address(), strk_amount);

            // Transfer MyUSD tokens to caller
            token_dispatcher.transfer(get_caller_address(), token_output);

            // Update STRK balance
            self.strk_balance.write(self.strk_balance.read() + strk_amount);

            self
                .emit(
                    Swap {
                        swapper: get_caller_address(),
                        input_token: Self::_get_strk_address(), // STRK contract address
                        input_amount: strk_amount,
                        output_token: self.token.read(),
                        output_amount: token_output,
                    },
                );

            token_output
        }

        fn _token_to_strk(ref self: ContractState, token_input: u256) -> u256 {
            let caller = get_caller_address();
            assert!(token_input > 0, "cannot swap 0 tokens");

            let token_dispatcher = IERC20Dispatcher { contract_address: self.token.read() };
            assert!(
                token_dispatcher.balance_of(caller) >= token_input, "insufficient token balance",
            );
            assert!(
                token_dispatcher.allowance(caller, get_contract_address()) >= token_input,
                "insufficient allowance",
            );

            let token_reserve = token_dispatcher.balance_of(get_contract_address());
            let strk_output = self.price(token_input, token_reserve, self.strk_balance.read());

            // Transfer MyUSD tokens from caller to contract
            token_dispatcher.transfer_from(caller, get_contract_address(), token_input);

            // Transfer STRK to caller
            self._transfer_strk(caller, strk_output);

            // Update STRK balance
            self.strk_balance.write(self.strk_balance.read() - strk_output);

            self
                .emit(
                    Swap {
                        swapper: caller,
                        input_token: self.token.read(),
                        input_amount: token_input,
                        output_token: Self::_get_strk_address(), // STRK contract address
                        output_amount: strk_output,
                    },
                );

            strk_output
        }

        fn _get_strk_balance(self: @ContractState) -> u256 {
            // Get actual STRK balance from the STRK contract
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher.balance_of(get_contract_address())
        }


        fn _transfer_strk(self: @ContractState, to: ContractAddress, amount: u256) {
            // Transfer STRK using the STRK contract
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            let strk_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            strk_dispatcher.transfer(to, amount);
        }

        fn _get_strk_address() -> ContractAddress {
            // Return STRK contract address
            FELT_STRK_CONTRACT.try_into().unwrap()
        }
    }
}
