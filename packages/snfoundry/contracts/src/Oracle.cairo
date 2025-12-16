#[starknet::interface]
pub trait IOracle<TContractState> {
    fn get_strk_myusd_price(self: @TContractState) -> u256;
    fn get_strk_usd_price(self: @TContractState) -> u256;
}

#[starknet::interface]
pub trait IDEX<TContractState> {
    fn current_price(self: @TContractState) -> u256;
}

#[starknet::contract]
pub mod Oracle {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::{IDEXDispatcher, IDEXDispatcherTrait, IOracle};

    #[storage]
    struct Storage {
        dex_address: ContractAddress,
        default_price: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, dex_address: ContractAddress, default_price: u256) {
        self.dex_address.write(dex_address);
        self.default_price.write(default_price);
    }

    #[abi(embed_v0)]
    impl OracleImpl of IOracle<ContractState> {
        fn get_strk_myusd_price(self: @ContractState) -> u256 {
            // Oracle just returns price from DEX unless no liquidity is available
            let dex_dispatcher = IDEXDispatcher { contract_address: self.dex_address.read() };
            let price = dex_dispatcher.current_price();

            if price == 0 {
                self.default_price.read()
            } else {
                price
            }
        }

        fn get_strk_usd_price(self: @ContractState) -> u256 {
            self.default_price.read()
        }
    }
}
