use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
#[starknet::interface]
pub trait IDiceGame<T> {
    fn init(ref self: T, init_balance: u256);
    fn roll_dice(ref self: T, amount: u256);
    fn last_dice_value(self: @T) -> u256;
    fn nonce(self: @T) -> u256;
    fn prize(self: @T) -> u256;
    fn eth_token(self: @T) -> IERC20CamelDispatcher;
}

#[starknet::contract]
mod DiceGame {
    use keccak::keccak_u256s_le_inputs;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use starknet::{ContractAddress, get_contract_address, get_block_number, get_caller_address};
    use super::IDiceGame;

    const ETH_CONTRACT_ADDRESS: felt252 =
        0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Roll: Roll,
        Winner: Winner,
    }

    #[derive(Drop, starknet::Event)]
    struct Roll {
        #[key]
        player: ContractAddress,
        amount: u256,
        roll: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Winner {
        winner: ContractAddress,
        amount: u256,
    }

    #[storage]
    struct Storage {
        eth_token: IERC20CamelDispatcher,
        nonce: u256,
        prize: u256,
        last_dice_value: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let eth_contract: ContractAddress = ETH_CONTRACT_ADDRESS.try_into().unwrap();
        self.eth_token.write(IERC20CamelDispatcher { contract_address: eth_contract });
    }


    #[abi(embed_v0)]
    impl DiceGameImpl of super::IDiceGame<ContractState> {
        fn init(ref self: ContractState, init_balance: u256) {
            self
                .eth_token
                .read()
                .transferFrom(get_caller_address(), get_contract_address(), init_balance);
            self._reset_prize();
        }

        fn roll_dice(ref self: ContractState, amount: u256) {
            // >= 0.002 ETH 
            assert(amount >= 2000000000000000, 'Not enough ETH');
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            // call approve on UI
            self.eth_token.read().transferFrom(caller, this_contract, amount);

            let prev_block: u256 = get_block_number().into() - 1;
            let array = array![prev_block, self.nonce.read()];
            let roll = keccak_u256s_le_inputs(array.span()) % 16;
            self.last_dice_value.write(roll);
            self.nonce.write(self.nonce.read() + 1);
            let new_prize = self.prize.read() + amount * 4 / 10;
            self.prize.write(new_prize);

            self.emit(Roll { player: caller, amount, roll });

            if (roll > 5) {
                return;
            }

            let contract_balance = self.eth_token.read().balanceOf(this_contract);
            let prize = self.prize.read();
            assert(contract_balance >= prize, 'Not enough balance');
            self.eth_token.read().transfer(caller, prize);

            self._reset_prize();
            self.emit(Winner { winner: caller, amount: prize });
        }
        fn last_dice_value(self: @ContractState) -> u256 {
            self.last_dice_value.read()
        }
        fn nonce(self: @ContractState) -> u256 {
            self.nonce.read()
        }

        fn prize(self: @ContractState) -> u256 {
            self.prize.read()
        }
        fn eth_token(self: @ContractState) -> IERC20CamelDispatcher {
            self.eth_token.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn _reset_prize(ref self: ContractState) {
            let contract_balance = self.eth_token.read().balanceOf(get_contract_address());
            self.prize.write(contract_balance / 10);
        }
    }
}
