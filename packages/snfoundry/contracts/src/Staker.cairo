use starknet::ContractAddress;
#[starknet::interface]
trait IStaker<T> {
    fn execute(ref self: T);
    fn stake(ref self: T, amount: u256);
    fn withdraw(ref self: T);
    fn balances(self: @T, account: ContractAddress) -> u256;
    //fn example_external_contract_completed(self: @T) -> bool;
    fn deadline(self: @T) -> u64;
    fn example_external_contract(self: @T) -> ContractAddress;
    fn open_for_withdraw(self: @T) -> bool;
    fn threshold(self: @T) -> u256;
    fn total_balance(self: @T) -> u256;
//fn time_left(self: @T) -> u64;
}

#[starknet::contract]
mod Staker {
    use contracts::ExampleExternalContract::{
        IExampleExternalContractDispatcher, IExampleExternalContractDispatcherTrait
    };
    use super::{ContractAddress, IStaker};
    use starknet::{get_block_timestamp, get_caller_address, get_contract_address};
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};

    const THRESHOLD: u256 = 1000000000000000000; // ONE_ETH_IN_WEI: 10 ^ 18;
    const ETH_CONTRACT_ADDRESS: felt252 =
        0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Stake: Stake,
    }

    #[derive(Drop, starknet::Event)]
    struct Stake {
        #[key]
        sender: ContractAddress,
        amount: u256,
    }

    #[storage]
    struct Storage {
        token: IERC20CamelDispatcher,
        balances: LegacyMap<ContractAddress, u256>,
        deadline: u64,
        open_for_withdraw: bool,
        external_contract_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, external_contract_address: ContractAddress,) {
        let eth_contract: ContractAddress = ETH_CONTRACT_ADDRESS.try_into().unwrap();
        self.token.write(IERC20CamelDispatcher { contract_address: eth_contract });
        self.external_contract_address.write(external_contract_address);
    }

    #[abi(embed_v0)]
    impl StakerImpl of IStaker<ContractState> {
        fn stake(
            ref self: ContractState, amount: u256
        ) { // Note: Sender should approve to transfer the amount to the staker contract
        // Implement your stake function here

        // self.emit(Stake { sender, amount }); // uncomment to emit the Stake event
        }

        // Function to execute the transfer or allow withdrawals after the deadline
        fn execute(ref self: ContractState) {}

        fn withdraw(
            ref self: ContractState
        ) { // Todo in UI: Staker contract should approve to transfer back the sender_amount to the sender
        }

        fn balances(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn total_balance(self: @ContractState) -> u256 {
            self.balances.read(get_contract_address())
        }

        fn deadline(self: @ContractState) -> u64 {
            self.deadline.read()
        }

        fn threshold(self: @ContractState) -> u256 {
            THRESHOLD
        }

        fn open_for_withdraw(self: @ContractState) -> bool {
            self.open_for_withdraw.read()
        }

        fn example_external_contract(self: @ContractState) -> ContractAddress {
            self.external_contract_address.read()
        }
    // fn example_external_contract_completed(self: @ContractState) -> bool {

    // }

    // fn time_left(self: @ContractState) -> u64 {}
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _complete_transfer(ref self: ContractState, amount: u256) {}
        fn _not_completed(ref self: ContractState) {}
    }
}
