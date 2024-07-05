# 🚩 Challenge #1: 🔏 Decentralized Staking App

![readme-1](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/7e7be92753ffa1f18f50976e97fdb0052ca9414a/packages/nextjs/public/banner-decentralized-staking.svg)

🦸 A superpower of Smart contracts is allowing you, the builder, to create a simple set of rules that an adversarial group of players can use to work together. In this challenge, you create a decentralized application where users can coordinate a group funding effort. If the users cooperate, the money is collected in a second smart contract. If they defect, the worst that can happen is everyone gets their money back. The users only have to trust the code.

🏦 Build a `Staker.cairo` contract that collects **ETH** from numerous addresses using a function `stake()` function and keeps track of `balances`. After some `deadline` if it has at least some `threshold` of ETH, it sends it to an `ExampleExternalContract` and triggers the `complete()` action sending the full balance. If not enough **ETH** is collected, allows users to `withdraw()`.

🎛 Building the frontend to display the information and UI is just as important as writing the contract. The goal is to deploy the contract and the app to allow anyone to stake using your app. Use a `Stake {sender: ContractAddress, amount: u256}` Starknet event to list all stakes.

🌟 The final deliverable is deploying a Dapp that lets users send ether to a contract and stake if the conditions are met, then `yarn vercel` your app to a public webserver.

