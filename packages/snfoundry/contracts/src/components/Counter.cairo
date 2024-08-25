#[starknet::interface]
pub trait ICounter<T> {
    fn current(self: @T) -> u256;
    fn increment(ref self: T);
    fn decrement(ref self: T);
}

#[starknet::component]
pub mod CounterComponent {
    use starknet::ContractAddress;
    use super::{ICounter};

    #[storage]
    struct Storage {
        value: u256
    }

    #[embeddable_as(CounterImpl)]
    impl Counter<
        TContractState, +HasComponent<TContractState>
    > of ICounter<ComponentState<TContractState>> {
        fn current(self: @ComponentState<TContractState>) -> u256 {
            self.value.read()
        }

        fn increment(ref self: ComponentState<TContractState>) {
            self.value.write(self.value.read() + 1);
        }

        fn decrement(ref self: ComponentState<TContractState>) {
            self.value.write(self.value.read() - 1);
        }
    }
}
