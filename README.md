# 🚩 Challenge 3: 🎲 Dice Game

![readme-3](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/dice-game/packages/nextjs/public/hero3.png)

📚 This tutorial is meant for developers that already understand the 🖍️ basics: [Starklings](https://starklings.app/) or [Node Guardians](https://nodeguardians.io/campaigns?f=3%3D2)

> 🎰 Randomness is tricky on a public deterministic blockchain. The block hash is an easy to use, but very weak form of randomness. This challenge will give you an example of a contract using block hash to create random numbers. This randomness is exploitable. Other, stronger forms of randomness include commit/reveal schemes, oracles, or VRF from Chainlink.

> 💬 Dice Game is a contract that allows users to roll the dice to try and win the prize. If players roll either a 0, 1, 2, 3, 4 or 5 they will win the current prize amount. The initial prize is 10% of the contract's balance, which starts out at .05 Eth.

> 🧤 Every time a player rolls the dice, they are required to send .002 Eth. 40 percent of this value is added to the current prize amount while the other 60 percent stays in the contract to fund future prizes. Once a prize is won, the new prize amount is set to 10% of the total balance of the DiceGame contract.

> 🧨 Your job is to attack the Dice Game contract! You will create a new contract that will predict the randomness ahead of time and only roll the dice when you're guaranteed to be a winner!

> 💬 Submit this challenge, meet other builders working on this challenge or get help in the [Builders telegram chat](https://t.me/+wO3PtlRAreo4MDI9)!

---

## Checkpoint 0: 📦 Environment 📚

Before you begin, you need to install the following tools:

- [Node (v18 LTS)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

### Compatible versions

- Scarb - v2.5.4
- Snforge - v0.25
- Cairo - v2.5.4

Make sure you have the compatible versions otherwise refer to [Scaffold-Stark Requirements](https://github.com/Quantum3-Labs/scaffold-stark-2?.tab=readme-ov-file#requirements)

Then download the challenge to your computer and install dependencies by running:

```sh

git clone https://github.com/Quantum3-Labs/speedrunstark.git --recurse-submodules dice-game
cd dice-game
git checkout dice-game

yarn install
```


> in the same terminal, start your local network (a local instance of a blockchain):

```bash
yarn chain
```


> in a second terminal window, 🛰 deploy your contract (locally):

```sh
cd dice-game
yarn deploy
```

> in a third terminal window, start your 📱 frontend:

```sh
cd dice-game
yarn start
```

📱 Open [http://localhost:3000](http://localhost:3000) to see the app.

> 👩‍💻 Rerun `yarn deploy` whenever you want to deploy new contracts to the frontend.

---

## Checkpoint 1: 🎲 Dice Game

🔍 Inspect the code in the `DiceGame.cairo` contract in `packages/snfoundry/contracts`

🔒 You will not be changing any code in the `DiceGame.cairo` contract in this challenge. You will write your own contract to predict the outcome, then only roll the dice when it is favourable.

### 🥅 Goals

- [ ] Track the cairo code to find out how the DiceGame contract is generating random numbers.
- [ ] Is it possible to predict the random number for any given roll?

---

## Checkpoint 2: 🔑 Rigged Contract

Start by adding the ETh token address in the `RiggedRoll.cairo` contract to allow it to receive Eth. This will allow us to fund the RiggedRoll contract from the faucet which is required for our contract to call the `rollTheDice()` function.

Next add a `riggedRoll()` function. This function should predict the randomness of a roll, and if the outcome will be a winner, call `rollTheDice()` on the DiceGame contract.

🃏 Predict the outcome by generating your random numbers in the exact same way as the DiceGame contract.

> 📣 Reminder! Calling `rollTheDice()` will fail unless you transfer a value of at least .002 Eth!.

🚀 To deploy your RiggedRoll contract, uncomment the appropriate lines in the `deploy.ts` file in `packages/snfoundry/script-ts/deploy.ts`

💸 You will need to send some funds to your RiggedRoll contract before doing your first roll, you can use the Faucet button at the bottom left of the page.

❓ If you're struggling to get the exact same random number as the DiceGame contract, try adding some `console.log()` statements in both contracts to help you track the values. These messages will appear in the Hardhat node terminal.

### ⚔️ Side Quest

- [ ] Add a statement to require `assert(contract_balance >= 2000000000000000,` in your riggedRoll function. This will help prevent calling the `rollTheDice()` function without enough value.
- [ ] Uncomment the code in `packages/nextjs/app/dice/page.tsx` to show a riggedRoll button and contract balance on the main UI tab. Now you can test your function without switching tabs.
- [ ] Does your riggedRoll function only call `rollTheDice()` when it's going to be a winning roll? What happens when it does call `rollTheDice()`?

![RiggedLosingRoll](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/gabi/dice-game/packages/nextjs/public/ch3-roll.png)

---

## Checkpoint 3: 💵 Where's my money?!?

You have beaten the game, but where is your money? Since the RiggedRoll contract is the one calling `rollTheDice()`, that is where the prize money is being sent.

![RiggedRollAddress](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/gabi/dice-game/packages/nextjs/public/ch3-events.png)

📥 Create a `fn withdraw(ref self: ContractState, to: ContractAddress, amount: u256)` function to allow you to send Eth from RiggedRoll to another address.

### 🥅 Goals

- [ ] Can you send value from the RiggedRoll contract to your front end address?
- [ ] Is anyone able to call the withdraw function? What would be the downside to that?

### ⚔️ Side Quest

- [ ] Lock the withdraw function so it can only be called by the owner.

![WithdrawOnlyOwner](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/gabi/dice-game/packages/nextjs/public/ch3-debug.png)

> ⚠️ But wait, I am not the owner! You will want to set your front end address as the owner in `deploy.ts`. This will allow your front end address to call the withdraw function.

## Checkpoint 4: 💾 Deploy your contracts! 🛰

📡 Edit the `defaultNetwork` to your choice of public Starknet networks in `packages/nextjs/scaffold.config.ts` to `sepolia`.

![network](https://raw.githubusercontent.com/Quantum3-Labs/speedrunstark/simple-nft-example/packages/nextjs/public/ch0-scaffold-config.png)

> Prepare your environment variables.

```shell
cp packages/snfoundry/.env.example packages/snfoundry/.env
```

🔐 You will need to generate a *deployer address* using Argent or Braavos, get your private key and put in `packages/snfoundry/.env`

⛽️ You will need to send ETH or STRK to your deployer Contract Addres with your wallet, or get it from a public faucet of your chosen network.

> Some popular faucets are [Starknet Faucet](https://starknet-faucet.vercel.app/) and [Blastapi Starknet Sepolia Eth](https://blastapi.io/faucets/starknet-sepolia-eth)

🚀 Run `yarn deploy --{DESIRED NETWORK}` , we support sepolia, mainnet and devnet

> 💬 Hint: you can `yarn deploy --network sepolia`.

---

## Checkpoint 5: 🚢 Ship your frontend! 🚁

✏️ Edit your frontend config in `packages/nextjs/scaffold.config.ts` to change the `targetNetwork` to `chains.sepolia` or any other public network.

💻 View your frontend at http://localhost:3000/dice and verify you see the correct network.

📡 When you are ready to ship the frontend app...

📦 Run `yarn vercel` to package up your frontend and deploy.

> Follow the steps to deploy to Vercel. Once you log in (email, github, etc), the default options should work. It'll give you a public URL.

> If you want to redeploy to the same production URL you can run `yarn vercel --prod`. If you omit the `--prod` flag it will deploy it to a preview/test URL.

> 🦊 Since we have deployed to a public testnet, you will now need to connect using a wallet you own or use a burner wallet. By default 🔥 `burner wallets` are only available on `devnet` . You can enable them on every chain by setting `onlyLocalBurnerWallet: false` in your frontend config (`scaffold.config.ts` in `packages/nextjs/`)

#### Configuration of Third-Party Services for Production-Grade Apps.

By default, 🏗 Scaffold-Stark provides predefined API keys for some services such as Infura. This allows you to begin developing and testing your applications more easily, avoiding the need to register for these services.
This is great to complete your SpeedRunStark.

For production-grade applications, it's recommended to obtain your own API keys (to prevent rate limiting issues). You can configure these at:

🔷 `RPC_URL_SEPOLIA` variable in `packages/snfoundry/.env` and `packages/nextjs/.env.local`. You can create API keys from the [Infura dashboard](https://www.infura.io/).

> 💬 Hint: It's recommended to store env's for nextjs in Vercel/system env config for live apps and use .env.local for local testing.

---

> 🏃 Head to your next challenge [here](https://speedrunstark.com/).

> 💬 Problems, questions, comments on the stack? Post them to the [🏗 scaffold-stark developers chat](https://t.me/+wO3PtlRAreo4MDI9)