💬 Submit this challenge, meet other builders working on this challenge or get help in the [Builders telegram chat](https://t.me/+wO3PtlRAreo4MDI9)!

---

## Checkpoint 0: 📦 Environment 📚

Before you begin, you need to install the following tools:

- [Node (v18 LTS)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

### Compatible versions

- Scarb - v2.5.4
- Snforge - v0.25.0
- Cairo - v2.5.4

Make sure you have the compatible versions otherwise refer to [Scaffold-Stark Requirements](https://github.com/Quantum3-Labs/scaffold-stark-2?.tab=readme-ov-file#requirements)

Then download the challenge to your computer and install dependencies by running:

```sh
git clone https://github.com/Quantum3-Labs/speedrunstark.git --recurse-submodules challenge-1-decentralized-staking
cd challenge-1-decentralized-staking
git checkout decentralized-staking

yarn install
```

> in the same terminal, start your local network (a blockchain emulator in your computer):

```bash
yarn chain
```

> in a second terminal window, 🛰 deploy your contract (locally):

```sh
cd challenge-1-decentralized-staking
yarn deploy
```

> in a third terminal window, start your 📱 frontend:

```sh
cd challenge-1-decentralized-staking
yarn start
```

📱 Open http://localhost:3000 to see the app.

> 👩‍💻 Rerun `yarn deploy` whenever you want to deploy new contracts to the frontend.

🔏 Now you are ready to edit your smart contract `Staker.cairo` in `packages/sfoundry/contracts`.

---

⚗️ At this point you will need to know basic Cairo syntax. If not, you can pick it up quickly by tinkering with concepts from [📑 The Cairo Book](https://book.cairo-lang.org/ch13-00-introduction-to-starknet-smart-contracts.html) using [🏗️ Scaffold-Stark-2](https://www.scaffoldstark.com/). (In particular:  Contract's State, storage variables, interface, mappings, events, traits, constructor, and public/private functions.)

---

## Checkpoint 1: 🥩 Staking 💵

You'll need to track individual `balances` using a LegacyMap:

```cairo
balances: LegacyMap<ContractAddress, u256>
```

And also track a constant threshold at 1 ether

```cairo
const THRESHOLD: u256 = 1000000000000000000;
```

> 👩‍💻 Write your `stake()` function and test it with the `Debug Contracts` tab in the frontend.

![debugContracts](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/decentralized-staking/packages/nextjs/public/debug-stake.png)

### 🥅 Goals

- [ ] Do you see the balance of the `Staker` contract go up when you `stake()`?
- [ ] Is your `balance` correctly tracked?
- [ ] Do you see the events in the `Stake Events` tab?

  ![allStakings](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/87dae08f476eadb05ea377247885aad16713599f/packages/nextjs/public/events.png)

---

## Checkpoint 2: 🔬 State Machine / Timing ⏱

### State Machine

> ⚙️ Think of your smart contract like a _state machine_. First, there is a **stake** period. Then, if you have gathered the `threshold` worth of ETH, there is a **success** state. Or, we go into a **withdraw** state to let users withdraw their funds.

Set a `deadline` of `get_block_timestamp() + 30` in the constructor to allow 30 seconds for users to stake.

```cairo
self.deadline.write(get_block_timestamp() + 30);
```

👨‍🏫 Smart contracts can't execute automatically, you always need to have a transaction execute to change state. Because of this, you will need to have an `execute()` function that _anyone_ can call, just once, after the `deadline` has expired.

> 👩‍💻 Write your `execute()` function and test it with the Debug Contracts tab

> Check the `ExampleExternalContract.cairo` for the bool you can use to test if it has been completed or not. But do not edit the `ExampleExternalContract.cairo` as it can slow the auto grading.

If the staked amount of the contract `let staked_amount = self.eth_token_dispatcher.read().balanceOf(get_contract_address())` is over the `threshold` by the `deadline`, you will want to call: `self._complete_transfer(staked_amount)`. This will send the funds to the `ExampleExternalContract` and call `complete()`.

If the balance is less than the `threshold`, you want to set a `open_for_withdraw` bool to `true` which will allow users to `withdraw()` their funds.

### Timing

You'll have 30 seconds after deploying until the deadline is reached, you can adjust this in the contract.

> 👩‍💻 Create a `time_left()` function including u64 that returns how much time is left.

⚠️ Be careful! If `get_block_timestamp() >= deadline` you want to return 0;

⏳ _"Time Left"_ will only update if a transaction occurs. You can see the time update by getting funds from the faucet button in navbar just to trigger a new block.

![stakerUI](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/87dae08f476eadb05ea377247885aad16713599f/packages/nextjs/public/stake.png)

> 👩‍💻 You can call `yarn deploy` again any time you want a fresh contract.
> You may need it when you want to reload the _"Time Left"_ of your tests.

Your `Staker UI` tab should be almost done and working at this point.

---

### 🥅 Goals

- [ ] Can you see `time_left()` counting down in the Staker UI tab when you trigger a transaction with the faucet button?
- [ ] If enough ETH is staked by the deadline, does your `execute()` function correctly call `complete()` and stake the ETH?
- [ ] If the threshold isn't met by the deadline, are you able to `withdraw()` your funds?

---

## Checkpoint 3: 💵 UX 🙎

### 🥅 Goals

- [ ] If you send ETH directly to the contract address does it update your `balance` and the `balance` of the contract?

### ⚔️ Side Quests

- [ ] Can `execute()` get called more than once, and is that okay?
- [ ] Can you stake and withdraw freely after the `deadline`, and is that okay?
- [ ] What are other implications of _anyone_ being able to withdraw for someone?

---

### 🐸 It's a trap!

- [ ] Make sure funds can't get trapped in the contract! *Try sending funds after you have executed! What happens?*
- [ ] Try to create a modifier called `notCompleted`. It will check that `ExampleExternalContract` is not completed yet. Use it to protect your `execute` and `withdraw` functions.

### ⚠️ Test it!

- Now is a good time to run `yarn test` to run the automated testing function. It will test that you hit the core checkpoints. You are looking for all green checkmarks and passing tests!

---

## Checkpoint 4: 💾 Deploy your contract! 🛰

📡 Edit the `defaultNetwork` to choose `Sepolia` public Starknet network in `packages/nextjs/scaffold.config.ts`

  ![network](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/simple-nft-example/packages/nextjs/public/ch0-scaffold-config.png)

🔐 You will need to generate a **deployer address** using Argent or Braavos wallet, get your account address and private key and put in `packages/snfoundry/.env`

⛽️ You will need to send ETH to your deployer address with your wallet, or get it from a public faucet.

> 📝 If you plan on submitting this challenge, be sure to set your deadline to at least block.timestamp + 72 hours

🚀 Run yarn deploy --network [network] to deploy your smart contract to a public network (mainnet or sepolia).

![allStakings-blockFrom](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/87dae08f476eadb05ea377247885aad16713599f/packages/nextjs/public/events.png)

> 💬 Hint: For faster loading of your "Stake Events" page, consider updating the fromBlock passed to useScaffoldEventHistory in [packages/nextjs/app/stakings/page.tsx](https://github.com/scaffold-eth/se-2-challenges/blob/challenge-1-decentralized-staking/packages/nextjs/app/stakings/page.tsx) to `blocknumber - 10` at which your contract was deployed. Example: `fromBlock: 3750241n` (where `n` represents its a [BigInt](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt)).
---

## Checkpoint 5: 🚢 Ship your frontend! 🚁

✏️ Edit your frontend config in `packages/nextjs/scaffold.config.ts` to change the targetNetwork to `chains.sepolia`.

💻 View your frontend at http://localhost:3000/stakerUI and verify you see the correct network.

📡 When you are ready to ship the frontend app...

📦 Run `yarn vercel` to package up your frontend and deploy.

> Follow the steps to deploy to Vercel. Once you log in (email, github, etc), the default options should work. It'll give you a public URL.

> If you want to redeploy to the same production URL you can run `yarn vercel --prod`. If you omit the `--prod` flag it will deploy it to a preview/test URL.

> 🦊 Since we have deployed to a public testnet, you will now need to connect using a wallet you own or use a burner wallet. By default 🔥 burner wallets are only available on devnet. You can enable them on every chain by setting `onlyLocalBurnerWallet: false` in your frontend config (`scaffold.config.ts` in `packages/nextjs/`)

#### Configuration of Third-Party Services for Production-Grade Apps.

By default, 🏗 Scaffold-Stark provides predefined API keys for some services such as Infura. This allows you to begin developing and testing your applications more easily, avoiding the need to register for these services.
This is great to complete your **SpeedRunStark**.

For production-grade applications, it's recommended to obtain your own API keys (to prevent rate limiting issues). You can configure these at:

🔷 `RPC_URL_SEPOLIA` variable in `packages/snfoundry/.env` and `packages/nextjs/.env.local`. You can create API keys from the [Infura dashboard](https://www.infura.io/).

> 💬 Hint: It's recommended to store env's for nextjs in Vercel/system env config for live apps and use .env.local for local testing.

---

> 🏃 Head to your next challenge [here](https://github.com/Quantum3-Labs/speedrunstark/tree/token-vendor).

> 💬 Problems, questions, comments on the stack? Post them to the [🏗 scaffold-stark developers chat](https://t.me/+wO3PtlRAreo4MDI9)
