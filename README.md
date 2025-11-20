# 💰 MyUSD Stablecoin

![readme-stablecoin](/packages/nextjs/public/hero5.png)

🪙 Build your own decentralized stablecoin! In this challenge, you'll build the core engine for **MyUSD**, a crypto-backed stablecoin designed to maintain a peg to $1 USD.

You'll get to wear the hat of a DeFi protocol that wants to maintain price stability while also increasing adoption of your stablecoin product, diving deep into concepts like **collateralization, minting, burning, interest rates,** and **liquidations** – all crucial components of a robust stablecoin system.

<details markdown='1'><summary>❓ Wondering what a stablecoin is? Read the overview here.</summary>

Stablecoins are cryptocurrencies designed to maintain a stable value relative to a specific asset (in our case, $1 USD). In some ways they serve as a bridge between traditional finance and crypto, providing stability in an otherwise volatile market.

🤔 How do they maintain their peg? There are several mechanisms:

- 💎 **Collateralization**: Users lock up valuable assets (like STRK) as collateral to mint stablecoins. This ensures each stablecoin is backed by real value.
- 📊 **Interest Rates**: By adjusting borrowing and savings rates, we can influence supply and demand to maintain the peg.
- 🚨 **Liquidations**: If collateral value drops too low, positions can be liquidated to protect the system.
- 💸 **Market Operations**: The system can incentivize buying or selling to maintain the peg.

👍 Now that you understand the basics, let's build our own stablecoin system!

</details>

---

