use starknet::ContractAddress;

#[starknet::interface]
pub trait IYourCollectible<T> {
    fn mint_item(ref self: T, recipient: ContractAddress, uri: ByteArray) -> u256;
}

#[starknet::contract]
mod YourCollectible {
    use contracts::components::Counter::CounterComponent;
    use contracts::components::ERC721Enumerable::ERC721EnumerableComponent;
    use core::num::traits::zero::Zero;

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{
        ERC721Component, interface::{IERC721Metadata, IERC721MetadataCamelOnly}
    };

    use super::{IYourCollectible, ContractAddress};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: CounterComponent, storage: token_id_counter, event: CounterEvent);
    component!(path: ERC721EnumerableComponent, storage: enumerable, event: EnumerableEvent);

    // Expose entrypoints
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl CounterImpl = CounterComponent::CounterImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721EnumerableImpl =
        ERC721EnumerableComponent::ERC721EnumerableImpl<ContractState>;

    // Use internal implementations but do not expose them
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        token_id_counter: CounterComponent::Storage,
        #[substorage(v0)]
        enumerable: ERC721EnumerableComponent::Storage,
        // ERC721URIStorage variables
        // Mapping for token URIs
        token_uris: LegacyMap<u256, ByteArray>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        CounterEvent: CounterComponent::Event,
        EnumerableEvent: ERC721EnumerableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let name: ByteArray = "YourCollectible";
        let symbol: ByteArray = "YCB";
        let base_uri: ByteArray = "https://ipfs.io/ipfs/";

        self.erc721.initializer(name, symbol, base_uri);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl YourCollectibleImpl of IYourCollectible<ContractState> {
        fn mint_item(ref self: ContractState, recipient: ContractAddress, uri: ByteArray) -> u256 {
            self.token_id_counter.increment();
            let token_id = self.token_id_counter.current();
            // let data_sucess = array!['SUCCESS'].span(); // ERC721Receiver data
            // self.erc721.safe_mint(recipient, token_id, data_sucess);
            self.erc721.mint(recipient, token_id);
            self.set_token_uri(token_id, uri);
            token_id
        }
    }

    #[abi(embed_v0)]
    impl WrappedIERC721MetadataImpl of IERC721Metadata<ContractState> {
        // Override token_uri to use the internal ERC721URIStorage _token_uri function
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self._token_uri(token_id)
        }
        fn name(self: @ContractState) -> ByteArray {
            self.erc721.name()
        }
        fn symbol(self: @ContractState) -> ByteArray {
            self.erc721.symbol()
        }
    }

    #[abi(embed_v0)]
    impl WrappedIERC721MetadataCamelOnlyImpl of IERC721MetadataCamelOnly<ContractState> {
        // Override tokenURI to use the internal ERC721URIStorage _token_uri function
        fn tokenURI(self: @ContractState, tokenId: u256) -> ByteArray {
            self._token_uri(tokenId)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // token_uri custom implementation
        fn _token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            assert(self.erc721.exists(token_id), ERC721Component::Errors::INVALID_TOKEN_ID);
            let base_uri = self.erc721._base_uri();
            if base_uri.len() == 0 {
                Default::default()
            } else {
                let uri = self.token_uris.read(token_id);
                format!("{}{}", base_uri, uri)
            }
        }
        // ERC721URIStorage internal functions,
        fn set_token_uri(ref self: ContractState, token_id: u256, uri: ByteArray) {
            assert(self.erc721.exists(token_id), ERC721Component::Errors::INVALID_TOKEN_ID);
            self.token_uris.write(token_id, uri);
        }
    }

    impl ERC721EnumerableHooksImpl<
        T,
        impl ERC721Enumerable: ERC721EnumerableComponent::HasComponent<T>,
        impl Counter: CounterComponent::HasComponent<T>,
        impl HasComponent: ERC721Component::HasComponent<T>,
        +SRC5Component::HasComponent<T>,
        +Drop<T>
    > of ERC721Component::ERC721HooksTrait<T> {
        // Implement this to add custom logic to the ERC721 hooks
        // Similar to _beforeTokenTransfer in OpenZeppelin ERC721.sol
        fn before_update(
            ref self: ERC721Component::ComponentState<T>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            let counter_component = get_dep_component!(@self, Counter);
            let token_id_counter = counter_component.current();
            let mut enumerable_component = get_dep_component_mut!(ref self, ERC721Enumerable);
            if (token_id == token_id_counter) { // `Mint Token` case: Add token to `all_tokens` enumerable component
                let length = enumerable_component.all_tokens_length.read();
                enumerable_component.all_tokens_index.write(token_id, length);
                enumerable_component.all_tokens.write(length, token_id);
                enumerable_component.all_tokens_length.write(length + 1);
            } else if (token_id < token_id_counter
                + 1) { // `Transfer Token` Case: Remove token from owner and update enumerable component
                // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
                // then delete the last slot (swap and pop).
                let owner = self.owner_of(token_id);
                let last_token_index = self.balance_of(owner) - 1;
                let token_index = enumerable_component.owned_tokens_index.read(token_id);

                // When the token to delete is the last token, the swap operation is unnecessary
                if (token_index != last_token_index) {
                    let last_token_id = enumerable_component
                        .owned_tokens
                        .read((owner, last_token_index));
                    // Move the last token to the slot of the to-delete token
                    enumerable_component.owned_tokens.write((owner, token_index), last_token_id);
                    // Update the moved token's index
                    enumerable_component.owned_tokens_index.write(last_token_id, token_index);
                }

                // Clear the last slot
                enumerable_component.owned_tokens.write((owner, last_token_index), 0);
                enumerable_component.owned_tokens_index.write(token_id, 0);
            }
            if (to == Zero::zero()) { // `Burn Token` case: Remove token from `all_tokens` enumerable component
                let last_token_index = enumerable_component.all_tokens_length.read() - 1;
                let token_index = enumerable_component.all_tokens_index.read(token_id);

                let last_token_id = enumerable_component.all_tokens.read(last_token_index);

                enumerable_component.all_tokens.write(token_index, last_token_id);
                enumerable_component.all_tokens_index.write(last_token_id, token_index);

                enumerable_component.all_tokens_index.write(token_id, 0);
                enumerable_component.all_tokens.write(last_token_index, 0);
                enumerable_component.all_tokens_length.write(last_token_index);
            } else if (to != auth) { // `Mint Token` and `Transfer Token` case: Add token owner to `owned_tokens` enumerable component
                let length = self.balance_of(to);
                enumerable_component.owned_tokens.write((to, length), token_id);
                enumerable_component.owned_tokens_index.write(token_id, length);
            }
        }

        fn after_update(
            ref self: ERC721Component::ComponentState<T>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {}
    }
}
