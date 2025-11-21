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

const DEVNET_RPC_URL = process.env.RPC_URL_DEVNET || "http://127.0.0.1:5050";

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

const mintInitialStrk = async (
  address: string,
  amountInStrk: bigint
): Promise<void> => {
  if (networkName !== "devnet") {
    return;
  }

  const friAmount = amountInStrk * STRK_PRECISION;

  try {
    const response = await fetch(`${DEVNET_RPC_URL}/rpc`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "devnet_mint",
        params: {
          address,
          amount: Number(friAmount),
          unit: "FRI",
        },
        id: 1,
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    if (data.error) {
      throw new Error(data.error.message || "devnet_mint failed");
    }

    console.log(
      green(
        `Minted ${amountInStrk.toString()} STRK to deployer (${address}) via devnet_mint`
      )
    );
  } catch (error) {
    console.warn(
      yellow("Unable to mint initial STRK balance via devnet_mint"),
      error
    );
  }
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
const LIQUIDITY_UNITS = 10_000_000n;
const STRK_COLLATERAL_UNITS = 20_000_000n;
const INITIAL_STRK_MINT = 50_000_000n;

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

  await mintInitialStrk(deployer.address, INITIAL_STRK_MINT);

  // Provide large collateral so the deployer is rarely at risk of liquidation
  // and seed the DEX with meaningful liquidity (similar to Hardhat example)
  const strkCollateralAmount = STRK_COLLATERAL_UNITS * STRK_PRECISION;
  const dexStrkAmount = LIQUIDITY_UNITS * STRK_PRECISION;

  // Determine MyUSD liquidity target based on off-chain STRK price (similar to Hardhat ethPrice)
  const priceFactor =
    cachedStrkPrice !== null
      ? BigInt(Math.max(Math.round(cachedStrkPrice * FLOAT_SCALE), 1))
      : FLOAT_SCALE_BI;

  const myUSDAmount =
    (priceFactor * (LIQUIDITY_UNITS * STRK_PRECISION)) / FLOAT_SCALE_BI;

  console.log(green("Target MyUSD liquidity amount:"), myUSDAmount.toString());

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

  // Initialize DEX only if the deployer received the expected MyUSD amount
  if (confirmedBalance === myUSDAmount) {
    try {
      const tx = await deployer.execute([
        {
          contractAddress: deployedContracts.myusd.address,
          entrypoint: "approve",
          calldata: [deployedContracts.dex.address, ...toUint256(myUSDAmount)],
        },
        {
          contractAddress: DEVNET_STRK_TOKEN,
          entrypoint: "approve",
          calldata: [
            deployedContracts.dex.address,
            ...toUint256(dexStrkAmount),
          ],
        },
        {
          contractAddress: deployedContracts.dex.address,
          entrypoint: "init",
          calldata: [...toUint256(myUSDAmount), ...toUint256(dexStrkAmount)],
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
