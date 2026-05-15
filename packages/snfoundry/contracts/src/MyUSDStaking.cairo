#[starknet::interface]
pub trait IMyUSDEngine<TContractState> {
    fn borrow_rate(self: @TContractState) -> u256;
    fn set_borrow_rate(ref self: TContractState, new_rate: u256);
}

#[starknet::interface]
pub trait IMyUSDStaking<TContractState> {
    fn stake(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState);
    fn set_savings_rate(ref self: TContractState, new_rate: u256);
    fn savings_rate(self: @TContractState) -> u256;
    fn set_engine(ref self: TContractState, new_engine: starknet::ContractAddress);
    fn total_shares(self: @TContractState) -> u256;
    fn get_balance(self: @TContractState, user: starknet::ContractAddress) -> u256;
    fn get_shares_value(self: @TContractState, shares: u256) -> u256;
    fn get_user_shares(self: @TContractState, user: starknet::ContractAddress) -> u256;
}

#[starknet::contract]
pub mod MyUSDStaking {
    use core::num::traits::Zero;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin_interfaces::token::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use super::{IMyUSDEngineDispatcher, IMyUSDEngineDispatcherTrait, IMyUSDStaking};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancy, event: ReentrancyEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl ReentrancyInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyEvent: ReentrancyGuardComponent::Event,
        Staked: Staked,
        Withdrawn: Withdrawn,
        SavingsRateUpdated: SavingsRateUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct Staked {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
        #[key]
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdrawn {
        #[key]
        user: ContractAddress,
        #[key]
        amount: u256,
        #[key]
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct SavingsRateUpdated {
        #[key]
        new_rate: u256,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancy: ReentrancyGuardComponent::Storage,
        myusd: ContractAddress,
        engine: ContractAddress,
        i_rate_controller: ContractAddress,
        // Total shares in the pool
        total_shares: u256,
        // Exchange rate between shares and MyUSD (1e18 precision)
        exchange_rate: u256,
        // Last update timestamp
        last_update_time: u64,
        // Interest rate in basis points (1% = 100)
        savings_rate: u256,
        // User's share balance
        user_shares: Map<ContractAddress, u256>,
    }

    // Custom errors
    mod Errors {
        pub const INVALID_AMOUNT: felt252 = 'Staking: Invalid amount';
        pub const INSUFFICIENT_BALANCE: felt252 = 'Staking: Insufficient balance';
        pub const TRANSFER_FAILED: felt252 = 'Staking: Transfer failed';
        pub const INVALID_SAVINGS_RATE: felt252 = 'Staking: Invalid savings rate';
        pub const ENGINE_NOT_SET: felt252 = 'Staking: Engine not set';
        pub const NOT_RATE_CONTROLLER: felt252 = 'Staking: Not rate controller';
    }

    // Constants
    const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
    const SECONDS_PER_YEAR: u256 = 31536000; // 365 * 24 * 60 * 60

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        myusd: ContractAddress,
        rate_controller: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.myusd.write(myusd);
        self.i_rate_controller.write(rate_controller);
        self.exchange_rate.write(PRECISION); // 1:1 initially
        self.last_update_time.write(get_block_timestamp());
    }

    #[abi(embed_v0)]
    impl MyUSDStakingImpl of IMyUSDStaking<ContractState> {
        /// Set the savings rate for the staking contract
        /// Only callable by rate controller
        fn set_savings_rate(ref self: ContractState, new_rate: u256) {
            let caller = get_caller_address();
            let rate_controller = self.i_rate_controller.read();
            assert(caller == rate_controller, Errors::NOT_RATE_CONTROLLER);

            let engine_dispatcher = IMyUSDEngineDispatcher { contract_address: self.engine.read() };
            let borrow_rate = engine_dispatcher.borrow_rate();
            assert(new_rate <= borrow_rate, Errors::INVALID_SAVINGS_RATE);

            self._accrue_interest();
            self.savings_rate.write(new_rate);
            self.emit(SavingsRateUpdated { new_rate });
        }

        /// Stake MyUSD tokens to earn interest
        fn stake(ref self: ContractState, amount: u256) {
            self.reentrancy.start();

            assert(amount > 0, Errors::INVALID_AMOUNT);

            // Calculate shares based on current exchange rate
            let shares = (amount * PRECISION) / self._get_current_exchange_rate();

            // Update user's shares and total shares
            let caller = get_caller_address();
            let current_user_shares = self.user_shares.read(caller);
            self.user_shares.write(caller, current_user_shares + shares);
            self.total_shares.write(self.total_shares.read() + shares);

            let myusd_dispatcher = IERC20Dispatcher { contract_address: self.myusd.read() };

            // Check balance
            let caller_balance = myusd_dispatcher.balance_of(caller);
            assert(caller_balance >= amount, Errors::INSUFFICIENT_BALANCE);

            // Check allowance
            let allowance = myusd_dispatcher.allowance(caller, get_contract_address());
            assert(allowance >= amount, Errors::INSUFFICIENT_BALANCE);

            // Transfer tokens to contract
            let success = myusd_dispatcher.transfer_from(caller, get_contract_address(), amount);
            assert(success, Errors::TRANSFER_FAILED);

            self.emit(Staked { user: caller, amount, shares });

            self.reentrancy.end();
        }

        /// Withdraw all staked tokens plus accrued interest
        fn withdraw(ref self: ContractState) {
            self.reentrancy.start();

            let engine = self.engine.read();
            assert(!engine.is_zero(), Errors::ENGINE_NOT_SET);

            let caller = get_caller_address();
            let share_amount = self.user_shares.read(caller);
            assert(share_amount > 0, Errors::INSUFFICIENT_BALANCE);

            // Calculate MyUSD amount based on current exchange rate
            let amount = self.get_shares_value(share_amount);

            // Update user's shares
            self.user_shares.write(caller, 0);

            // Transfer tokens to user
            let myusd_dispatcher = IERC20Dispatcher { contract_address: self.myusd.read() };
            let success = myusd_dispatcher.transfer(caller, amount);
            assert(success, Errors::TRANSFER_FAILED);

            // Now update total shares since MyUSD uses this to determine this contract's token
            // balance
            self.total_shares.write(self.total_shares.read() - share_amount);

            self.emit(Withdrawn { user: caller, amount, shares: share_amount });

            self.reentrancy.end();
        }

        /// Get the MyUSD balance for a user (includes accrued interest)
        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            let user_shares = self.user_shares.read(user);
            if user_shares == 0 {
                return 0;
            }

            self.get_shares_value(user_shares)
        }

        fn savings_rate(self: @ContractState) -> u256 {
            self.savings_rate.read()
        }

        fn set_engine(ref self: ContractState, new_engine: ContractAddress) {
            self.ownable.assert_only_owner();
            self.engine.write(new_engine);
        }

        /// Get total shares in the pool
        fn total_shares(self: @ContractState) -> u256 {
            self.total_shares.read()
        }

        /// Convert shares to MyUSD value
        fn get_shares_value(self: @ContractState, shares: u256) -> u256 {
            (shares * self._get_current_exchange_rate()) / PRECISION
        }

        fn get_user_shares(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_shares.read(user)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Accrue interest and update exchange rate
        fn _accrue_interest(ref self: ContractState) {
            let total_shares = self.total_shares.read();
            if total_shares == 0 {
                self.last_update_time.write(get_block_timestamp());
                return;
            }

            let time_elapsed = get_block_timestamp() - self.last_update_time.read();
            if time_elapsed == 0 {
                return;
            }

            // Calculate interest based on total shares and exchange rate
            let total_value = self.get_shares_value(total_shares);
            // FIXED: Divide by 10000, not multiply!
            let interest = (total_value * self.savings_rate.read() * time_elapsed.into())
                / (SECONDS_PER_YEAR * 10000);

            if interest > 0 {
                // Update exchange rate to reflect new value
                let current_exchange_rate = self.exchange_rate.read();
                self
                    .exchange_rate
                    .write(current_exchange_rate + (interest * PRECISION) / total_shares);
            }

            self.last_update_time.write(get_block_timestamp());
        }

        /// Get current exchange rate (includes pending interest)
        fn _get_current_exchange_rate(self: @ContractState) -> u256 {
            let total_shares = self.total_shares.read();
            if total_shares == 0 {
                return self.exchange_rate.read();
            }

            let time_elapsed = get_block_timestamp() - self.last_update_time.read();
            if time_elapsed == 0 {
                return self.exchange_rate.read();
            }

            let total_value = (total_shares * self.exchange_rate.read()) / PRECISION;
            let interest = (total_value * self.savings_rate.read() * time_elapsed.into())
                / (SECONDS_PER_YEAR * 10000);

            if interest == 0 {
                return self.exchange_rate.read();
            }

            self.exchange_rate.read() + (interest * PRECISION) / total_shares
        }
    }
}
