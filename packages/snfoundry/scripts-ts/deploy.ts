import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
  provider,
  networkName,
  assertDeployerDefined,
  assertRpcNetworkActive,
  assertDeployerSignable,
} from "./deploy-contract";
import { green, red, yellow } from "./helpers/colorize-log";

const fetchStrkPrice = async (): Promise<number> => {
  const response = await fetch(
    "https://api.coingecko.com/api/v3/simple/price?ids=starknet&vs_currencies=usd"
  );
  const data = await response.json();
  return data.starknet.usd;
};

const STRK_PRECISION = 1_000_000_000_000_000_000n; // 1e18
const FLOAT_SCALE = 1_000_000; // use 6 decimal places to preserve precision safely
const FLOAT_SCALE_BI = BigInt(FLOAT_SCALE);
const PRECISION_SCALE = STRK_PRECISION / FLOAT_SCALE_BI;

let cachedStrkPrice: number | null = null;

const deployedContracts = {
  myusd: null,
  dex: null,
  oracle: null,
  rateController: null,
  myusdStaking: null,
  myusdEngine: null,
};

const UINT128_MAX = (1n << 128n) - 1n;

const toUint256 = (value: bigint): string[] => {
  const normalized = value < 0n ? 0n : value;
  const low = normalized & UINT128_MAX;
  const high = normalized >> 128n;
  return [low.toString(), high.toString()];
};

const fromUint256 = (felts: string[]): bigint => {
  if (!felts || felts.length === 0) {
    return 0n;
  }
  const low = BigInt(felts[0]);
  const high = felts.length > 1 ? BigInt(felts[1]) : 0n;
  return (high << 128n) + low;
};

/**
 * Deploy a contract using the specified parameters.
 *
 * @example (deploy contract with constructorArgs)
 * const deployScript = async (): Promise<void> => {
 *   await deployContract(
 *     {
 *       contract: "YourContract",
 *       contractName: "YourContractExportName",
 *       constructorArgs: {
 *         owner: deployer.address,
 *       },
 *       options: {
 *         maxFee: BigInt(1000000000000)
 *       }
 *     }
 *   );
 * };
 *
 * @example (deploy contract without constructorArgs)
 * const deployScript = async (): Promise<void> => {
 *   await deployContract(
 *     {
 *       contract: "YourContract",
 *       contractName: "YourContractExportName",
 *       options: {
 *         maxFee: BigInt(1000000000000)
 *       }
 *     }
 *   );
 * };
 *
 *
 * @returns {Promise<void>}
 */
const deployScript = async (): Promise<void> => {
  deployedContracts.myusd = await deployContract({
    contract: "MyUSD",
    constructorArgs: {
      owner: deployer.address,
    },
  });

  deployedContracts.dex = await deployContract({
    contract: "DEX",
    constructorArgs: {
      token_addr: deployedContracts.myusd.address,
    },
  });

  const strkPrice = await fetchStrkPrice();
  cachedStrkPrice = strkPrice;
  deployedContracts.oracle = await deployContract({
    contract: "Oracle",
    constructorArgs: {
      dex_address: deployedContracts.dex.address,
      default_price:
        BigInt(Math.round(strkPrice * FLOAT_SCALE)) * PRECISION_SCALE,
    },
  });

  deployedContracts.rateController = await deployContract({
    contract: "RateController",
  });

  deployedContracts.myusdStaking = await deployContract({
    contract: "MyUSDStaking",
    constructorArgs: {
      owner: deployer.address,
      myusd: deployedContracts.myusd.address,
      rate_controller: deployedContracts.rateController.address,
    },
  });

  deployedContracts.myusdEngine = await deployContract({
    contract: "MyUSDEngine",
    constructorArgs: {
      owner: deployer.address,
      oracle: deployedContracts.oracle.address,
      myusd_address: deployedContracts.myusd.address,
      staking_address: deployedContracts.myusdStaking.address,
      rate_controller: deployedContracts.rateController.address,
    },
  });
};

const initializeContracts = async (): Promise<void> => {
  const initializeCalls = await deployer.execute([
    {
      contractAddress: deployedContracts.myusd.address,
      entrypoint: "set_staking_contract",
      calldata: [deployedContracts.myusdStaking.address],
    },
    {
      contractAddress: deployedContracts.myusd.address,
      entrypoint: "set_engine_contract",
      calldata: [deployedContracts.myusdEngine.address],
    },
    {
      contractAddress: deployedContracts.rateController.address,
      entrypoint: "set_engine_address",
      calldata: [deployedContracts.myusdEngine.address],
    },
    {
      contractAddress: deployedContracts.rateController.address,
      entrypoint: "set_staking_address",
      calldata: [deployedContracts.myusdStaking.address],
    },
    {
      contractAddress: deployedContracts.myusdStaking.address,
      entrypoint: "set_engine",
      calldata: [deployedContracts.myusdEngine.address],
    },
  ]);
  console.log(
    green("Initialize Calls Executed at "),
    initializeCalls.transaction_hash
  );
};