🌟 The final deliverable is an app that allows users to mint and manage a decentralized stablecoin (MyUSD) backed by STRK collateral, with features for depositing collateral, minting/burning tokens, managing positions, and participating in liquidations.
Deploy your contracts to a testnet then build and upload your app to a public web server. Submit the url on [SpeedRunStark.com](https://speedrunstark.com/)!

🔍 First we should mention there are lots of different types of stablecoins on the market. Some are backed 1:1 with actual USD-denominated assets in a bank (USDC, USDT). Others are backed by crypto and use special mechanisms to maintain their peg (Dai, RAI, LUSD/BOLD).

📚 This challenge is modeled after one of the first crypto-backed stablecoins called Dai - back when the only thing backing it was a single collateral type. Later Dai would allow multiple types of collateral and change its design somewhat. The version we are building is commonly referred to as "single collateral Dai".

⚠️ You are highly encouraged to have completed the [Over-collateralized Lending challenge](https://speedrunstark.com/challenge/over-collateralized-lending) prior to attempting this one since we will be building on that same basic system but won't be discussing it in detail.

💬 Meet other builders working on this challenge and get help in the [Stablecoin Challenge Telegram](https://t.me/+y93US5WbP5dkNDFh)

---

> **Implementation note:** The codebase uses the `Errors::...` constants with `assert` statements instead of emitting `Engine__*` custom errors.

## Checkpoint 0: 📦 Environment 📚

Before you begin, you need to install the following tools:

- [Node (>= v22)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

### Starknet-devnet version

To ensure the proper functioning of scaffold-stark, your `starknet-devnet` version must match the version specified in [Compatible versions](#compatible-versions). To accomplish this, first check your `starknet-devnet` version:

```sh
starknet-devnet --version
```

If your `starknet-devnet` version is not the version specified in [Compatible versions](#compatible-versions), you need to install it.

- Install starknet-devnet via `asdf` ([instructions](https://github.com/gianalarcon/asdf-starknet-devnet/blob/main/README.md)). Use the exact version from [Compatible versions](#compatible-versions).

### Compatible versions

- Starknet-devnet - 0.6.1
- Scarb - v2.12.2
- Snforge - v0.50.0
- Cairo - v2.12.2
- Rpc - v0.9.x

Make sure you have the compatible versions otherwise refer to [Scaffold-Stark Requirements](https://github.com/Scaffold-Stark/scaffold-stark-2?.tab=readme-ov-file#requirements)

### Docker Option for Environment Setup

<details>

For an alternative to local installations, you can use Docker to set up the environment.

- Install [Docker](https://www.docker.com/get-started/) and [VSCode Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
- A pre-configured Docker environment is provided via `devcontainer.json` using the `starknetfoundation/starknet-dev` image with the Scarb version specified in [Compatible versions](#compatible-versions).

For complete instructions on using Docker with the project, check out the [Requirements Optional with Docker section in the README](https://github.com/Scaffold-Stark/scaffold-stark-2?tab=readme-ov-file#requirements-alternative-option-with-docker) for setup details.

</details>

📥 Then download the challenge to your computer and install dependencies by running:

```sh
npx create-stark@latest -e challenge-stablecoin challenge-stablecoin
cd challenge-stablecoin
yarn install
```

or clone from SpeedrunStark repo:

```sh
git clone https://github.com/Scaffold-Stark/speedrunstark.git challenge-stablecoin
cd challenge-stablecoin
git checkout challenge-stablecoin
yarn install
```

> in the same terminal, start your local network (a local instance of a blockchain):

```sh
yarn chain
```

> To run a fork : `yarn chain --fork-network <URL> [--fork-block <BLOCK_NUMBER>]`

> in a second terminal window, 🛰 deploy your contract (locally):

```sh
cd <challenge_folder_name>
yarn deploy
```

> in a third terminal window, start your 📱 frontend:

```sh
cd <challenge_folder_name>
yarn start
```

📱 Open <http://localhost:3000> to see the app.

> 👩‍💻 Rerun `yarn deploy --reset` whenever you want to deploy new contracts to the frontend, update your current contracts with changes, or re-deploy it to get a fresh contract address.

🔏 Now you are ready to edit your smart contract `MyUSDEngine.cairo` in `packages/snfoundry/contracts/src`

---

## Checkpoint 1: 🎯 System Overview

🔍 Let's understand the key components and mechanics of our stablecoin system.

These are located in `packages/snfoundry/contracts/src`. Go check them out and reference the following descriptions of each contract.

### Core Components

1. 💱 **DEX (`DEX.cairo`)**
   - Simple decentralized exchange for the STRK/MyUSD pair
   - Provides liquidity for users to swap between STRK and MyUSD
   - We naively use this to determine the market price of MyUSD

2. 💰 **MyUSD Token (`MyUSD.cairo`)**
   - The actual stablecoin token (ERC20 compatible)
   - Can be minted and burned only by the engine

3. ⚙️ **Engine (`MyUSDEngine.cairo`)**
   - This is what _you_ will be editing
   - Core contract managing the stablecoin system
   - Handles collateral deposits (STRK)
   - Controls minting/burning of MyUSD
   - Manages interest rates and liquidations
   - Enforces collateralization requirements

4. 🏦 **Staking (`MyUSDStaking.cairo`)**
   - Allows users to stake MyUSD
   - Earns yield from borrow rates
   - Creates buy pressure for MyUSD

5. 📊 **Oracle (`Oracle.cairo`)**
   - Provides STRK/MyUSD and STRK/USD price feeds
   - STRK/USD price is **fixed** at the time you deploy the contracts

> ⚠️ The real world STRK price being fixed is just a shortcut on our parts to simplify the overall process of understanding the mechanics at play. It would be substantially harder to track the impact of the peg manipulation devices if we also had to account for a changing STRK price.

6. 📈 **Rate Controller (`RateController.cairo`)**
   - Manages borrow and savings rates
   - Key tool for maintaining the $1 peg

This system creates a stablecoin where we have two levers to pull in order to maintain the peg.

---

## Checkpoint 2: 🧱 Depositing Collateral & Understanding Value

First, users need a way to deposit collateral (STRK) into the system. We also need to know the USD value of this collateral.

🔍 Open the `packages/snfoundry/contracts/src/MyUSDEngine.cairo` file to begin adding the logic to the existing (empty) methods.

### ✏️ Tasks:

1.  **Implement `add_collateral()`**
    - This function takes a `strk_amount` argument and uses ERC20 `transfer_from`, so the caller must approve STRK to the engine first.
    - It should update the `s_user_collateral` mapping for the caller to reflect how much STRK they deposited.
    - It should emit a `CollateralAdded` event.
    - Don't forget to `assert(strk_amount > 0, Errors::INVALID_AMOUNT);`.

    <details markdown='1'>
    <summary>💡 Hint: Adding Collateral</summary>

    This is a simple function that:
    - Pulls STRK from the caller via `transfer_from`
    - Updates a mapping to track how much STRK each user has deposited
    - Emits an event for tracking

    Remember to:
    - Check for zero value
    - Use the existing mapping
    - Include the current STRK price (in MyUSD) in the event

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn add_collateral(ref self: ContractState, strk_amount: u256) {
        let caller = starknet::get_caller_address();
        assert(strk_amount > 0, Errors::INVALID_AMOUNT);

        let strk_dispatcher = self._get_strk();
        let success = strk_dispatcher.transfer_from(
            caller,
            starknet::get_contract_address(),
            strk_amount,
        );
        assert(success, Errors::TRANSFER_FAILED);

        let current = self.s_user_collateral.read(caller);
        self.s_user_collateral.write(caller, current + strk_amount);

        let strk_price = self._get_oracle().get_strk_myusd_price();
        self.emit(CollateralAdded { user: caller, amount: strk_amount, price: strk_price });
    }
    ```

    </details>
    </details>

---

2.  **Implement `calculate_collateral_value(user: ContractAddress)`**
    - This function should return the total USD value of the STRK collateral held by a `user`.
    - Use `i_oracle.get_strk_myusd_price()` to get the current price of STRK in MyUSD (it returns price with 1e18 precision).
    - The collateral amount `s_user_collateral[user]` is in wei-style precision (1e18 = 1 STRK).
    - Calculation: `(collateral_amount * strk_price) / PRECISION`.

    <details markdown='1'>
    <summary>💡 Hint: Calculating Collateral Value</summary>

    This function converts STRK to USD value:
    - Get the user's STRK amount from the mapping
    - Get the current STRK price from the oracle
    - Multiply them together and divide by PRECISION

    Think about:
    - Why we need to divide by PRECISION
    - What units the oracle price is in
    - What units the collateral amount is in

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn calculate_collateral_value(self: @ContractState, user: ContractAddress) -> u256 {
        let collateral_amount = self.s_user_collateral.read(user);
        let strk_price = self._get_oracle().get_strk_myusd_price();
        (collateral_amount * strk_price) / PRECISION
    }
    ```

    </details>
    </details>

---

🚀 Go ahead and re-deploy your contracts with `yarn deploy --reset` and test your front-end to see if you can add collateral.

On the right side of the screen you will see a three icon menu. Hover the top icon to make the collateral menu appear.

### 🥅 Goals:

- [ ] Users can send STRK to contract using the `add_collateral` function.
- [ ] `s_user_collateral` correctly tracks the amount of STRK deposited by each user.
- [ ] `calculate_collateral_value` returns the correct USD value of a user's collateral.
- [ ] In the frontend, you should be able to see your address in the left table.

---

## Checkpoint 3: 💰 Interest Calculation System

Now that users can deposit collateral, we need to set up the interest calculation system before we can let them mint MyUSD. This system uses a share-based approach to efficiently track interest accrual. Unlike traditional systems where interest is used as revenue, our stablecoin uses interest rates as a tool to maintain the peg - higher rates discourage borrowing when the price is below $1, helping to destroy demand for loans and pushing the price back up.

> ⚠️ The complexity starts to go up from here so pay close attention.

To handle interest accrual efficiently, we use a **share-based** system. Instead of updating every user's balance when interest accrues, we use two key variables:

- `debt_exchange_rate`: How much MyUSD each share is worth
- `last_update_time`: When we last updated the exchange rate

Here's how it works:

1. When Bob mints 100 MyUSD, he gets 100 shares (1 share = 1 MyUSD initially)
2. After a year at 10% interest:
   - Bob still has 100 shares
   - But each share is now worth 1.1 MyUSD
   - So he owes 110 MyUSD total (100 shares × 1.1 exchange rate)
3. Now if Alice mints 100 MyUSD:
   - She gets 90.91 shares (100 MyUSD ÷ 1.1 exchange rate)
   - These shares are worth 100 MyUSD at the current rate
   - But she won't owe interest on the first year's debt

The exchange rate only updates when the borrow rate changes, and we calculate any new interest based on the time since the last update.

<details markdown='1'>
<summary>💡 Hint: Understanding Shares and Exchange Rate</summary>

Think of shares like a "debt token" that represents a portion of the total debt pool. The exchange rate tells us how much MyUSD each share is worth. As interest accrues, the exchange rate increases, making each share worth more MyUSD. This way, we don't need to update every user's balance - we just update the exchange rate.

</details>

---

Keep in mind, in the absence of decimals we will assume that a borrow rate of 125 is equivalent to a 1.25% annual rate. This will mean we need to divide by 10000 (i.e. 100.00%) any time we have multiplied by the borrow rate.

### ✏️ Tasks:

1.  **Implement `_get_current_exchange_rate()`**
    - Calculate what the `debt_exchange_rate` would be if interest were accrued right now.
    - If `total_debt_shares` is 0, return current `debt_exchange_rate`.
    - Calculate interest based on total debt value and time elapsed. This will require multiplying the total debt by the borrow rate and the time elapsed since the last update but you will need to divide by `SECONDS_PER_YEAR` and 100% (`10000`)
    - Return the current exchange rate which should be the existing exchange rate + interest (in shares, not value _which is what we figured above_)

    <details markdown='1'>
    <summary>💡 Hint: Calculating Current Exchange Rate</summary>

    You need to calculate how much interest has accrued since the last update. Think about:
    - How much time has passed since `last_update_time`
    - What the total debt value is currently (`total_debt_shares` x `debt_exchange_rate`)
    - How much interest that debt has earned at the current `borrow_rate`

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn _get_current_exchange_rate(self: @ContractState) -> u256 {
        let total_shares = self.total_debt_shares.read();
        if total_shares == 0 {
            return self.debt_exchange_rate.read();
        }

        let time_elapsed = starknet::get_block_timestamp() - self.last_update_time.read();
        let borrow_rate = self.borrow_rate.read();

        if time_elapsed == 0 || borrow_rate == 0 {
            return self.debt_exchange_rate.read();
        }

        let current_rate = self.debt_exchange_rate.read();
        let total_debt_value = (total_shares * current_rate) / PRECISION;
        let interest = (total_debt_value * borrow_rate * time_elapsed) / (SECONDS_PER_YEAR * 10000);

        current_rate + (interest * PRECISION) / total_shares
    }
    ```

    </details>
    </details>

---

2.  **Implement `_accrue_interest()`**
    - Update `debt_exchange_rate` using `_get_current_exchange_rate()`.
    - Update `last_update_time` to current timestamp.

    <details markdown='1'>
    <summary>💡 Hint: Accruing Interest</summary>

    This function updates the exchange rate to include accrued interest:
    - Get the new exchange rate
    - Update the stored rate
    - Update the timestamp

    Remember to:
    - Handle the case where there are no debt shares
    - Update both the exchange rate and timestamp
    - Use the helper function we just created (`_get_current_exchange_rate()`)

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn _accrue_interest(ref self: ContractState) {
        let total_shares = self.total_debt_shares.read();
        if total_shares == 0 {
            self.last_update_time.write(starknet::get_block_timestamp());
            return;
        }

        let new_rate = self._get_current_exchange_rate();
        self.debt_exchange_rate.write(new_rate);
        self.last_update_time.write(starknet::get_block_timestamp());
    }
    ```

    </details>
    </details>

---

3.  **Implement `_get_myusd_to_shares(amount: u256)`**
    - Convert a MyUSD `amount` into the equivalent number of `debt_shares`.
    - Use `_get_current_exchange_rate()` to get the current rate.

    <details markdown='1'>
    <summary>💡 Hint: Converting MyUSD to Shares</summary>

    Think about this like a currency conversion:
    - If 1 share = 1.1 MyUSD (exchange rate)
    - Then 100 MyUSD = 100/1.1 shares

    You need to:
    - Get the current exchange rate
    - Use it to calculate how many shares represent the given amount

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn _get_myusd_to_shares(self: @ContractState, amount: u256) -> u256 {
        let current_rate = self._get_current_exchange_rate();
        (amount * PRECISION) / current_rate
    }
    ```

    </details>
    </details>

---

🔍 Nothing material to test on the frontend but you may need to return to these helper methods you just created if something isn't working as expected later.

### 🥅 Goals:

- [ ] Interest accrues correctly based on time elapsed and borrow rate
- [ ] Exchange rate updates properly when interest accrues
- [ ] Shares are calculated correctly based on current exchange rate
- [ ] The system handles edge cases (no shares, zero interest, etc.)

---

## Checkpoint 4: 💰 Minting MyUSD & Position Health

🪙 Now that we have our interest calculation system in place, we can implement the minting functionality. Users should be able to mint MyUSD against their collateral, but we must ensure they don't mint too much, keeping the system over-collateralized. This is where the `COLLATERAL_RATIO` (150%) comes in.

### ✏️ Tasks:

1.  **Implement `get_current_debt_value(user: ContractAddress)`**
    - This function calculates how much MyUSD a user actually owes, including interest.
    - If user has no shares (`s_user_debt_shares[user] == 0`), return 0.
    - Get the current exchange rate using `_get_current_exchange_rate()`.
    - Calculate: `(s_user_debt_shares[user] * current_exchange_rate) / PRECISION`.
    - This represents the total debt value including accrued interest.

    <details markdown='1'>
    <summary>💡 Hint: Calculating Current Debt Value</summary>

    This is the inverse of `_get_myusd_to_shares`:
    - If we know how many shares a user has
    - And we know the current exchange rate
    - We can calculate their total debt value

    Remember to handle the case where a user has no shares!

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn get_current_debt_value(self: @ContractState, user: ContractAddress) -> u256 {
        let user_shares = self.s_user_debt_shares.read(user);
        if user_shares == 0 {
            return 0;
        }

        let current_rate = self._get_current_exchange_rate();
        (user_shares * current_rate) / PRECISION
    }
    ```

    </details>
    </details>

---

2.  **Implement `calculate_position_ratio(user: ContractAddress)`**
    - This function calculates a user's collateralization ratio.
    - Get the user's current debt value using `get_current_debt_value(user)`.
    - Get the user's collateral value using `calculate_collateral_value(user)`.
    - If debt value is 0, return `type(uint256).max` (infinite ratio).
    - Calculate: `(collateral_value * PRECISION) / debt_value`.
    - This ratio must stay above 150% to keep the position safe.

    <details markdown='1'>
    <summary>💡 Hint: Calculating Position Ratio</summary>

    The position ratio is like a health score for a user's position:
    - Higher ratio = safer position
    - Lower ratio = riskier position

    Think about:
    - What happens if someone has no debt?
    - How to handle division by zero
    - Why we need to multiply by `PRECISION` before dividing

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn calculate_position_ratio(self: @ContractState, user: ContractAddress) -> u256 {
        let debt_value = self.get_current_debt_value(user);
        if debt_value == 0 {
            return BoundedInt::max();
        }

        let collateral_value = self.calculate_collateral_value(user);
        (collateral_value * PRECISION) / debt_value
    }
    ```

    </details>
    </details>

---

3.  **Implement `_validate_position(user: ContractAddress)`**
    - This internal view function uses the last function and it reverts if the position is unsafe
    - Get the position ratio using `calculate_position_ratio(user)`.
    - A position is safe if `(position_ratio * 100) >= (COLLATERAL_RATIO * PRECISION)`.
    - If unsafe, revert with `Engine__UnsafePositionRatio()`.

    <details markdown='1'>
    <summary>💡 Hint: Validating Position Safety</summary>

    This is a simple check that uses the position ratio:
    - Get the ratio
    - Compare it to the required ratio (150%)
    - Revert if it's too low

    Remember to handle the precision correctly when comparing!

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn _validate_position(self: @ContractState, user: ContractAddress) {
        let position_ratio = self.calculate_position_ratio(user);
        if (position_ratio * 100) < (COLLATERAL_RATIO * PRECISION) {
            self.emit(Event::Engine__UnsafePositionRatio(Engine__UnsafePositionRatio {}));
        }
    }
    ```

    </details>
    </details>

---

4.  **Implement `mint_myusd(amount: u256)`**
    - Finally get to mint some stablecoin tokens against your collateral!
    - Revert with `Engine__InvalidAmount()` if `amount` is 0.
    - Calculate how many shares this mint amount represents using `_get_myusd_to_shares(amount)`.
    - Update the user's debt shares: `s_user_debt_shares[msg.sender] += shares`.
    - Update total debt shares: `total_debt_shares += shares`.
    - Validate the position is safe using `_validate_position(msg.sender)`.
    - Mint the MyUSD tokens to the user.
    - Emit `DebtSharesMinted` event with the amount and shares.

    <details markdown='1'>
    <summary>💡 Hint: Minting MyUSD</summary>

    This function ties everything together:
    - Convert the mint amount to shares
    - Update the user's and total shares
    - Check if the position is still safe
    - Mint the actual tokens

    Remember to:
    - Check for zero amount
    - Update both share mappings
    - Validate before minting
    - Emit the event

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn mint_myusd(ref self: ContractState, amount: u256) {
        assert(amount > 0, Errors::INVALID_AMOUNT);

        let shares = self._get_myusd_to_shares(amount);
        let caller = starknet::get_caller_address();

        let current_shares = self.s_user_debt_shares.read(caller);
        self.s_user_debt_shares.write(caller, current_shares + shares);

        let current_total_shares = self.total_debt_shares.read();
        self.total_debt_shares.write(current_total_shares + shares);

        self._validate_position(caller);

        let myusd = self._get_myusd();
        let success = myusd.mint_to(caller, amount);
        assert(success, 'mint failed');

        self.emit(Event::DebtSharesMinted(DebtSharesMinted {
            user: caller,
            amount,
            shares
        }));
    }
    ```

    </details>
    </details>

---

🧪 Run `yarn deploy --reset` then go test the minting functionality on the front end. After depositing collateral, hover the mint icon and input the amount of MyUSD you would like to mint.

### 🥅 Goals:

- [ ] Users can mint MyUSD up to the allowed collateralization limit (150%).
- [ ] The share-based system correctly tracks debt including interest.
- [ ] `get_current_debt_value` shows the true amount owed including interest.
- [ ] `calculate_position_ratio` correctly reflects position health.
- [ ] The frontend should allow minting and show the MyUSD balance and position ratio.

---

## Checkpoint 5: 📈 Accruing Interest & Managing Borrow Rates

🛠️ Now let's set up the ability for the rate controller to change the borrow rate.

Whenever the rate is changed we need to "lock-in" all the interest accrued since the last rate change using the `_accrue_interest` method we created in checkpoint 3.

### ✏️ Tasks:

1.  **Implement `set_borrow_rate(new_rate: u256)`**
    - Allow the `i_rate_controller` to change the annual `borrow_rate`.
    - Run `_accrue_interest()` to update the `debt_exchange_rate` and `last_update_time`
    - Update `borrow_rate` and emit the `BorrowRateUpdated` event.

    <details markdown='1'>
    <summary>💡 Hint: Setting Borrow Rate</summary>

    This function lets the rate controller adjust the borrow rate:
    - Check if caller is the rate controller (handled by modifier)
    - Run `_accrue_interest()`
    - Update the rate
    - Emit the event

    Remember to:
    - Use the modifier for access control
    - Emit the event with the new rate

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn set_borrow_rate(ref self: ContractState, new_rate: u256) {
        // Only rate controller can set borrow rate
        let caller = starknet::get_caller_address();
        if caller != self.i_rate_controller.read() {
            self.emit(Event::Engine__Unauthorized(Engine__Unauthorized {}));
            return;
        }

        self._accrue_interest();
        self.borrow_rate.write(new_rate);

        self.emit(Event::BorrowRateUpdated(BorrowRateUpdated { new_rate }));
    }
    ```

    </details>
    </details>

---

🤡 The funny thing about checking that only the rate controller can change the rate is that _anyone_ can use the methods in the `RateController.cairo` contract! We did this so that you can easily change rates from the frontend without having to authorize a specific account.

🧪 Go try it out on the frontend after redeploying with `yarn deploy --reset`. Click the edit icon next to the borrow rate (inside **Rate Controls**) and set a new rate.

### 🥅 Goals:

- [ ] The borrow rate can be updated

---

## Checkpoint 6: 💸 Repaying Debt & Withdrawing Collateral

🔄 Users need to be able to repay their MyUSD debt and withdraw their STRK collateral.

🧮 Since debt is always accruing we have decided to use a method (`repay_up_to`) that allows specifying an arbitrary amount _over_ the debt that is owed so that a user can cancel their debt completely. If we simply made them specify the exact amount they owed, by the time their transaction was included their debt would have accrued more interest and a very small amount would remain unpaid.

### ✏️ Tasks:

1.  **Implement `repay_up_to(amount: u256)`**
    - This function allows a user to repay up to a certain `amount` of their MyUSD debt.
    - First, convert the MyUSD `amount` the user wants to repay into `amount_in_shares` using `_get_myusd_to_shares(amount)`.
    - If `amount_in_shares` is more than the user's `s_user_debt_shares[msg.sender]`, they are trying to repay more than they owe. In this case, we cap the repayment at their actual debt by:
      - Setting `amount_in_shares` to `s_user_debt_shares[msg.sender]`
      - Recalculating the actual MyUSD `amount` to be repaid using `get_current_debt_value(msg.sender)`
    - Check if the user has enough MyUSD balance: `self._get_myusd().balance_of(msg.sender) < amount`. Revert if not.
    - Check if the MyUSD Engine contract has allowance to spend the user's MyUSD: `self._get_myusd().allowance(msg.sender, address(this)) < amount`. Revert if not.
    - Update `s_user_debt_shares[msg.sender]` and `total_debt_shares` by subtracting `amount_in_shares`.
    - Burn the MyUSD from the user: `self._get_myusd().burn_from(msg.sender, amount)`.
    - Emit `DebtSharesBurned`.

    <details markdown='1'>
    <summary>💡 Hint: Repaying Debt</summary>

    This function needs to handle several cases:
    - User wants to repay exactly what they owe
    - User wants to repay more than they owe (we cap at their actual debt)
    - User doesn't have enough balance
    - User hasn't approved enough allowance

    Remember to:
    - Convert MyUSD amount to shares first
    - If user tries to repay more than they owe, cap it at their actual debt
    - Update both user's shares and total shares
    - Burn the correct amount of MyUSD

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn repay_up_to(ref self: ContractState, amount: u256) {
        let caller = starknet::get_caller_address();
        let amount_in_shares = self._get_myusd_to_shares(amount);

        // Check if user has enough debt
        let user_shares = self.s_user_debt_shares.read(caller);
        let mut actual_amount = amount;
        let mut actual_shares = amount_in_shares;

        if amount_in_shares > user_shares {
            // Cap at actual debt
            actual_shares = user_shares;
            actual_amount = self.get_current_debt_value(caller);
        }

        // Check balance
        let myusd = self._get_myusd();
        assert(actual_amount > 0, Errors::INVALID_AMOUNT);
        assert(myusd.balance_of(caller) >= actual_amount, 'insufficient MyUSD');

        // Check allowance
        assert(
            myusd.allowance(caller, starknet::get_contract_address()) >= actual_amount,
            'insufficient allowance'
        );

        // Update shares
        self.s_user_debt_shares.write(caller, user_shares - actual_shares);
        let current_total = self.total_debt_shares.read();
        self.total_debt_shares.write(current_total - actual_shares);

        // Burn MyUSD
        myusd.burn_from(caller, actual_amount);

        self.emit(Event::DebtSharesBurned(DebtSharesBurned {
            user: caller,
            amount: actual_amount,
            shares: actual_shares
        }));
    }
    ```

    </details>
    </details>

---

2.  **Implement `withdraw_collateral(amount: u256)`**
    - Revert with `Errors::INVALID_AMOUNT` if `amount` is 0.
    - Revert with `Errors::INSUFFICIENT_COLLATERAL` if `s_user_collateral[caller] < amount`.
    - Decrease `s_user_collateral[caller]` by `amount`.
    - If the user still has debt (`s_user_debt_shares[caller] > 0`), call `_validate_position(caller)` to ensure they are still safely collateralized _after_ the withdrawal. If not, the `_validate_position` will revert (and because you haven't actually transferred STRK yet, the state change to `s_user_collateral` will also be reverted).
    - If the position is still valid (or they have no debt), transfer the STRK using `strk_dispatcher.transfer(caller, amount)`. Handle potential transfer failure with `Errors::TRANSFER_FAILED`.
    - Emit `CollateralWithdrawn` with the current STRK price.

    <details markdown='1'>
    <summary>💡 Hint: Withdrawing Collateral</summary>

    This function needs to be careful about maintaining the user's position safety:
    - Check if they have enough collateral
    - Reduce their collateral but immediately `_validate_position` to check if they'd still be safe
    - Only transfer STRK if the position remains safe

    Remember to:
    - Handle the case where user has no debt
    - Use the existing position validation function
    - Emit the event with the current price (this is solely for the frontend)

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn withdraw_collateral(ref self: ContractState, amount: u256) {
        let caller = starknet::get_caller_address();

        assert(amount > 0, Errors::INVALID_AMOUNT);

        let current_collateral = self.s_user_collateral.read(caller);
        assert(current_collateral >= amount, Errors::INSUFFICIENT_COLLATERAL);

        // Temporarily reduce collateral to check position
        let new_collateral = current_collateral - amount;
        self.s_user_collateral.write(caller, new_collateral);

        // Validate position after withdrawal
        let user_shares = self.s_user_debt_shares.read(caller);
        if user_shares > 0 {
            self._validate_position(caller);
        }

        // Transfer STRK if position is still valid
        let strk_dispatcher = self._get_strk();
        let success = strk_dispatcher.transfer(caller, amount);
        assert(success, Errors::TRANSFER_FAILED);

        let strk_price = self._get_oracle().get_strk_myusd_price();
        self.emit(Event::CollateralWithdrawn(CollateralWithdrawn {
            withdrawer: caller,
            amount,
            price: strk_price
        }));
    }
    ```

    </details>
    </details>

---

🧪 Go try it out on the frontend! Re-deploy with `yarn deploy --reset` and go try to do the full deposit, mint/borrow, repay, and withdraw workflow.

### 🥅 Goals:

- [ ] Users can repay their MyUSD debt. Their `s_user_debt_shares` should decrease.
- [ ] Users can withdraw their STRK collateral, provided their position remains safe (above 150% collateralization if they have debt).
- [ ] Attempting to withdraw too much collateral leading to an unsafe position should fail.
- [ ] The frontend should reflect these changes.

---

## Checkpoint 7: 🚨 Liquidation - Enforcing System Stability

🛡️ What happens if the price of STRK drops or a user's debt accrues too much interest, causing their position to become less than 150% collateralized? This is where liquidations come in. Anyone can trigger a liquidation for an unsafe position.

⚖️ Liquidations are crucial for maintaining the system's solvency. They ensure that:

1. The system remains over-collateralized at all times
2. Debt is quickly resolved before it becomes "bad debt" (under-collateralized - less than 100% collateralized)
3. Users are incentivized to maintain safe positions

### ✏️ Tasks:

1.  **Implement `is_liquidatable(user: ContractAddress)`**
    - This function checks if a user's position has become unsafe and can be liquidated.
    - Calculate the user's current position ratio using `calculate_position_ratio(user)`. This will automatically use the current exchange rate to get up-to-date debt values.
    - Return `true` if `(position_ratio * 100) < COLLATERAL_RATIO * PRECISION`, otherwise `false`.

    <details markdown='1'>
    <summary>💡 Hint: Checking Liquidation Status</summary>

    This function is very similar logic to `_validate_position` except it only returns a bool instead of reverting.

    Think about:
    - How the position ratio relates to the collateral ratio
    - Why we multiply by 100 and compare with COLLATERAL_RATIO \* PRECISION

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn is_liquidatable(self: @ContractState, user: ContractAddress) -> bool {
        let position_ratio = self.calculate_position_ratio(user);
        (position_ratio * 100) < (COLLATERAL_RATIO * PRECISION)
    }
    ```

    </details>
    </details>

---

2.  **Implement `liquidate(user: ContractAddress)`**
    - This function allows anyone to liquidate an unsafe position by:
      - Paying off the user's debt
      - Receiving their collateral (plus a bonus)
      - Clearing their debt
    - Check if the position is actually liquidatable using `if (!is_liquidatable(user)) revert Engine__NotLiquidatable();`.
    - Get `user_debt_value = get_current_debt_value(user)`.
    - Get `user_collateral = s_user_collateral[user]`.
    - Get `collateral_value = calculate_collateral_value(user)`.
    - The liquidator (`msg.sender`) must pay off the user's debt. Check if liquidator has enough MyUSD: `self._get_myusd().balance_of(msg.sender) < user_debt_value`. Revert if not.
    - Check allowance for the engine to burn liquidator's MyUSD: `self._get_myusd().allowance(msg.sender, address(this)) < user_debt_value`. Revert if not.
    - Burn `user_debt_value` of MyUSD from `msg.sender`: `self._get_myusd().burn_from(msg.sender, user_debt_value)`.
    - Clear the liquidated user's debt: `total_debt_shares -= s_user_debt_shares[user]; s_user_debt_shares[user] = 0;`.
    - Calculate how much of the user's collateral the liquidator receives:
      - `collateral_to_cover_debt = (user_debt_value * user_collateral) / collateral_value;` (This is the amount of STRK collateral that has the same USD value as the debt).
      - `reward_amount = (collateral_to_cover_debt * LIQUIDATOR_REWARD) / 100;`
      - `amount_for_liquidator = collateral_to_cover_debt + reward_amount;`
    - Ensure `amount_for_liquidator` does not exceed `user_collateral`. If it does, cap it at `user_collateral`.
    - Reduce the liquidated user's collateral: `s_user_collateral[user] -= amount_for_liquidator;`.
    - Transfer `amount_for_liquidator` STRK to the liquidator using `strk_dispatcher.transfer(liquidator, amount_for_liquidator)`. Handle potential transfer failure.
    - Emit `Liquidation` event.

    <details markdown='1'>
    <summary>💡 Hint: Liquidating Positions</summary>

    This is the core function that maintains system health:
    - It allows anyone to step in and resolve unsafe positions
    - It ensures the liquidator is compensated for their service
    - It protects the system from accumulating bad debt

    Key considerations:
    - Always accrue interest first to get current debt values
    - Calculate collateral amounts carefully to maintain system solvency
    - Handle edge cases where collateral might not cover the full debt
    - Ensure proper event emission for off-chain monitoring

    <details markdown='1'>
    <summary>🎯 Solution</summary>

    ```cairo
    fn liquidate(ref self: ContractState, user: ContractAddress) {
        if !self.is_liquidatable(user) {
            self.emit(Event::Engine__NotLiquidatable(Engine__NotLiquidatable {}));
            return;
        }

        let liquidator = starknet::get_caller_address();
        let user_debt_value = self.get_current_debt_value(user);
        let user_collateral = self.s_user_collateral.read(user);
        let collateral_value = self.calculate_collateral_value(user);

        // Check liquidator has enough MyUSD
        let myusd = self._get_myusd();
        assert(myusd.balance_of(liquidator) >= user_debt_value, 'insufficient MyUSD');
        assert(
            myusd.allowance(liquidator, starknet::get_contract_address()) >= user_debt_value,
            'insufficient allowance'
        );

        myusd.burn_from(liquidator, user_debt_value);

        // Clear user's debt
        let user_shares = self.s_user_debt_shares.read(user);
        let current_total_shares = self.total_debt_shares.read();
        self.total_debt_shares.write(current_total_shares - user_shares);
        self.s_user_debt_shares.write(user, 0);

        // Calculate collateral for liquidator
        let collateral_to_cover_debt = (user_debt_value * user_collateral) / collateral_value;
        let reward_amount = (collateral_to_cover_debt * LIQUIDATOR_REWARD) / 100;
        let mut amount_for_liquidator = collateral_to_cover_debt + reward_amount;

        if amount_for_liquidator > user_collateral {
            amount_for_liquidator = user_collateral;
        }

        // Update user's collateral
        self.s_user_collateral.write(user, user_collateral - amount_for_liquidator);

        // Transfer STRK to liquidator
        let strk_dispatcher = self._get_strk();
        let success = strk_dispatcher.transfer(liquidator, amount_for_liquidator);
        assert(success, Errors::TRANSFER_FAILED);

        let strk_price = self._get_oracle().get_strk_myusd_price();
        self.emit(Event::Liquidation(Liquidation {
            user,
            liquidator,
            amount_for_liquidator,
            liquidated_user_debt: user_debt_value,
            price: strk_price
        }));
    }
    ```

    </details>
    </details>

---

🏆 The `LIQUIDATOR_REWARD` (10%) incentivizes _anyone_ to monitor the system and liquidate unsafe positions. This creates a market for liquidators who:

- Monitor positions for safety
- Act quickly when positions become unsafe
- Help maintain system health
- Profit from their service

💡 The reward is carefully balanced to:

- Be attractive enough to ensure liquidations happen
- Cover gas costs and provide a reasonable return
- Maintain system solvency

🧪 Re-deploy (`yarn deploy --reset`) and go test everything on the frontend.

- Crank up the Borrow Rate to 1000% or something crazy (this will help us get in a liquidatable position quickly)
- Deposit collateral
- Mint the maximum amount MyUSD (150% of collateral value), including added cents in order to get as close as possible.
- Open a private browser tab to the same page. You should have access to a new burner wallet. Go ahead and give it some STRK by clicking the faucet button (top right).
- Use the **swap** button (in the MyUSD Wallet section) to exchange the STRK for enough MyUSD to pay the debt of your first account. Make sure you get more than the amount of MyUSD they minted because they have already accrued more debt in interest.
- Check if the first account's position is in a liquidatable state. The **Liquidate** button should be enabled.
- Click the button with your second account to liquidate the position.

### 🥅 Goals:

- [ ] `is_liquidatable` should correctly identify positions below the `COLLATERAL_RATIO`.
- [ ] `liquidate` function should allow a third party to repay a risky user's debt and claim their collateral (with a bonus).
- [ ] The liquidated user's debt should be cleared, and their collateral reduced.
- [ ] The liquidator should receive the correct amount of collateral.
- [ ] Test this by creating a position and borrowing the maximum amount possible, then letting interest accrue by setting a high borrow rate.

---

## Checkpoint 8: 🤖 Market Simulation

🧪 Now that we have implemented all the core functionality of our stablecoin system, let's see how it behaves in a simulated market environment. The `yarn simulate` script will run several automated bots that simulate different market participants.

🚀 At first, we will focus on the borrowing aspect. These bot accounts each have a slow trickle of unlimited funds and they want to use it to get leveraged exposure to STRK. They will deposit collateral, then mint some MyUSD. After that they will take their newly minted MyUSD and swap it for more STRK. This will drive the price of MyUSD down since the _only_ market participants are dumping it in favor of STRK.

### 🚀 Running the Simulation:

1. 🟢 Make sure your local network is running (`yarn chain`)
2. 🟢 Deploy your contracts (`yarn deploy --reset`) or at least set the borrow rate back to 0
3. 🟢 Run the simulation: `yarn simulate`

👀 Watch the console output to see:

- Each bot accounts upper borrow rate limit preference
- The activity of each bot

👀 Watch the frontend to see:

- Our precious MyUSD losing its peg!
- The total supply of MyUSD in circulation increasing

💣 Now raise the borrow rate to 30%.

🧠 The bots are having to kiss their sweet low rate goodbye and accept the high interest they are now being charged.

❓ What do you notice?

- Bots are exiting their positions
- Total supply drops significantly
- The peg is restored

🧩 Now this is just a small example of what a very small group of market participants can do to the price of an asset.

❓ Is our stablecoin doomed to either have a very small market cap or lose its peg perpetually? Find out in the next section...

### 🥅 Goals:

- [ ] Successfully run the simulation script
- [ ] Observe bullish market activities effect on the market
- [ ] Understand how the system components interact
- [ ] See how rates influence market behavior

---

## Checkpoint 9: ⚖️ The Other Side: Savings Rate & Market Dynamics

🪙 So far, we've focused on users borrowing MyUSD (which can create sell pressure if they swap MyUSD for STRK). But we saw how that made the stablecoin lose its peg pretty quickly.

🧲 To maintain the $1 peg, we also need mechanisms to create _buy pressure_ for MyUSD. What if we could create an incentive for the market to buy MyUSD instead of just selling it? This is where a **Savings Rate** comes in, managed by the `MyUSDStaking.cairo` contract.

💡 Users can stake their MyUSD into `MyUSDStaking.cairo` to earn yield. This yield (the savings rate) makes holding MyUSD attractive and provides a new incentive _besides leveraged exposure to STRK_ for using MyUSD.

<details markdown='1'>
<summary>Where does the yield come from?</summary>

No MyUSD can exist that is not paying for the borrow rate so <b>as long as the savings rate is less than or equal to the borrow rate this is sustainable</b>. Maybe you are thinking, "What about all the DEX liquidity?". Even this DEX liquidity is just a large borrower who deposited STRK collateral and has a lot of MyUSD borrowed and then supplied it all to the DEX. Technically all of the MyUSD that is accrued from the borrow rate that is not being allocated to stakers should exist <i>somewhere</i> in the system but we decided against adding that to an already complex system. As a result, if everyone (including the DEX liquidity provider) decided to attempt repaying all their debt, they would not be able to do so.

</details>

---

🛡️ Now that we understand where the yield comes from, we need to ensure our system can always pay it. Return to your `set_borrow_rate` function in `MyUSDEngine.cairo` and add a check to ensure the new rate is greater than or equal to the savings rate. This ensures the system can always pay stakers their yield. If the new rate is too low, revert with `Engine__InvalidBorrowRate()`.

<details markdown='1'>
<summary>💡 Hint: Setting Borrow Rate</summary>

The borrow rate must always be high enough to cover the savings rate:

- Get the current savings rate from the staking contract using `i_staking.savings_rate()`
- Compare it with the new borrow rate
- Revert if the borrow rate is too low
- Remember to do this check before accruing interest and updating the rate

<details markdown='1'>
<summary>🎯 Solution</summary>

```cairo
fn set_borrow_rate(ref self: ContractState, new_rate: u256) {
    let current_savings_rate = self.i_staking.read().savings_rate();

    if new_rate < current_savings_rate {
        self.emit(Event::Engine__InvalidBorrowRate(Engine__InvalidBorrowRate {}));
        return;
    }

    self._accrue_interest();
    self.borrow_rate.write(new_rate);

    self.emit(Event::BorrowRateUpdated(BorrowRateUpdated { new_rate }));
}
```

</details>
</details>

---

🧠 For the rest of this checkpoint **you won't need to edit any Cairo**, but you need to understand the interactions.

### 📖 Concepts & Connections:

1.  **`MyUSDStaking.cairo`:** This separate contract (already provided) has a `set_savings_rate(new_rate: u256)` function (callable by its owner, which is also the `RateController` in our setup) and a `savings_rate()` view function. Users would `approve` MyUSD to this contract and call a `stake(amount: u256)` function on it.
2.  **`RateController.cairo`:** This contract (which you can control via the UI) can call:
    - `MyUSDEngine.set_borrow_rate()`
    - `MyUSDStaking.set_savings_rate()`
3.  **Constraint in `MyUSDEngine.set_borrow_rate()`:**
    - Remember the line: `if (new_rate < i_staking.savings_rate()) revert Engine__InvalidBorrowRate();`
    - This implies the `borrow_rate` in your engine should generally be higher than or equal to the `savings_rate` offered by `MyUSDStaking.cairo`. This makes sense: the system needs to earn more from borrowers than it pays out to savers to be sustainable.
4.  **The Levers for Peg Stability:**
    - **High Borrow Rate:** Discourages minting MyUSD (reduces potential sell pressure).
    - **Attractive Savings Rate:** Encourages buying/holding MyUSD to stake it (creates buy pressure).
    - Finding the right balance between these rates is key to keeping MyUSD close to $1. If MyUSD is trading below $1, you might increase the savings rate or increase the borrow rate. If MyUSD is above $1, you might decrease the savings rate or decrease the borrow rate.

### 📖 Understanding:

- In the frontend you can see options to set both the **Borrow Rate** (for `MyUSDEngine`) and the **Savings Rate** (for `MyUSDStaking`).
- The `DEX.cairo` contract provides a simple market where STRK can be swapped for MyUSD. The price on this DEX will reflect the supply and demand for MyUSD.
- Think about how changing the borrow and savings rates would influence users:
  - If savings rate is high, people might buy MyUSD on the DEX to stake it, pushing the price up.
  - If borrow rate is high, people might be less inclined to mint new MyUSD, or might buy MyUSD on the DEX to repay existing loans, reducing sell pressure or creating buy pressure.

### 🥅 Goals:

- [ ] Understand that `MyUSDEngine` and `MyUSDStaking` work together, influenced by rates set via `RateController`.
- [ ] Understand that the savings rate creates an incentive to hold/buy MyUSD.
- [ ] Observe the MyUSD price on the **Price Graph** section of the frontend.

---

## Checkpoint 10: 🤖 Simulation & Finding Equilibrium

🧪 Now for the "Aha!" moment. Let's see how these mechanisms play out with simulated market activity and an automated rate controller.

### 🚀 Running Simulations:

1.  **`yarn simulate` Script:**
    - This script spins up several simulated users (actors).
    - Some actors will look at the `borrow_rate`. If it's attractive, they will deposit STRK and mint MyUSD (potentially selling it on the DEX for more STRK, representing leveraged traders).
    - Other actors will look at the `savings_rate`. If it's attractive, they will buy MyUSD from the DEX and stake it in `MyUSDStaking.cairo`.
    - Run this script from your `challenge-stablecoin` directory: `yarn simulate`.
    - Observe your console and the frontend. You should see activity: collateral deposits, MyUSD mints, stakes, and DEX swaps. The MyUSD price on the DEX will fluctuate.
    - Experiment: Manually set very high or very low borrow/savings rates using the frontend controls (which use `RateController.cairo`) while running `yarn simulate`. How does the MyUSD price react?

2.  **`yarn interest-rate-controller` Script:**
    - This script attempts to automatically adjust the `borrow_rate` (in `MyUSDEngine`) and `savings_rate` (in `MyUSDStaking`) to try and bring the MyUSD price towards $1.
    - It will observe the price and then make decisions:
      - If MyUSD < $1: Try to increase savings rate (make holding MyUSD more attractive) or increase borrow rate (make minting MyUSD less attractive).
      - If MyUSD > $1: Try to decrease savings rate or decrease borrow rate.
    - Run this script: `yarn interest-rate-controller`.
    - Observe its actions in the console and how the MyUSD price on the DEX responds. Does it manage to stabilize the price near $1?
    - It starts in **TEMPERED** mode which just raises the borrow rate until the peg is stabilized. Once this has happened it switches to **GROWTH** mode where it lowers the borrow rate and starts raising the savings rate to make it attractive for users.
    - Click the **Show Rates** button on the price graph to see how the rates changing affects the price historically.
    - The price should find equilibrium where it oscillates near the peg

### 🤔 Key Takeaways:

- **Demand Destruction:** High borrow rates make minting MyUSD expensive, reducing its supply and potential sell pressure. This is one lever.
- **Demand Creation:** Attractive savings rates make holding MyUSD (and thus buying it) desirable, increasing demand and buy pressure. This is the other crucial lever.
- **Dynamic Equilibrium:** The "correct" rates are not fixed; they depend on market conditions and sentiment. This stablecoin system constantly seeks equilibrium by adjusting these incentives.
- **Arbitrary Rates:** The rates are ultimately set by a controller (in our case, `RateController.cairo`, which you can manipulate). Their effectiveness depends on the market's reaction.
- **Market Unpredictability:** We have only simulated two different types of market participants. Imagine what a real market would be like with thousands, maybe even millions, of participants (🤯). All constantly changing as new incentives to buy, sell or hold MyUSD emerge. Also think about how those market demands may change when in a bull market vs bear market.

### 🥅 Goals:

- [ ] Successfully run the `yarn simulate` script and observe market behaviors.
- [ ] Successfully run the `yarn interest-rate-controller` script and observe its attempts to stabilize the MyUSD price.
- [ ] Gain an intuitive understanding of how borrow and savings rates are the primary tools for managing a stablecoin's peg in this type of system.
- [ ] Appreciate that maintaining a peg is an active process of balancing incentives.

---

## Checkpoint 11: 💾 Deploy your contracts! 🛰

Well done on building a stablecoin engine! Now, let's get it on a public testnet.

📡 Edit the `defaultNetwork` to [your choice of public Starknet networks](https://docs.starknet.io/documentation/architecture_and_concepts/Networks/networks/) in `packages/snfoundry/scripts-ts/networks.ts` (e.g., `sepolia`).

🔐 You will need to generate a **deployer address** using `yarn generate`. This creates a mnemonic and saves it locally.

👩‍🚀 Use `yarn account` to view your deployer account balances.

⛽️ You will need to send STRK to your **deployer address** with your wallet, or get it from a public faucet of your chosen network.

🚀 Run `yarn deploy` to deploy your smart contract to a public network (selected in `networks.ts`)

> 💬 Hint: You can set the `defaultNetwork` in `networks.ts` to `sepolia` **OR** you can `yarn deploy --network sepolia`.

---

## Checkpoint 12: 🚢 Ship your frontend! 🚁

✏️ Edit your frontend config in `packages/nextjs/scaffold.config.ts` to change the `targetNetworks` to `chains.sepolia` (or your chosen deployed network).

💻 View your frontend at http://localhost:3000 and verify you see the correct network.

📡 When you are ready to ship the frontend app...

📦 Run `yarn vercel` to package up your frontend and deploy.

> You might need to log in to Vercel first by running `yarn vercel:login`. Once you log in (email, GitHub, etc), the default options should work.

> If you want to redeploy to the same production URL you can run `yarn vercel --prod`. If you omit the `--prod` flag it will deploy it to a preview/test URL.

> Follow the steps to deploy to Vercel. It'll give you a public URL.

> 🦊 Since we have deployed to a public testnet, you will now need to connect using a wallet you own or use a burner wallet. By default 🔥 `burner wallets` are only available on `hardhat` . You can enable them on every chain by setting `onlyLocalBurnerWallet: false` in your frontend config (`scaffold.config.ts` in `packages/nextjs/`)

#### Configuration of Third-Party Services for Production-Grade Apps.

By default, 🏗 Scaffold-Stark 2 provides predefined RPC endpoints. For production-grade applications, it's recommended to obtain your own RPC endpoints to prevent rate limiting issues.

It's recommended to store envs for nextjs in Vercel/system env config for live apps and use .env.local for local testing.

---

## Checkpoint 13: 📜 Contract Verification

Run the `yarn verify --network your_network` command to verify your contracts on Starkscan 🛰.

👉 Search your deployed `MyUSDEngine` contract address on [Sepolia Starkscan](https://sepolia.starkscan.co/) to get the URL you submit to 🏃‍♀️[SpeedRunStark.com](https://speedrunstark.com/).

---

> 🎉 Congratulations on completing the MyUSD Stablecoin Engine Challenge! You've gained valuable insights into the mechanics of decentralized stablecoins.

> 🏃 Head to your next challenge [here](https://speedrunstark.com/).

> 💬 Problems, questions, comments on the stack? Post them to the [🏗 Scaffold-Stark developers chat](https://t.me/+wO3PtlRAreo4MDI9)

## Checkpoint 14: More On Stablecoins

In the case of the original single collateral Dai, MakerDAO was voting weekly to set new rates. Later they overhauled their entire system to allow for multiple collateral types thinking it would increase adoption. Shortly after that, a big shift occurred when they introduced their Peg Stability Module (PSM) which allowed anyone to trade 1 Dai for 1 USDC. This was a controversial change because instead of every Dai being backed by an over-collateralized debt position of assets it was instead reliant on a centralized stablecoin that could be blacklisted at any point.

Other stablecoin systems that match the design we explored here are LUSD(BOLD) and RAI. They both have sets of trade-offs in other areas but you should research to see how they compare to the system you just built! You have high context after building this stablecoin system.
