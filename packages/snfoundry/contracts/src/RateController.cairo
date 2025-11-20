use starknet::ContractAddress;

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
    fn set_engine_address(ref self: TContractState, engine: ContractAddress);
    fn set_staking_address(ref self: TContractState, staking: ContractAddress);
}

#[starknet::contract]
pub mod RateController {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::{
        IMyUSDEngineDispatcher, IMyUSDEngineDispatcherTrait, IMyUSDStakingDispatcher,
        IMyUSDStakingDispatcherTrait, IRateController,
    };

    #[storage]
    struct Storage {
        i_engine: ContractAddress,
        i_staking: ContractAddress,
    }

    #[abi(embed_v0)]
    impl RateControllerImpl of IRateController<ContractState> {
        /// Set the borrow rate for the MyUSD engine
        /// Note: In Cairo, if the underlying call fails, the transaction will revert
        /// with the error from the engine contract (e.g., "Engine: Invalid borrow rate")
        fn set_borrow_rate(ref self: ContractState, new_rate: u256) {
            let engine_dispatcher = IMyUSDEngineDispatcher {
                contract_address: self.i_engine.read(),
            };

            // Call set_borrow_rate on the engine
            // If this fails, the transaction reverts with the engine's error message
            engine_dispatcher.set_borrow_rate(new_rate);
        }

        /// Set the savings rate for the MyUSD staking contract
        /// Note: In Cairo, if the underlying call fails, the transaction will revert
        /// with the error from the staking contract (e.g., "Staking: Invalid savings rate")
        fn set_savings_rate(ref self: ContractState, new_rate: u256) {
            let staking_dispatcher = IMyUSDStakingDispatcher {
                contract_address: self.i_staking.read(),
            };

            // Call set_savings_rate on the staking contract
            // If this fails, the transaction reverts with the staking contract's error message
            staking_dispatcher.set_savings_rate(new_rate);
        }

        fn set_engine_address(ref self: ContractState, engine: ContractAddress) {
            self.i_engine.write(engine);
        }

        fn set_staking_address(ref self: ContractState, staking: ContractAddress) {
            self.i_staking.write(staking);
        }
    }
}
