# 🚩 Challenge #0: 🎟 Simple NFT Example

![readme-0](./packages/nextjs/public/hero.png)

📚 This tutorial is meant for developers that already understand the 🖍️ basics: [Starklings](https://starklings.app/) or [Node Guardians](https://nodeguardians.io/campaigns?f=3%3D2)

🎫 Create a simple NFT:

👷‍♀️ You'll compile and deploy your first smart contract. Then, you'll use a template React app full of important Starknet components and hooks. Finally, you'll deploy an NFT to a public network to share with friends! 🚀

🌟 The final deliverable is an app that lets users purchase and transfer NFTs. Deploy your contracts to a testnet, then build and upload your app to a public web server.

💬 Submit this challenge, meet other builders working on this challenge or get help in the [Builders telegram chat](https://t.me/+wO3PtlRAreo4MDI9)!

## Checkpoint 0: 📦 Environment 📚

Before you begin, you need to install the following tools:

- [Node (>= v22)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Rust](https://rust-lang.org/tools/install)
- [asdf](https://asdf-vm.com/guide/getting-started.html)
- [Cairo 1.0 extension for VSCode](https://marketplace.visualstudio.com/items?itemName=starkware.cairo1)

### Starknet-devnet version

To ensure the proper functioning of scaffold-stark, your `starknet-devnet` version must match the version specified in [Compatible versions](#compatible-versions). To accomplish this, first check your `starknet-devnet` version:

```sh
starknet-devnet --version
```

If your `starknet-devnet` version is not the version specified in [Compatible versions](#compatible-versions), you need to install it.

- Install starknet-devnet via `asdf` ([instructions](https://github.com/gianalarcon/asdf-starknet-devnet/blob/main/README.md)). Use the exact version from [Compatible versions](#compatible-versions).

### Scarb version

To ensure the proper functioning of scaffold-stark, your `Scarb` version must match the version specified in [Compatible versions](#compatible-versions). To accomplish this, first check Scarb version:

```sh
scarb --version
```

If your `Scarb` version is not the version specified in [Compatible versions](#compatible-versions), you need to install it. If you already have installed `Scarb` via `starkup`, you can setup this specific version with the following command:

```sh
asdf install scarb <version> && asdf set scarb <version>
```

Replace `<version>` with the exact version from [Compatible versions](#compatible-versions). Otherwise, you can install Scarb following the [instructions](https://docs.swmansion.com/scarb/download.html#install-via-asdf).

### Starknet Foundry version

To ensure the proper functioning of the tests on scaffold-stark, your `Starknet Foundry` version must match the version specified in [Compatible versions](#compatible-versions). To accomplish this, first check your `Starknet Foundry` version:

```sh
snforge --version
```

If your `Starknet Foundry` version is not the version specified in [Compatible versions](#compatible-versions), you need to install it. If you already have installed `Starknet Foundry` via `starkup`, you can setup this specific version with the following command:

```sh
asdf install starknet-foundry <version> && asdf set starknet-foundry <version>
```

Replace `<version>` with the exact version from [Compatible versions](#compatible-versions). Otherwise, you can install Starknet Foundry following the [instructions](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html#installation-via-asdf).

### Compatible versions

- Starknet-devnet - v0.7.2
- Scarb - v2.15.1
- Snforge - v0.55.0
- Cairo - v2.15.0
- Rpc - v0.10.x

Make sure you have the compatible versions otherwise refer to [Scaffold-Stark Requirements](https://github.com/Scaffold-Stark/scaffold-stark-2?.tab=readme-ov-file#requirements)
### Docker Option for Environment Setup

<details>

For an alternative to local installations, you can use Docker to set up the environment.

- Install [Docker](https://www.docker.com/get-started/) and [VSCode Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
- A pre-configured Docker environment is provided via `devcontainer.json` using the `starknetfoundation/starknet-dev` image with the Scarb version specified in [Compatible versions](#compatible-versions).

For complete instructions on using Docker with the project, check out the [Requirements Optional with Docker section in the README](https://github.com/Scaffold-Stark/scaffold-stark-2?tab=readme-ov-file#requirements-alternative-option-with-docker) for setup details.

</details>

Then download the challenge to your computer and install dependencies by running:

```sh
npx create-stark@latest -e challenge-0-simple-nft challenge-0-simple-nft
cd challenge-0-simple-nft
yarn install
```

or clone from SpeedrunStark repo:

```sh
git clone https://github.com/Scaffold-Stark/speedrunstark.git challenge-0-simple-nft
cd challenge-0-simple-nft
git checkout challenge-0-simple-nft
yarn install
```

> in the same terminal, start your local network (a local instance of a blockchain):

```bash
yarn chain
```

> To run a fork : `yarn chain --fork-network <URL> [--fork-block <BLOCK_NUMBER>]`

> in a second terminal window, 🛰 deploy your contract (locally):

```sh
cd challenge-0-simple-nft
yarn deploy
```

> in a third terminal window, start your 📱 frontend:

```sh
cd challenge-0-simple-nft
yarn start
```

📱 Open [http://localhost:3000](http://localhost:3000) to see the app.

---

## Checkpoint 1: ⛽️ Gas & Wallets 👛

> 🔥 We'll use burner wallets on localhost.

> 👛 Explore how burner wallets work in 🏗 Scaffold-Stark. You will notice the `Connect Wallet` button on the top right corner. After click it, you can choose the `Burner Wallet` option. You will get a default prefunded account.

## ![wallet](./packages/nextjs/public/ch0-wallet.png)

## Checkpoint 2: 🖨 Minting

> ✏️ Mint some NFTs! Click the **MINT NFT** button in the `My NFTs` tab.

![image](./packages/nextjs/public/ch0-mynft.png)

👀 You should see your NFTs start to show up:

![image](./packages/nextjs/public/ch0-nfts-images.png)

👛 Open an window Browser and navigate to <http://localhost:3000>

🎟 Transfer an NFT from one address to another using the UI:

![image](./packages/nextjs/public/ch0-nfts-images-transfer.png)

👛 Try to mint an NFT from a different address.

🕵🏻‍♂️ Inspect the `Debug Contracts` tab to figure out what address is the owner of YourCollectible?

🔏 You can also check out your smart contract `your_collectible.cairo` in `packages/snfoundry/contracts`.

💼 Take a quick look at your deploy script `deploy.ts` in `packages/snfoundry/script-ts`.

📝 If you want to edit the frontend, navigate to `packages/nextjs/app` and open the specific page you want to modify. For instance: `/myNFTs/page.tsx`. For guidance on [routing](https://nextjs.org/docs/app/building-your-application/routing/defining-routes) and configuring [pages/layouts](https://nextjs.org/docs/app/building-your-application/routing/pages-and-layouts) checkout the Next.js documentation.

---

## Checkpoint 3: 💾 Deploy your contract! 🛰

🛰 Ready to deploy to a public testnet?!?

> Find the `packages/nextjs/scaffold.config.ts` file and change the `targetNetworks` to `[chains.sepolia]`.

![chall-0-scaffold-config](./packages/nextjs/public/ch0-scaffold-config.png)

🔐 Prepare your environment variables.

> Find the `packages/snfoundry/.env` file and fill the env variables related to Sepolia testnet with your own wallet account address and private key.

> Follow up [Wallet Account](https://docs.starknet.io/quick-start/set-up-an-account) to install the example Wallet on Browser

- Visit [here](https://www.argent.xyz/argent-x) to dowload ArgentX wallet
- visit [here](https://braavos.app/) to dowload Braavos wallet

> You will need to get some STRK Sepolia tokens to deploy your contract to Sepolia testnet.Some popular faucets are [Starknet Faucet](https://starknet-faucet.vercel.app/) and [Blastapi Starknet Sepolia STRK](https://blastapi.io/faucets/starknet-sepolia-strk)

🚀 Deploy your NFT smart contract with `yarn deploy`.

> you input `yarn deploy --network sepolia`.

---

## Checkpoint 4: 🚢 Ship your frontend! 🚁

> 🦊 Since we have deployed to a public testnet, you will now need to connect using a wallet you own(Argent X or Braavos).

![connect-wallet](./packages/nextjs/public/ch0-wallet.png)

> You should see the correct network in the frontend (<http://localhost:3000>):

![image](./packages/nextjs/public/ch0-balance.png)

> 💬 Hint: For faster loading of your transfer page, consider updating the `fromBlock` passed to `useScaffoldEventHistory` in [`packages/nextjs/app/transfers/page.tsx`](https://github.com/Scaffold-Stark/scaffold-stark-2/blob/main/packages/nextjs/hooks/scaffold-stark/useScaffoldEventHistory.ts) to `blocknumber - 10` at which your contract was deployed. Example: `fromBlock: 3750241n` (where `n` represents its a [BigInt](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt)). To find this blocknumber, search your contract's address on Starkscan and find the `Contract Creation` transaction line.

🚀 Deploy your NextJS App

```shell
yarn vercel
```

> Follow the steps to deploy to Vercel. Once you log in (email, github, etc), the default options should work. It'll give you a public URL.

> If you want to redeploy to the same production URL you can run `yarn vercel --prod`. If you omit the `--prod` flag it will deploy it to a preview/test URL.

⚠️ Run the automated testing function to make sure your app passes

```shell
yarn test
```

#### Configuration of Third-Party Services for Production-Grade Apps

By default, 🏗 Scaffold-Stark provides predefined Open API endpoint for some services such as Blast. This allows you to begin developing and testing your applications more easily, avoiding the need to register for these services.
This is great to complete your **SpeedRunStark**.

For production-grade applications, it's recommended to obtain your own API keys (to prevent rate limiting issues). You can configure these at:

🔷 `RPC_URL_SEPOLIA` variable in `packages/snfoundry/.env` and `packages/nextjs/.env.local`. You can create API keys from the [Alchemy dashboard](https://dashboard.alchemy.com/).

> 💬 Hint: It's recommended to store env's for nextjs in Vercel/system env config for live apps and use .env.local for local testing.

---

> 🏃 Head to your next challenge [here](https://github.com/Scaffold-Stark/speedrunstark/tree/challenge-1-decentralized-staking).

> 💭 Problems, questions, comments on the stack? Post them to the [🏗 Scaffold-Stark developers chat](https://t.me/+wO3PtlRAreo4MDI9)
