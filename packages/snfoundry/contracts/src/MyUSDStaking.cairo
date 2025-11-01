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
    fn get_balance(self: @TContractState, user: starknet::ContractAddress) -> u256;
    fn get_shares_value(self: @TContractState, shares: u256) -> u256;
}

#[starknet::contract]
pub mod MyUSDStaking {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use super::{IMyUSDEngineDispatcher, IMyUSDEngineDispatcherTrait, IMyUSDStaking};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Staked: Staked,
        Withdrawn: Withdrawn,
        SavingsRateUpdated: SavingsRateUpdated,
        Staking__InvalidAmount: Staking__InvalidAmount,
        Staking__InsufficientBalance: Staking__InsufficientBalance,
        Staking__TransferFailed: Staking__TransferFailed,
        Staking__InvalidSavingsRate: Staking__InvalidSavingsRate,
        Staking__EngineNotSet: Staking__EngineNotSet,
        Staking__NotRateController: Staking__NotRateController,
        MyUSD__InsufficientBalance: MyUSD__InsufficientBalance,
        MyUSD__InsufficientAllowance: MyUSD__InsufficientAllowance,
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

    // Error events
    #[derive(Drop, starknet::Event)]
    struct Staking__InvalidAmount {}

    #[derive(Drop, starknet::Event)]
    struct Staking__InsufficientBalance {}

    #[derive(Drop, starknet::Event)]
    struct Staking__TransferFailed {}

    #[derive(Drop, starknet::Event)]
    struct Staking__InvalidSavingsRate {}

    #[derive(Drop, starknet::Event)]
    struct Staking__EngineNotSet {}

    #[derive(Drop, starknet::Event)]
    struct Staking__NotRateController {}

    #[derive(Drop, starknet::Event)]
    struct MyUSD__InsufficientBalance {}

    #[derive(Drop, starknet::Event)]
    struct MyUSD__InsufficientAllowance {}

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
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

    // Constants
    const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
    const SECONDS_PER_YEAR: u256 = 365 * 24 * 60 * 60; // 365 days

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        myusd: ContractAddress,
        engine: ContractAddress,
        rate_controller: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.myusd.write(myusd);
        self.engine.write(engine);
        self.i_rate_controller.write(rate_controller);
        self.exchange_rate.write(PRECISION); // 1:1 initially
        self.last_update_time.write(get_block_timestamp());
    }

    #[abi(embed_v0)]
    impl MyUSDStakingImpl of IMyUSDStaking<ContractState> {
        // Set the savings rate for the staking contract
        fn set_savings_rate(ref self: ContractState, new_rate: u256) {
            let caller = get_caller_address();
            let rate_controller = self.i_rate_controller.read();
            if caller != rate_controller {
                self.emit(Staking__NotRateController {});
                return;
            }

            let engine_dispatcher = IMyUSDEngineDispatcher { contract_address: self.engine.read() };
            let borrow_rate = engine_dispatcher.borrow_rate();
            if new_rate > borrow_rate {
                self.emit(Staking__InvalidSavingsRate {});
                return;
            }

            self._accrue_interest();
            self.savings_rate.write(new_rate);
            self.emit(SavingsRateUpdated { new_rate });
        }

        fn stake(ref self: ContractState, amount: u256) {
            if amount == 0 {
                self.emit(Staking__InvalidAmount {});
                return;
            }

            // Calculate shares based on current exchange rate
            let shares = (amount * PRECISION) / self._get_current_exchange_rate();

            // Update user's shares and total shares
            let caller = get_caller_address();
            let current_user_shares = self.user_shares.read(caller);
            self.user_shares.write(caller, current_user_shares + shares);
            self.total_shares.write(self.total_shares.read() + shares);

            let myusd_dispatcher = IERC20Dispatcher { contract_address: self.myusd.read() };

            if myusd_dispatcher.balance_of(caller) < amount {
                self.emit(MyUSD__InsufficientBalance {});
                return;
            }

            if myusd_dispatcher.allowance(caller, get_contract_address()) < amount {
                self.emit(MyUSD__InsufficientAllowance {});
                return;
            }

            // Transfer tokens to contract
            myusd_dispatcher.transfer_from(caller, get_contract_address(), amount);

            self.emit(Staked { user: caller, amount, shares });
        }

        fn withdraw(ref self: ContractState) {
            let engine = self.engine.read();
            if engine == 0.try_into().unwrap() {
                self.emit(Staking__EngineNotSet {});
                return;
            }

            let caller = get_caller_address();
            let share_amount = self.user_shares.read(caller);
            if share_amount == 0 {
                self.emit(Staking__InsufficientBalance {});
                return;
            }

            // Calculate MyUSD amount based on current exchange rate
            let amount = self.get_shares_value(share_amount);

            // Update user's shares
            self.user_shares.write(caller, 0);

            // Transfer tokens to user
            let myusd_dispatcher = IERC20Dispatcher { contract_address: self.myusd.read() };
            myusd_dispatcher.transfer(caller, amount);

            // Now update total shares since MyUSD uses this to determine this contract's token
            // balance
            self.total_shares.write(self.total_shares.read() - share_amount);

            self.emit(Withdrawn { user: caller, amount, shares: share_amount });
        }

        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            let user_shares = self.user_shares.read(user);
            if user_shares == 0 {
                return 0;
            }

            self.get_shares_value(user_shares)
        }

        fn get_shares_value(self: @ContractState, shares: u256) -> u256 {
            (shares * self._get_current_exchange_rate()) / PRECISION
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
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
            let interest = (total_value * self.savings_rate.read() * time_elapsed.into())
                / SECONDS_PER_YEAR
                * 10000;

            if interest > 0 {
                // Update exchange rate to reflect new value
                let current_exchange_rate = self.exchange_rate.read();
                self
                    .exchange_rate
                    .write(current_exchange_rate + interest * PRECISION / total_shares);
            }

            self.last_update_time.write(get_block_timestamp());
        }

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
