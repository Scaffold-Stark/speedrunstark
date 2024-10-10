#[starknet::interface]
pub trait ICounter<TState> {
    fn current(self: @TState) -> u256;
    fn increment(ref self: TState);
    fn decrement(ref self: TState);
}

#[starknet::component]
pub mod CounterComponent {
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