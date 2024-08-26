use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC721Enumerable<TState> {
    fn token_of_owner_by_index(self: @TState, owner: ContractAddress, index: u256) -> u256;
    fn total_supply(self: @TState) -> u256;
}

#[starknet::component]
pub mod ERC721EnumerableComponent {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::interface::IERC721;
    use super::{IERC721Enumerable, ContractAddress};

    #[storage]
    struct Storage {
        // Mapping from owner to list of owned token IDs
        owned_tokens: LegacyMap<(ContractAddress, u256), u256>,
        // Mapping from token ID to index of the owner tokens list
        owned_tokens_index: LegacyMap<u256, u256>,
        // Mapping with all token ids, 
        all_tokens: LegacyMap<u256, u256>,
        // Helper to get the length of `all_tokens`
        all_tokens_length: u256,
        // Mapping from token id to position in the allTokens array
        all_tokens_index: LegacyMap<u256, u256>
    }

    #[embeddable_as(ERC721EnumerableImpl)]
    impl ERC721Enumerable<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        +Drop<TContractState>
    > of IERC721Enumerable<ComponentState<TContractState>> {
        fn token_of_owner_by_index(
            self: @ComponentState<TContractState>, owner: ContractAddress, index: u256
        ) -> u256 {
            let erc721_component = get_dep_component!(self, ERC721);
            let balance = erc721_component.balance_of(owner);
            assert(index < balance, 'Owner index out of bounds');
            self.owned_tokens.read((owner, index))
        }
        fn total_supply(self: @ComponentState<TContractState>) -> u256 {
            self.all_tokens_length.read()
        }
    }
}
