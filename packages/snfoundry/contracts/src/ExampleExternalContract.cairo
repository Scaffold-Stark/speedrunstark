#[starknet::interface]
pub trait IExampleExternalContract<T> {
    fn complete(ref self: T);
    fn completed(self: @T) -> bool;
}

#[starknet::contract]
mod ExampleExternalContract {
    #[storage]
    struct Storage {
        completed: bool,
    }

    #[abi(embed_v0)]
    impl ExampleExternalContractImpl of super::IExampleExternalContract<ContractState> {
        fn complete(ref self: ContractState) {
            self.completed.write(true);
        }
        fn completed(self: @ContractState) -> bool {
            self.completed.read()
        }
    }
}
