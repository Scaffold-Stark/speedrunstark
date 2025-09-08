use starknet::ContractAddress;

#[starknet::interface]
pub trait IMultisigWallet<TContractState> {
    fn transfer_funds(ref self: TContractState, to: ContractAddress, amount: u256);
}

#[starknet::contract]
mod CustomMultisigWallet {
    use contracts::custom_multisig_component::MultisigComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{ContractAddress, IMultisigWallet};

    const STRK_CONTRACT_ADDRESS: ContractAddress =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        .try_into()
        .unwrap();

    component!(path: MultisigComponent, storage: multisig, event: MultisigEvent);

    #[abi(embed_v0)]
    impl MultisigImpl = MultisigComponent::MultisigImpl<ContractState>;
    impl MultisigInternalImpl = MultisigComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        multisig: MultisigComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MultisigEvent: MultisigComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, quorum: u32, signer: ContractAddress) {
        self.multisig.initializer(quorum, signer);
    }

    #[abi(embed_v0)]
    impl MultisigWalletImpl of IMultisigWallet<ContractState> {
        fn transfer_funds(ref self: ContractState, to: ContractAddress, amount: u256) {
            let strk_contract_address = STRK_CONTRACT_ADDRESS;
            let token_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            token_dispatcher.transfer(to, amount);
        }
    }
}
