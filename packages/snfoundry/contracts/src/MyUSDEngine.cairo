#[starknet::interface]
pub trait IOracle<TContractState> {
    fn get_strk_myusd_price(self: @TContractState) -> u256;
    fn get_strk_usd_price(self: @TContractState) -> u256;
}

#[starknet::interface]
pub trait IMyUSDStaking<TContractState> {
    fn savings_rate(self: @TContractState) -> u256;
}

#[starknet::interface]
pub trait IMyUSDEngine<TContractState> {
    // Collateral management
    fn add_collateral(ref self: TContractState, strk_amount: u256);
    fn withdraw_collateral(ref self: TContractState, amount: u256);
    fn calculate_collateral_value(self: @TContractState, user: starknet::ContractAddress) -> u256;

    // Debt management
    fn mint_myusd(ref self: TContractState, amount: u256);
    fn repay_up_to(ref self: TContractState, amount: u256);

    // Interest and rates
    fn set_borrow_rate(ref self: TContractState, new_rate: u256);
    fn borrow_rate(self: @TContractState) -> u256;

    // Position health
    fn get_current_debt_value(self: @TContractState, user: starknet::ContractAddress) -> u256;
    fn calculate_position_ratio(self: @TContractState, user: starknet::ContractAddress) -> u256;
    fn is_liquidatable(self: @TContractState, user: starknet::ContractAddress) -> bool;

    // Liquidation
    fn liquidate(ref self: TContractState, user: starknet::ContractAddress);

    // View functions
    fn get_user_collateral(self: @TContractState, user: starknet::ContractAddress) -> u256;
    fn get_user_debt_shares(self: @TContractState, user: starknet::ContractAddress) -> u256;
    fn get_borrow_rate(self: @TContractState) -> u256;
}

#[starknet::contract]
pub mod MyUSDEngine {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::IERC20Dispatcher;
    use starknet::storage::{
        Map, StorageMapReadAccess, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use crate::MyUSD::IMyUSDDispatcher;
    use super::{IMyUSDEngine, IMyUSDStakingDispatcher, IOracleDispatcher};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // STRK contract address on Starknet
    pub const FELT_STRK_CONTRACT: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        CollateralAdded: CollateralAdded,
        CollateralWithdrawn: CollateralWithdrawn,
        BorrowRateUpdated: BorrowRateUpdated,
        DebtSharesMinted: DebtSharesMinted,
        DebtSharesBurned: DebtSharesBurned,
        Liquidation: Liquidation,
    }

