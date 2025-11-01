use starknet::ContractAddress;

#[starknet::interface]
pub trait IMyUSD<TContractState> {
    // MyUSD specific functions
    fn mint(ref self: TContractState, to: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, amount: u256);
    fn set_engine(ref self: TContractState, engine: ContractAddress);
}

#[starknet::contract]
pub mod MyUSD {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::{DefaultConfig, ERC20Component, ERC20HooksEmptyImpl};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};
    use super::IMyUSD;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // External
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    // Internal
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        MyUSDMinted: MyUSDMinted,
        MyUSDBurned: MyUSDBurned,
        EngineUpdated: EngineUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct MyUSDMinted {
        #[key]
        to: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MyUSDBurned {
        #[key]
        from: ContractAddress,
        #[key]
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct EngineUpdated {
        #[key]
        old_engine: ContractAddress,
        #[key]
        new_engine: ContractAddress,
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        engine: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, engine: ContractAddress) {
        // Initialize ERC20
        self.erc20.initializer("MyUSD Stablecoin", "MyUSD");
        // Initialize Ownable
        self.ownable.initializer(owner);
        // Set engine
        self.engine.write(engine);
    }

    #[abi(embed_v0)]
    impl MyUSDImpl of IMyUSD<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            self._only_engine();
            self.erc20.mint(to, amount);
            self.emit(MyUSDMinted { to, amount });
        }

        fn burn(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            self.erc20.burn(caller, amount);
            self.emit(MyUSDBurned { from: caller, amount });
        }

        fn set_engine(ref self: ContractState, engine: ContractAddress) {
            self._only_owner();
            let old_engine = self.engine.read();
            self.engine.write(engine);
            self.emit(EngineUpdated { old_engine, new_engine: engine });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _only_engine(self: @ContractState) {
            let caller = get_caller_address();
            let engine = self.engine.read();
            assert!(caller == engine, "Only engine can call this function");
        }

        fn _only_owner(self: @ContractState) {
            self.ownable.assert_only_owner();
        }
    }
}
