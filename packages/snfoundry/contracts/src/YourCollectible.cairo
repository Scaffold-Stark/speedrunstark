use starknet::ContractAddress;

#[starknet::interface]
pub trait IYourCollectible<T> {
    fn mint_item(ref self: T, recipient: ContractAddress, uri: ByteArray) -> u256;
}

#[starknet::interface]
pub trait IERC721Enumerable<T> {
    fn token_of_owner_by_index(self: @T, owner: ContractAddress, index: u256) -> u256;
    fn total_supply(self: @T) -> u256;
}

#[starknet::interface]
pub trait IERC721<T> {
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn owner_of(self: @T, token_id: u256) -> ContractAddress;
}

#[starknet::interface]
pub trait IERC721Metadata<T> {
    fn token_uri(self: @T, token_id: u256) -> ByteArray;
}

#[starknet::contract]
mod YourCollectible {
    use contracts::Counter::CounterComponent;
    use core::array::ArrayTrait;
    use core::num::traits::zero::Zero;
    use openzeppelin::access::ownable::OwnableComponent;

    use openzeppelin::account::interface::ISRC6_ID;
    use openzeppelin::introspection::interface::{ISRC5, ISRC5_ID};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::interface::{
        IERC721_ID, IERC721_METADATA_ID, IERC721_RECEIVER_ID,
    };
    use openzeppelin::token::erc721::{
        ERC721ReceiverComponent, ERC721Component, interface::{IERC721, IERC721Metadata}
    };

    use starknet::get_caller_address;
    use super::{IYourCollectible, ContractAddress, IERC721Enumerable};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: CounterComponent, storage: token_id_counter, event: CounterEvent);
    component!(path: ERC721ReceiverComponent, storage: erc721_receiver, event: ERC721ReceiverEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl CounterImpl = CounterComponent::CounterImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl ERC721ReceiverInternalImpl = ERC721ReceiverComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc721_receiver: ERC721ReceiverComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        token_id_counter: CounterComponent::Storage,
        // ERC721URIStorage variables
        // Mapping for token URIs
        token_uris: LegacyMap<u256, ByteArray>,
        // IERC721Enumerable variables
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

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        ERC721ReceiverEvent: ERC721ReceiverComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        CounterEvent: CounterComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let name: ByteArray = "YourCollectible";
        let symbol: ByteArray = "YCB";
        let base_uri: ByteArray = "https://ipfs.io/ipfs/";

        self.erc721.initializer(name, symbol, base_uri);
        self.ownable.initializer(owner);
        self.erc721_receiver.initializer();
    }

    #[abi(embed_v0)]
    impl YourCollectibleImpl of IYourCollectible<ContractState> {
        fn mint_item(ref self: ContractState, recipient: ContractAddress, uri: ByteArray) -> u256 {
            self.token_id_counter.increment();
            let token_id = self.token_id_counter.current();
            self.mint(recipient, token_id);
            self._set_token_uri(token_id, uri);
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
    impl IERC721EnumerableImpl of IERC721Enumerable<ContractState> {
        fn token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> u256 {
            assert(index < self.erc721.balance_of(owner), 'Owner index out of bounds');
            self.owned_tokens.read((owner, index))
        }
        fn total_supply(self: @ContractState) -> u256 {
            self.all_tokens_length.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // IYourCollectible internal functions
        fn mint(ref self: ContractState, recipient: ContractAddress, token_id: u256) {
            assert(!recipient.is_zero(), ERC721Component::Errors::INVALID_RECEIVER);
            assert(!self.erc721.exists(token_id), ERC721Component::Errors::ALREADY_MINTED);
            self.erc721.mint(recipient, token_id);
        }

        // ERC721URIStorage internal functions
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
        fn _set_token_uri(ref self: ContractState, token_id: u256, uri: ByteArray) {
            assert(self.erc721.exists(token_id), ERC721Component::Errors::INVALID_TOKEN_ID);
            self.token_uris.write(token_id, uri);
        }
    }

    impl ERC721HooksEmptyImpl of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {
            let mut contract_state = ERC721Component::HasComponent::get_contract_mut(ref self);
            let token_id_counter = contract_state.token_id_counter.current();
            if (token_id == token_id_counter) { // Mint case: self._add_token_to_all_tokens_enumeration(first_token_id);
                let length = contract_state.all_tokens_length.read();
                contract_state.all_tokens_index.write(token_id, length);
                contract_state.all_tokens.write(length, token_id);
            } else if (token_id < token_id_counter
                + 1) { // Transfer Case: self._remove_token_from_owner_enumeration(auth, first_token_id);
                // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
                // then delete the last slot (swap and pop).
                let owner = self.owner_of(token_id);
                let last_token_index = self.balance_of(owner) - 1;
                let token_index = contract_state.owned_tokens_index.read(token_id);

                // When the token to delete is the last token, the swap operation is unnecessary
                if (token_index != last_token_index) {
                    let last_token_id = contract_state.owned_tokens.read((owner, last_token_index));
                    // Move the last token to the slot of the to-delete token
                    contract_state.owned_tokens.write((owner, token_index), last_token_id);
                    // Update the moved token's index
                    contract_state.owned_tokens_index.write(last_token_id, token_index);
                }

                // Clear the last slot
                contract_state.owned_tokens.write((owner, last_token_index), 0);
                contract_state.owned_tokens_index.write(token_id, 0);
            }
            if (to == Zero::zero()) { // Burn case: self._remove_token_from_all_tokens_enumeration(first_token_id);
                let last_token_index = contract_state.all_tokens_length.read() - 1;
                let token_index = contract_state.all_tokens_index.read(token_id);

                let last_token_id = contract_state.all_tokens.read(last_token_index);

                contract_state.all_tokens.write(token_index, last_token_id);
                contract_state.all_tokens_index.write(last_token_id, token_index);

                contract_state.all_tokens_index.write(token_id, 0);
                contract_state.all_tokens.write(last_token_index, 0);
                contract_state.all_tokens_length.write(last_token_index);
            } else if (to != auth) { //self._add_token_to_owner_enumeration(to, first_token_id);
                let length = self.balance_of(to);
                contract_state.owned_tokens.write((to, length), token_id);
                contract_state.owned_tokens_index.write(token_id, length);
            }
        }

        fn after_update(
            ref self: ERC721Component::ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {}
    }
}
