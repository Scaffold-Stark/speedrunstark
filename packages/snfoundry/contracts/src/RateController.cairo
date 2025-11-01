#[starknet::interface]
pub trait IMyUSDEngine<TContractState> {
    fn set_borrow_rate(ref self: TContractState, new_rate: u256);
}

#[starknet::interface]
pub trait IMyUSDStaking<TContractState> {
    fn set_savings_rate(ref self: TContractState, new_rate: u256);
}

#[starknet::interface]
pub trait IRateController<TContractState> {
    fn set_borrow_rate(ref self: TContractState, new_rate: u256);
    fn set_savings_rate(ref self: TContractState, new_rate: u256);
}

#[starknet::contract]
pub mod RateController {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::{
        IMyUSDEngineDispatcher, IMyUSDEngineDispatcherTrait, IMyUSDStakingDispatcher,
        IMyUSDStakingDispatcherTrait, IRateController,
    };

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Engine__InvalidBorrowRate: Engine__InvalidBorrowRate,
        Staking__InvalidSavingsRate: Staking__InvalidSavingsRate,
    }

    #[derive(Drop, starknet::Event)]
    struct Engine__InvalidBorrowRate {}

    #[derive(Drop, starknet::Event)]
    struct Staking__InvalidSavingsRate {}

    #[storage]
    struct Storage {
        i_myusd: ContractAddress,
        i_staking: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, myusd: ContractAddress, staking: ContractAddress) {
        self.i_myusd.write(myusd);
        self.i_staking.write(staking);
    }

    #[abi(embed_v0)]
    impl RateControllerImpl of IRateController<ContractState> {
        // Set the borrow rate for the MyUSD engine
        fn set_borrow_rate(ref self: ContractState, new_rate: u256) {
            let myusd_dispatcher = IMyUSDEngineDispatcher { contract_address: self.i_myusd.read() };

            // Try to call setBorrowRate on the engine
            // In Cairo, we don't have try-catch, so we use a different approach
            // We'll call the function and handle any potential errors
            myusd_dispatcher.set_borrow_rate(new_rate);
        }

        // Set the savings rate for the MyUSD staking contract
        fn set_savings_rate(ref self: ContractState, new_rate: u256) {
            let staking_dispatcher = IMyUSDStakingDispatcher {
                contract_address: self.i_staking.read(),
            };

            // Try to call setSavingsRate on the staking contract
            // In Cairo, we don't have try-catch, so we use a different approach
            // We'll call the function and handle any potential errors
            staking_dispatcher.set_savings_rate(new_rate);
        }
    }
}