    #[derive(Drop, starknet::Event)]
    struct CollateralAdded {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
        #[key]
        price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct CollateralWithdrawn {
        #[key]
        withdrawer: ContractAddress,
        #[key]
        amount: u256,
        #[key]
        price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct BorrowRateUpdated {
        #[key]
        new_rate: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct DebtSharesMinted {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
        #[key]
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct DebtSharesBurned {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
        #[key]
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Liquidation {
        #[key]
        user: ContractAddress,
        #[key]
        liquidator: ContractAddress,
        #[key]
        amount_for_liquidator: u256,
        #[key]
        liquidated_user_debt: u256,
        #[key]
        price: u256,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // Contract addresses
        i_myusd: ContractAddress,
        i_oracle: ContractAddress,
        i_staking: ContractAddress,
        i_rate_controller: ContractAddress,
        // Core state variables
        borrow_rate: u256, // Annual interest rate for borrowers in basis points (1% = 100)
        total_debt_shares: u256,
        debt_exchange_rate: u256, // Exchange rate between debt shares and MyUSD (1e18 precision)
        last_update_time: u64,
        // User mappings
        s_user_collateral: Map<ContractAddress, u256>,
        s_user_debt_shares: Map<ContractAddress, u256>,
    }

    // Custom errors
    mod Errors {
        pub const INVALID_AMOUNT: felt252 = 'Engine: Invalid amount';
        pub const UNSAFE_POSITION_RATIO: felt252 = 'Engine: Unsafe position ratio';
        pub const NOT_LIQUIDATABLE: felt252 = 'Engine: Not liquidatable';
        pub const INVALID_BORROW_RATE: felt252 = 'Engine: Invalid borrow rate';
        pub const NOT_RATE_CONTROLLER: felt252 = 'Engine: Not rate controller';
        pub const INSUFFICIENT_COLLATERAL: felt252 = 'Engine: Insufficient collateral';
        pub const TRANSFER_FAILED: felt252 = 'Engine: Transfer failed';
    }

    // Constants
    const COLLATERAL_RATIO: u256 = 150; // 150% collateralization required
    const LIQUIDATOR_REWARD: u256 = 10; // 10% reward for liquidators
    const SECONDS_PER_YEAR: u256 = 365 * 24 * 60 * 60; // 365 days in seconds
    const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        oracle: ContractAddress,
        myusd_address: ContractAddress,
        staking_address: ContractAddress,
        rate_controller: ContractAddress,
    ) {
        // Initialize Ownable
        self.ownable.initializer(owner);

        // Set contract addresses
        self.i_oracle.write(oracle);
        self.i_myusd.write(myusd_address);
        self.i_staking.write(staking_address);
        self.i_rate_controller.write(rate_controller);

        // Initialize state
        self.last_update_time.write(get_block_timestamp());
        self.debt_exchange_rate.write(PRECISION); // 1:1 initially
    }

    #[abi(embed_v0)]
    impl MyUSDEngineImpl of IMyUSDEngine<ContractState> {
        // Checkpoint 2: Depositing Collateral & Understanding Value
        fn add_collateral(
            ref self: ContractState, strk_amount: u256,
        ) { // TODO: Implement addCollateral functionality
        // - Validate strk_amount > 0
        // - Transfer STRK from caller to contract
        // - Update user's collateral balance
        // - Emit CollateralAdded event
        }

        fn calculate_collateral_value(self: @ContractState, user: ContractAddress) -> u256 {
            // TODO: Implement calculateCollateralValue functionality
            // - Get user's STRK collateral amount
            // - Get current STRK/MyUSD price from oracle
            // - Calculate and return collateral value in MyUSD
            0
        }

        // Checkpoint 3: Interest Calculation System
        fn get_current_debt_value(self: @ContractState, user: ContractAddress) -> u256 {
            // TODO: Implement getCurrentDebtValue functionality
            // - Get user's debt shares
            // - Get current exchange rate
            // - Calculate and return current debt value
            0
        }

        fn calculate_position_ratio(self: @ContractState, user: ContractAddress) -> u256 {
            // TODO: Implement calculatePositionRatio functionality
            // - Get user's collateral value
            // - Get user's current debt value
            // - Calculate and return position ratio
            0
        }

        fn mint_myusd(
            ref self: ContractState, amount: u256,
        ) { // TODO: Implement mintMyUSD functionality
        // - Validate amount > 0
        // - Calculate shares to mint
        // - Update user's debt shares
        // - Update total debt shares
        // - Validate position is safe
        // - Mint MyUSD tokens to user
        // - Emit DebtSharesMinted event
        }

        // Checkpoint 4: Minting MyUSD & Position Health
        fn set_borrow_rate(
            ref self: ContractState, new_rate: u256,
        ) { // TODO: Implement setBorrowRate functionality
        // - Check caller is rate controller
        // - Validate new rate >= savings rate
        // - Accrue interest before updating
        // - Update borrow rate
        // - Emit BorrowRateUpdated event
        }

        // Checkpoint 5: Accruing Interest & Managing Borrow Rates
        fn repay_up_to(
            ref self: ContractState, amount: u256,
        ) { // TODO: Implement repayUpTo functionality
        // - Calculate shares to burn
        // - Cap at user's actual debt
        // - Check user has enough MyUSD balance
        // - Check allowance
        // - Update user's debt shares
        // - Update total debt shares
        // - Transfer MyUSD from user to contract
        // - Emit DebtSharesBurned event
        }

        fn withdraw_collateral(
            ref self: ContractState, amount: u256,
        ) { // TODO: Implement withdrawCollateral functionality
        // - Validate amount > 0
        // - Check user has enough collateral
        // - Temporarily reduce collateral
        // - Validate position is still safe
        // - Transfer STRK to user
        // - Emit CollateralWithdrawn event
        }

        // Checkpoint 6: Repaying Debt & Withdrawing Collateral
        fn is_liquidatable(self: @ContractState, user: ContractAddress) -> bool {
            // TODO: Implement isLiquidatable functionality
            // - Calculate user's position ratio
            // - Return true if ratio < collateral ratio
            false
        }

        fn liquidate(
            ref self: ContractState, user: ContractAddress,
        ) { // TODO: Implement liquidate functionality
        // - Check user is liquidatable
        // - Get user's debt value
        // - Check liquidator has enough MyUSD
        // - Check allowance
        // - Transfer MyUSD from liquidator
        // - Clear user's debt
        // - Calculate liquidator reward
        // - Transfer STRK to liquidator
        // - Emit Liquidation event
        }

        // View functions
        fn get_user_collateral(self: @ContractState, user: ContractAddress) -> u256 {
            self.s_user_collateral.read(user)
        }

        fn get_user_debt_shares(self: @ContractState, user: ContractAddress) -> u256 {
            self.s_user_debt_shares.read(user)
        }

        fn get_borrow_rate(self: @ContractState) -> u256 {
            self.borrow_rate.read()
        }

        fn borrow_rate(self: @ContractState) -> u256 {
            self.borrow_rate.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _get_current_exchange_rate(self: @ContractState) -> u256 {
            // TODO: Implement _getCurrentExchangeRate functionality
            // - Calculate time elapsed since last update
            // - Calculate interest accrued
            // - Return new exchange rate
            self.debt_exchange_rate.read()
        }

        fn _accrue_interest(
            ref self: ContractState,
        ) { // TODO: Implement _accrueInterest functionality
        // - Get current exchange rate
        // - Update debt exchange rate
        // - Update last update time
        }

        fn _get_myusd_to_shares(self: @ContractState, amount: u256) -> u256 {
            // TODO: Implement _getMyUSDToShares functionality
            // - Get current exchange rate
            // - Calculate shares for given amount
            amount
        }

        fn _validate_position(
            self: @ContractState, user: ContractAddress,
        ) { // TODO: Implement _validatePosition functionality
        // - Calculate position ratio
        // - Panic if ratio < collateral ratio
        }

        fn _get_oracle(self: @ContractState) -> IOracleDispatcher {
            IOracleDispatcher { contract_address: self.i_oracle.read() }
        }

        fn _get_staking(self: @ContractState) -> IMyUSDStakingDispatcher {
            IMyUSDStakingDispatcher { contract_address: self.i_staking.read() }
        }

        fn _get_myusd(self: @ContractState) -> IMyUSDDispatcher {
            IMyUSDDispatcher { contract_address: self.i_myusd.read() }
        }

        fn _get_strk(self: @ContractState) -> IERC20Dispatcher {
            let strk_contract_address: ContractAddress = FELT_STRK_CONTRACT.try_into().unwrap();
            IERC20Dispatcher { contract_address: strk_contract_address }
        }

        fn _only_rate_controller(self: @ContractState) {
            let caller = get_caller_address();
            let rate_controller = self.i_rate_controller.read();
            assert(caller == rate_controller, Errors::NOT_RATE_CONTROLLER);
        }
    }
}
