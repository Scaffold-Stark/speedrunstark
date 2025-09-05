use starknet::ContractAddress;

#[starknet::interface]
pub trait IYourCollectible<T> {
    fn mint_item(ref self: T, recipient: ContractAddress, uri: ByteArray) -> u256;
}

#[starknet::contract]
pub mod YourCollectible {
    use contracts::components::counter::CounterComponent;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc721::extensions::ERC721EnumerableComponent;
    use openzeppelin_token::erc721::extensions::ERC721EnumerableComponent::InternalTrait as EnumerableInternalTrait;
    use openzeppelin_token::erc721::interface::IERC721Metadata;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use super::{ContractAddress, IYourCollectible};

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
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721EnumerableImpl =
        ERC721EnumerableComponent::ERC721EnumerableImpl<ContractState>;

    // Use internal implementations but do not expose them
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        token_id_counter: CounterComponent::Storage,
        #[substorage(v0)]
        pub enumerable: ERC721EnumerableComponent::Storage,
        // ERC721URIStorage variables
        // Mapping for token URIs string format
        token_uris: Map<u256, ByteArray>,
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
        self.enumerable.initializer();
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    pub impl YourCollectibleImpl of IYourCollectible<ContractState> {
        fn mint_item(ref self: ContractState, recipient: ContractAddress, uri: ByteArray) -> u256 {
            self.token_id_counter.increment();
            let token_id = self.token_id_counter.current();
            self.erc721.mint(recipient, token_id); // Todo: use `safe_mint instead of mint
            self.set_token_uri(token_id, uri);
            token_id
        }
    }

    #[abi(embed_v0)]
    pub impl WrappedIERC721MetadataImpl of IERC721Metadata<ContractState> {
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

    // Implement this to add custom logic to the ERC721 hooks before mint/mint_item, transfer,
    // transfer_from Similar to _beforeTokenTransfer in OpenZeppelin ERC721.sol
    impl ERC721HooksImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress,
        ) {
            let mut contract_state = self.get_contract_mut();
            contract_state.enumerable.before_update(to, token_id);
        }
    }
}
