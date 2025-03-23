use openzeppelin_token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IStaker<T> {
    // Core functions
    fn execute(ref self: T);
    fn stake(ref self: T, amount: u256);
    fn withdraw(ref self: T);
    fn on_receive(ref self: T, amount: u256);
    // Getters
    fn balances(self: @T, account: ContractAddress) -> u256;
    fn completed(self: @T) -> bool;
    fn deadline(self: @T) -> u64;
    fn example_external_contract(self: @T) -> ContractAddress;
    fn open_for_withdraw(self: @T) -> bool;
    fn eth_token_dispatcher(self: @T) -> IERC20CamelDispatcher;
    fn threshold(self: @T) -> u256;
    fn total_balance(self: @T) -> u256;
    fn time_left(self: @T) -> u64;
}

#[starknet::contract]
pub mod Staker {
    use contracts::ExampleExternalContract::{
        IExampleExternalContractDispatcher, IExampleExternalContractDispatcherTrait,
    };
    use starknet::storage::Map;
    use starknet::{get_block_timestamp, get_caller_address, get_contract_address};
    use super::{ContractAddress, IERC20CamelDispatcher, IERC20CamelDispatcherTrait, IStaker};

    const THRESHOLD: u256 = 1000000000000000000; // ONE_ETH_IN_WEI: 10 ^ 18;

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
        eth_token_dispatcher: IERC20CamelDispatcher,
        balances: Map<ContractAddress, u256>,
        deadline: u64,
        open_for_withdraw: bool,
        external_contract_address: ContractAddress,
    }

    #[constructor]
    pub fn constructor(
        ref self: ContractState,
        eth_contract: ContractAddress,
        external_contract_address: ContractAddress,
    ) {
        self.eth_token_dispatcher.write(IERC20CamelDispatcher { contract_address: eth_contract });
        self.external_contract_address.write(external_contract_address);
        self.deadline.write(get_block_timestamp() + (72*60*60));
    }

    #[abi(embed_v0)]
    impl StakerImpl of IStaker<ContractState> {
        // ToDo Checkpoint 1: Implement your `stake` function here
        // ToDo Checkpoint 3: Assert that the staking period has not ended
        fn stake(
            ref self: ContractState, amount: u256,
        ) { // Note: In UI and Debug contract `sender` should call `approve`` before to `transfer` the amount to the staker contract
            // Check if amount is greater than 0
            assert(self.time_left() > 0, 'Staking period has ended');

            assert(amount > 0, 'Amount must be greater than 0');

            let sender = get_caller_address();
            let token_dispatcher = self.eth_token_dispatcher.read();
            
            // Check if sender has enough balance
            let sender_balance = token_dispatcher.balanceOf(sender);
            assert(sender_balance >= amount, 'Insufficient balance');
            
            // Check if contract has enough allowance
            let allowance = token_dispatcher.allowance(sender, get_contract_address());
            assert(allowance >= amount, 'Insufficient allowance');
            
            // Transfer tokens from sender to this contract
            token_dispatcher.transferFrom(sender, get_contract_address(), amount);
            
            let current_balance = self.balances.read(sender);
            self.balances.write(sender, current_balance + amount);
            
            // Emit the Stake event
            self.emit(Stake { sender, amount });
        }

        // Function to execute the transfer or allow withdrawals after the deadline
        // ToDo Checkpoint 2: Implement your `execute` function here
        // In this implimentation, we should call the `complete_transfer` function if the staked
        // amount is greater than or equal to the threshold Otherwise, we should call
        // `open_for_withdraw` function ToDo Checkpoint 3: Assert that the staking period has ended
        // ToDo Checkpoint 3: Protect the function calling `not_completed` function before the
        // execution
        fn execute(ref self: ContractState) {
            self.not_completed();
            assert(self.time_left() == 0, 'Staking period not ended yet');

            let staked_amount = self.eth_token_dispatcher.read().balanceOf(get_contract_address());
            let threshold = self.threshold();

            if staked_amount >= threshold {
                self.complete_transfer(staked_amount);
            } else {
                self.open_for_withdraw.write(true);
            }
        }

        // ToDo Checkpoint 3: Implement your `withdraw` function here
        fn withdraw(ref self: ContractState) {
            self.not_completed();

            assert(self.open_for_withdraw.read(), 'Withdrawals not open');

            let sender = get_caller_address();
            let staked_balance = self.balances.read(sender);

            assert(staked_balance > 0, 'No balance');

            self.eth_token_dispatcher.read().transfer(sender, staked_balance);  
            self.balances.write(sender, 0);
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

        fn eth_token_dispatcher(self: @ContractState) -> IERC20CamelDispatcher {
            self.eth_token_dispatcher.read()
        }

        fn open_for_withdraw(self: @ContractState) -> bool {
            self.open_for_withdraw.read()
        }

        fn example_external_contract(self: @ContractState) -> ContractAddress {
            self.external_contract_address.read()
        }
        // Read Function to check if the external contract is completed.
        // ToDo Checkpoint 3: Implement your completed function here
        fn completed(self: @ContractState) -> bool {
            let external_contract = self.external_contract_address.read();
            let external_dispatcher = IExampleExternalContractDispatcher { contract_address: external_contract };
            external_dispatcher.completed()
        }
        // ToDo Checkpoint 2: Implement your time_left function here
        fn time_left(self: @ContractState) -> u64 {
            if get_block_timestamp() >= self.deadline() {
                return 0;
            }
            return self.deadline() - get_block_timestamp();
        }

        fn on_receive(ref self: ContractState, amount: u256) {
            self.stake(amount);
        }
      }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // ToDo Checkpoint 2: Implement your complete_transfer function here
        // This function should be called after the deadline has passed and the staked amount is
        // greater than or equal to the threshold You have to call/use this function in the above
        // `execute` function This function should call the `complete` function of the external
        // contract and transfer the staked amount to the external contract
        fn complete_transfer(
            ref self: ContractState, amount: u256,
        ) { // Note: Staker contract should approve to transfer the staked_amount to the external contract
            let external_contract = self.external_contract_address.read();
            let token_dispatcher = self.eth_token_dispatcher.read();
            token_dispatcher.transfer(external_contract, amount);

            // Create dispatcher for external contract
            let external_dispatcher = IExampleExternalContractDispatcher { contract_address: external_contract };
            external_dispatcher.complete();

            self.balances.write(get_contract_address(), 0);
        }
        // ToDo Checkpoint 3: Implement your not_completed function here
        fn not_completed(ref self: ContractState) {
            assert!(!self.completed(), "External contract already completed");
        }
    }
}