const DEVNET_STRK_TOKEN =
  "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";
const LIQUIDITY_UNITS = 1_000_000n;

const setup = async (): Promise<void> => {
  if (networkName !== "devnet") {
    console.log(green(`Skipping local setup for network ${networkName}`));
    return;
  }

  if (
    !deployedContracts.myusd ||
    !deployedContracts.dex ||
    !deployedContracts.oracle ||
    !deployedContracts.rateController ||
    !deployedContracts.myusdStaking ||
    !deployedContracts.myusdEngine
  ) {
    console.warn(red("Contracts are not fully deployed. Skipping setup."));
    return;
  }

  // - Deposit collateral amount (10 STRK = 10 * 1e18)
  // - Calculate max mintable MyUSD based on collateral and 150% ratio
  // - Mint 90% of max to be safe
  // - Use minted amount for DEX initialization
  const strkCollateralAmount = 10n * STRK_PRECISION; // 10 STRK collateral

  // Get STRK price from oracle to calculate max mintable
  let strkPrice = FLOAT_SCALE_BI; // Default to 1.0 if price not available
  try {
    if (provider) {
      const priceRes = (await provider.callContract({
        contractAddress: deployedContracts.oracle.address,
        entrypoint: "get_strk_myusd_price",
        calldata: [],
      })) as string[] | { result: string[] };
      const priceArray = Array.isArray(priceRes) ? priceRes : priceRes.result;
      strkPrice = fromUint256(priceArray);
      console.log(green("STRK price from oracle:"), strkPrice.toString());
    }
  } catch (error) {
    console.warn(
      yellow("Failed to get STRK price from oracle, using default 1.0"),
      error
    );
  }

  // Calculate max mintable MyUSD based on collateral and 150% ratio
  // Formula: max_debt = (collateral_amount * strk_price * 100) / (COLLATERAL_RATIO * PRECISION)
  // COLLATERAL_RATIO = 150 (150%)
  const COLLATERAL_RATIO = 150n;
  const PRECISION = STRK_PRECISION; // 1e18
  const maxMintableMyUSD =
    (strkCollateralAmount * strkPrice * 100n) / (COLLATERAL_RATIO * PRECISION);

  // Mint 90% of max to be safe (leave some buffer)
  const myUSDAmount = (maxMintableMyUSD * 90n) / 100n;

  console.log(
    green("Calculated max mintable MyUSD:"),
    maxMintableMyUSD.toString()
  );
  console.log(green("Minting MyUSD amount:"), myUSDAmount.toString());

  try {
    const tx = await deployer.execute([
      {
        contractAddress: DEVNET_STRK_TOKEN,
        entrypoint: "approve",
        calldata: [
          deployedContracts.myusdEngine.address,
          ...toUint256(strkCollateralAmount),
        ],
      },
      {
        contractAddress: deployedContracts.myusdEngine.address,
        entrypoint: "add_collateral",
        calldata: toUint256(strkCollateralAmount),
      },
      {
        contractAddress: deployedContracts.myusdEngine.address,
        entrypoint: "mint_myusd",
        calldata: toUint256(myUSDAmount),
      },
    ]);
    await provider?.waitForTransaction(tx.transaction_hash);
    console.log(
      green("Seeded engine with collateral / minted MyUSD"),
      tx.transaction_hash
    );
  } catch (error) {
    console.warn(
      red("Unable to seed engine with collateral / minted MyUSD"),
      error
    );
    return;
  }

  let confirmedBalance = 0n;
  try {
    if (!provider) {
      throw new Error("Provider is undefined");
    }
    const balanceRes = (await provider.callContract({
      contractAddress: deployedContracts.myusd.address,
      entrypoint: "balance_of",
      calldata: [deployer.address],
    })) as string[] | { result: string[] };
    const balanceArray = Array.isArray(balanceRes)
      ? balanceRes
      : balanceRes.result;
    confirmedBalance = fromUint256(balanceArray);
  } catch (error) {
    console.warn(red("Failed to read deployer MyUSD balance"), error);
    return;
  }

  // Initialize DEX with the actual minted MyUSD amount
  if (confirmedBalance > 0n) {
    try {
      // Check deployer's STRK balance
      let deployerStrkBalance = 0n;
      try {
        if (provider) {
          const strkBalanceRes = (await provider.callContract({
            contractAddress: DEVNET_STRK_TOKEN,
            entrypoint: "balance_of",
            calldata: [deployer.address],
          })) as string[] | { result: string[] };
          const strkBalanceArray = Array.isArray(strkBalanceRes)
            ? strkBalanceRes
            : strkBalanceRes.result;
          deployerStrkBalance = fromUint256(strkBalanceArray);
        }
      } catch (error) {
        console.warn(red("Failed to read deployer STRK balance"), error);
      }
      console.log(green("Deployer STRK balance"), deployerStrkBalance);

      // Calculate STRK amount for DEX based on price ratio
      // If 1 STRK = X MyUSD (where X = strkPrice / PRECISION), then for confirmedBalance MyUSD, we need confirmedBalance / X STRK
      // For DEX, we want to maintain the price ratio, so use confirmedBalance worth of STRK
      const actualMyUSDAmount = confirmedBalance;

      // Calculate STRK amount: if price is 1 STRK = 1 MyUSD (strkPrice = PRECISION), use same amount
      // Otherwise adjust based on price: STRK_amount = (MyUSD_amount * PRECISION) / strk_price
      const PRECISION = STRK_PRECISION; // 1e18
      const actualDexStrkAmount =
        strkPrice > 0n
          ? (actualMyUSDAmount * PRECISION) / strkPrice
          : actualMyUSDAmount; // If price is 1:1, use same amount

      // Cap STRK amount to available balance
      const cappedStrkAmount =
        deployerStrkBalance > 0n && deployerStrkBalance < actualDexStrkAmount
          ? deployerStrkBalance
          : actualDexStrkAmount;

      // Adjust MyUSD proportionally if STRK was capped
      const finalMyUSDAmount =
        cappedStrkAmount < actualDexStrkAmount
          ? (actualMyUSDAmount * cappedStrkAmount) / actualDexStrkAmount
          : actualMyUSDAmount;

      console.log(green("Actual DEX STRK amount"), cappedStrkAmount.toString());
      console.log(green("Actual MyUSD amount"), finalMyUSDAmount.toString());

      if (cappedStrkAmount === 0n || finalMyUSDAmount === 0n) {
        console.warn(
          yellow("Insufficient balance for DEX initialization. Skipping.")
        );
        return;
      }

      const tx = await deployer.execute([
        {
          contractAddress: deployedContracts.myusd.address,
          entrypoint: "approve",
          calldata: [
            deployedContracts.dex.address,
            ...toUint256(finalMyUSDAmount),
          ],
        },
        {
          contractAddress: DEVNET_STRK_TOKEN,
          entrypoint: "approve",
          calldata: [
            deployedContracts.dex.address,
            ...toUint256(cappedStrkAmount),
          ],
        },
        {
          contractAddress: deployedContracts.dex.address,
          entrypoint: "init",
          calldata: [
            ...toUint256(finalMyUSDAmount),
            ...toUint256(cappedStrkAmount),
          ],
        },
      ]);
      await provider?.waitForTransaction(tx.transaction_hash);
      console.log(
        green("Initialized local DEX liquidity"),
        tx.transaction_hash
      );
    } catch (error) {
      console.warn(red("DEX initialization failed"), error);
    }
  } else {
    console.warn(
      yellow(
        `Deployer balance (${confirmedBalance}) does not match minted amount (${myUSDAmount}). Skipping DEX init.`
      )
    );
  }

  const contractOwner =
    process.env.CONTRACT_OWNER?.toLowerCase() ?? deployer.address.toLowerCase();
  if (contractOwner !== deployer.address.toLowerCase()) {
    try {
      const tx = await deployer.execute([
        {
          contractAddress: deployedContracts.myusdEngine.address,
          entrypoint: "transfer_ownership",
          calldata: [process.env.CONTRACT_OWNER as string],
        },
        {
          contractAddress: deployedContracts.myusdStaking.address,
          entrypoint: "transfer_ownership",
          calldata: [process.env.CONTRACT_OWNER as string],
        },
      ]);
      console.log(green("Queued ownership transfer"), tx.transaction_hash);
    } catch (error) {
      console.warn(red("Ownership transfer failed"), error);
    }
  }
};

const main = async (): Promise<void> => {
  try {
    assertDeployerDefined();

    await Promise.all([assertRpcNetworkActive(), assertDeployerSignable()]);

    await deployScript();
    await executeDeployCalls();
    await initializeContracts();
    await setup();
    exportDeployments();

    console.log(green("All Setup Done!"));
  } catch (err) {
    if (err instanceof Error) {
      console.error(red(err.message));
    } else {
      console.error(err);
    }
    process.exit(1); //exit with error so that non subsequent scripts are run
  }
};

main();
