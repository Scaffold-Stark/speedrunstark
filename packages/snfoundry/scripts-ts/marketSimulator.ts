import chalk from "chalk";
import blessed from "blessed";
import * as contrib from "blessed-contrib";
import { Abi, Account, Call, Contract, RpcProvider } from "starknet";
import { networks } from "./helpers/networks";
import deployedContracts from "../../nextjs/contracts/deployedContracts";

type BurnerAccount = {
  accountAddress: string;
  privateKey: string;
  publicKey: string;
};

type BorrowerProfile = {
  maxBorrowRateBps: number;
  targetDebtRatioBps: number;
};

type StakerProfile = {
  minSavingsRateBps: number;
  stakePortionBps: number;
};

type BorrowerActor = {
  account: Account;
  profile: BorrowerProfile;
  label: string;
};

type StakerActor = {
  account: Account;
  profile: StakerProfile;
  label: string;
};

type ContractArtifact = {
  address: string;
  abi: unknown;
};

type DeploymentAddresses = {
  MyUSD: ContractArtifact;
  DEX: ContractArtifact;
  Oracle: ContractArtifact;
  RateController: ContractArtifact;
  MyUSDStaking: ContractArtifact;
  MyUSDEngine: ContractArtifact;
};

const burnerAccounts: BurnerAccount[] = [
  {
    accountAddress:
      "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
    privateKey: "0x71d7bb07b9a64f6f78ac4c816aff4da9",
    publicKey:
      "0x39d9e6ce352ad4530a0ef5d5a18fd3303c3606a7fa6ac5b620020ad681cc33b",
  },
  {
    accountAddress:
      "0x78662e7352d062084b0010068b99288486c2d8b914f6e2a55ce945f8792c8b1",
    privateKey: "0xe1406455b7d66b1690803be066cbe5e",
    publicKey:
      "0x7a1bb2744a7dd29bffd44341dbd78008adb4bc11733601e7eddff322ada9cb",
  },
  {
    accountAddress:
      "0x49dfb8ce986e21d354ac93ea65e6a11f639c1934ea253e5ff14ca62eca0f38e",
    privateKey: "0xa20a02f0ac53692d144b20cb371a60d7",
    publicKey:
      "0xb8fd4ddd415902d96f61b7ad201022d495997c2dff8eb9e0eb86253e30fabc",
  },
  {
    accountAddress:
      "0x4f348398f859a55a0c80b1446c5fdc37edb3a8478a32f10764659fc241027d3",
    privateKey: "0xa641611c17d4d92bd0790074e34beeb7",
    publicKey:
      "0x5e05d2510c6110bde03df9c1c126a1f592207d78cd9e481ac98540d5336d23c",
  },
  {
    accountAddress:
      "0xd513de92c16aa42418cf7e5b60f8022dbee1b4dfd81bcf03ebee079cfb5cb5",
    privateKey: "0x5b4ac23628a5749277bcabbf4726b025",
    publicKey:
      "0x4708e28e2424381659ea6b7dded2b3aff4b99debfcf6080160a9d098ac2214d",
  },
  {
    accountAddress:
      "0x1e8c6c17efa3a047506c0b1610bd188aa3e3dd6c5d9227549b65428de24de78",
    privateKey: "0x836203aceb0e9b0066138c321dda5ae6",
    publicKey:
      "0x776d33371a98abee91ce60ac04321361565c8623cb612ee9357092da2162f51",
  },
  {
    accountAddress:
      "0x557ba9ef60b52dad611d79b60563901458f2476a5c1002a8b4869fcb6654c7e",
    privateKey: "0x15b5e3013d752c909988204714f1ff35",
    publicKey:
      "0x4236bd1a08ee4bc3288081dfaf2b71d9a6e6e573d1b31a62719db73a88bb55",
  },
  {
    accountAddress:
      "0x3736286f1050d4ba816b4d56d15d80ca74c1752c4e847243f1da726c36e06f",
    privateKey: "0xa56597ba3378fa9e6440ea9ae0cf2865",
    publicKey:
      "0x20b6aad24b5741eb49ed1b00ea78e3657e4d74af47e329f6f9fe489517474db",
  },
  {
    accountAddress:
      "0x4d8bb41636b42d3c69039f3537333581cc19356a0c93904fa3e569498c23ad0",
    privateKey: "0xb467066159b295a7667b633d6bdaabac",
    publicKey:
      "0xc6c2f7833f681c8fe001533e99571f6ff8dec59268792a429a14b5b252f1ad",
  },
  {
    accountAddress:
      "0x4b3f4ba8c00a02b66142a4b1dd41a4dfab4f92650922a3280977b0f03c75ee1",
    privateKey: "0x57b2f8431c772e647712ae93cc616638",
    publicKey:
      "0x374f7fcb50bc2d6b8b7a267f919232e3ac68354ce3eafe88d3df323fc1deb23",
  },
];

const STRK_TOKEN_ADDRESS =
  "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d";
const DEVNET_RPC_URL = process.env.RPC_URL_DEVNET || "http://127.0.0.1:5050";
const PRECISION = 1_000_000_000_000_000_000n;
const UINT128_MAX = (1n << 128n) - 1n;
const BORROWER_COUNT = 5;
const STAKER_COUNT = 5;
const SIMULATION_INTERVAL_MS = 4_000;
const UI_REFRESH_MS = 1_500;
const MIN_STRK_BALANCE = 2_000n * PRECISION;
const BORROWER_COLLATERAL_CHUNK = 1_000n * PRECISION;
const BORROWER_MINT_CHUNK = 400n * PRECISION;
const BORROWER_REPAY_CHUNK = 250n * PRECISION;
const STAKER_SEED_AMOUNT = 300n * PRECISION;
const MIN_STAKE_CHUNK = 50n * PRECISION;

let screen: blessed.Widgets.Screen;
let systemInfoBox: blessed.Widgets.BoxElement;
let borrowersTable: contrib.Widgets.TableElement;
let stakersTable: contrib.Widgets.TableElement;
let activityLog: blessed.Widgets.Log;

const toUint256 = (value: bigint): string[] => {
  const normalized = value < 0n ? 0n : value;
  const low = normalized & UINT128_MAX;
  const high = normalized >> 128n;
  return [low.toString(), high.toString()];
};

const fromUint256 = (felts: string[] | undefined): bigint => {
  if (!felts || felts.length < 2) {
    return 0n;
  }
  const low = BigInt(felts[0]);
  const high = BigInt(felts[1]);
  return (high << 128n) + low;
};

const normalizeHex = (value: string): string => {
  if (!value.startsWith("0x")) {
    return `0x${value}`;
  }
  return value;
};

const formatAmount = (
  value: bigint,
  precision = 18,
  fractionDigits = 3
): string => {
  const decimals = 10n ** BigInt(precision);
  const integer = value / decimals;
  const fraction = value % decimals;
  const padded = fraction.toString().padStart(precision, "0");
  const trimmed = padded.slice(0, fractionDigits);
  return `${integer.toString()}.${trimmed}`;
};

const logActivity = (message: string): void => {
  const timestamp = new Date().toLocaleTimeString();
  if (activityLog) {
    activityLog.log(`[${timestamp}] ${message}`);
    screen.render();
  } else {
    console.log(`[${timestamp}] ${message}`);
  }
};

const initializeUI = (): void => {
  screen = blessed.screen({
    smartCSR: true,
    title: "MyUSD Starknet Simulator",
  });

  screen.key(["escape", "q", "C-c"], () => process.exit(0));

  const grid = new contrib.grid({ rows: 12, cols: 12, screen });

  systemInfoBox = grid.set(0, 0, 2, 12, blessed.box, {
    label: "System Status",
    tags: true,
    border: { type: "line" },
    style: {
      border: { fg: "blue" },
    },
  });

  borrowersTable = grid.set(2, 0, 4, 12, contrib.table, {
    label: "Borrowers",
    keys: false,
    interactive: false,
    columnSpacing: 1,
    columnWidth: [16, 14, 14, 14, 40],
  }) as contrib.Widgets.TableElement;

  stakersTable = grid.set(6, 0, 4, 12, contrib.table, {
    label: "Stakers",
    keys: false,
    interactive: false,
    columnSpacing: 1,
    columnWidth: [16, 14, 14, 14, 40],
  }) as contrib.Widgets.TableElement;

  activityLog = grid.set(10, 0, 2, 12, blessed.log, {
    label: "Activity",
    tags: true,
    scrollable: true,
    border: { type: "line" },
    scrollbar: {
      ch: " ",
      track: {
        bg: "cyan",
      },
      style: {
        inverse: true,
      },
    },
    style: {
      border: { fg: "green" },
    },
  });

  borrowersTable.setData({
    headers: ["Address", "Collateral", "Debt", "Max Rate", "Status"],
    data: [["-", "-", "-", "-", "Loading..."]],
  });

  stakersTable.setData({
    headers: ["Address", "MyUSD", "Staked", "Min Rate", "Status"],
    data: [["-", "-", "-", "-", "Loading..."]],
  });

  screen.render();
};

const loadDeployments = (network: string): DeploymentAddresses => {
  const deployments =
    deployedContracts[network as keyof typeof deployedContracts];
  if (!deployments) {
    throw new Error(`Missing deployments config for network ${network}`);
  }
  const requiredKeys = [
    "MyUSD",
    "DEX",
    "Oracle",
    "RateController",
    "MyUSDStaking",
    "MyUSDEngine",
  ] as const;

  for (const key of requiredKeys) {
    if (!(key in deployments)) {
      throw new Error(`Deployment for ${key} not found on ${network}`);
    }
  }

  return deployments as DeploymentAddresses;
};

const waitForTx = async (
  provider: RpcProvider,
  hash: string,
  label: string
): Promise<void> => {
  await provider.waitForTransaction(hash);
  logActivity(`${label} tx: ${hash}`);
};

const devnetMint = async (
  address: string,
  amountWei: bigint
): Promise<void> => {
  if (amountWei <= 0n) {
    return;
  }

  const friAmount = Number(amountWei);
  if (!Number.isFinite(friAmount)) {
    throw new Error("Amount too large to mint via devnet");
  }
  const body = {
    jsonrpc: "2.0",
    method: "devnet_mint",
    params: {
      address,
      amount: friAmount,
      unit: "FRI",
    },
    id: 1,
  };

  try {
    const response = await fetch(`${DEVNET_RPC_URL}/rpc`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      throw new Error(`Mint failed with status ${response.status}`);
    }
    logActivity(`Minted STRK to ${address.slice(0, 8)}...`);
  } catch (error) {
    logActivity(`Unable to mint STRK for ${address.slice(0, 8)}... ${error}`);
  }
};

const readErc20Balance = async (
  provider: RpcProvider,
  contractAddress: string,
  user: string
): Promise<bigint> => {
  const res = await provider.callContract({
    contractAddress,
    entrypoint: "balance_of",
    calldata: [normalizeHex(user)],
  });
  const felts = Array.isArray(res) ? res : (res as { result: string[] }).result;
  return fromUint256(felts);
};

const callUint256View = async (
  provider: RpcProvider,
  contractAddress: string,
  entrypoint: string,
  calldata: string[] = []
): Promise<bigint> => {
  const res = await provider.callContract({
    contractAddress,
    entrypoint,
    calldata,
  });
  const felts = Array.isArray(res) ? res : (res as { result: string[] }).result;
  return fromUint256(felts);
};

const getStrkPrice = async (
  provider: RpcProvider,
  oracleAddress: string
): Promise<bigint> =>
  callUint256View(provider, oracleAddress, "get_strk_myusd_price", []);

const ensureStrkBalance = async (
  provider: RpcProvider,
  account: Account
): Promise<void> => {
  const balance = await readErc20Balance(
    provider,
    STRK_TOKEN_ADDRESS,
    account.address
  );
  if (balance >= MIN_STRK_BALANCE) {
    return;
  }
  const topUp = MIN_STRK_BALANCE - balance;
  await devnetMint(account.address, topUp);
  logActivity(
    `Minted ${formatAmount(topUp)} STRK to ${account.address.slice(0, 8)}...`
  );
};

const makeBorrowerActors = (accounts: Account[]): BorrowerActor[] =>
  accounts.slice(0, BORROWER_COUNT).map((account, idx) => ({
    account,
    profile: {
      maxBorrowRateBps: 800 + idx * 150,
      targetDebtRatioBps: 3500 + idx * 400,
    },
    label: `B${idx + 1}`,
  }));

const makeStakerActors = (accounts: Account[]): StakerActor[] =>
  accounts
    .slice(BORROWER_COUNT, BORROWER_COUNT + STAKER_COUNT)
    .map((account, idx) => ({
      account,
      profile: {
        minSavingsRateBps: 200 + idx * 120,
        stakePortionBps: 6000 + idx * 300,
      },
      label: `S${idx + 1}`,
    }));

const approveAndCall = async (
  account: Account,
  provider: RpcProvider,
  calls: Call[],
  label: string
): Promise<void> => {
  const tx = await account.execute(calls);
  await waitForTx(provider, tx.transaction_hash, label);
};

const seedBorrower = async (
  borrower: BorrowerActor,
  provider: RpcProvider,
  engineAddress: string,
  oracleAddress: string
): Promise<void> => {
  const strkPrice = await getStrkPrice(provider, oracleAddress);
  const collateralValue = (BORROWER_COLLATERAL_CHUNK * strkPrice) / PRECISION;
  const safeMintCap = (collateralValue * 2n) / 3n;
  const mintAmount =
    safeMintCap === 0n
      ? 0n
      : safeMintCap < BORROWER_MINT_CHUNK
      ? safeMintCap
      : BORROWER_MINT_CHUNK;

  const calls: Call[] = [
    {
      contractAddress: STRK_TOKEN_ADDRESS,
      entrypoint: "approve",
      calldata: [engineAddress, ...toUint256(BORROWER_COLLATERAL_CHUNK)],
    },
    {
      contractAddress: engineAddress,
      entrypoint: "add_collateral",
      calldata: [...toUint256(BORROWER_COLLATERAL_CHUNK)],
    },
  ];

  if (mintAmount > 0n) {
    calls.push({
      contractAddress: engineAddress,
      entrypoint: "mint_myusd",
      calldata: [...toUint256(mintAmount)],
    });
  }

  try {
    await approveAndCall(
      borrower.account,
      provider,
      calls,
      `${borrower.label} seed`
    );
  } catch (error) {
    logActivity(`${borrower.label} seed failed: ${(error as Error).message}`);
  }
};

const seedStakerBalances = async (
  source: Account | undefined,
  provider: RpcProvider,
  stakers: StakerActor[],
  myusdAddress: string
): Promise<void> => {
  if (!source) {
    logActivity("No deployer account available. Skipping staker seeding.");
    return;
  }

  const balance = await readErc20Balance(
    provider,
    myusdAddress,
    source.address
  );

  const required = BigInt(stakers.length) * STAKER_SEED_AMOUNT;
  if (balance < required) {
    logActivity(
      `Deployer has insufficient MyUSD (${formatAmount(
        balance
      )}). Needed ${formatAmount(required)}.`
    );
    return;
  }

  for (const staker of stakers) {
    const calls: Call[] = [
      {
        contractAddress: myusdAddress,
        entrypoint: "transfer",
        calldata: [
          normalizeHex(staker.account.address),
          ...toUint256(STAKER_SEED_AMOUNT),
        ],
      },
    ];

    try {
      await approveAndCall(source, provider, calls, `${staker.label} seed`);
    } catch (error) {
      logActivity(
        `${staker.label} seed transfer failed: ${(error as Error).message}`
      );
    }
  }
};

const describeBorrower = (
  debtRatioBps: number,
  borrowRate: number,
  profile: BorrowerProfile
): string => {
  if (borrowRate > profile.maxBorrowRateBps) {
    return "{yellow-fg}Rates high, pausing";
  }
  if (debtRatioBps > profile.targetDebtRatioBps + 800) {
    return "{red-fg}Reducing debt";
  }
  if (debtRatioBps < profile.targetDebtRatioBps - 600) {
    return "{green-fg}Room to borrow";
  }
  return "{cyan-fg}Balanced";
};

const describeStaker = (
  savingsRate: number,
  profile: StakerProfile,
  hasStake: boolean
): string => {
  if (savingsRate < profile.minSavingsRateBps) {
    return hasStake
      ? "{yellow-fg}Yield low, exiting"
      : "{gray-fg}Waiting for rate";
  }
  return hasStake ? "{green-fg}Compounding" : "{cyan-fg}Ready to stake";
};

const simulateBorrowerStep = async (
  borrower: BorrowerActor,
  provider: RpcProvider,
  engine: Contract,
  myusdAddress: string,
  borrowRateBps: number,
  strkPrice: bigint,
  oracleAddress: string
): Promise<void> => {
  try {
    const normalizedAddress = normalizeHex(borrower.account.address);
    const collateral = await callUint256View(
      provider,
      engine.address,
      "get_user_collateral",
      [normalizedAddress]
    );
    const debt = await callUint256View(
      provider,
      engine.address,
      "get_current_debt_value",
      [normalizedAddress]
    );

    if (collateral === 0n) {
      await seedBorrower(borrower, provider, engine.address, oracleAddress);
      return;
    }

    const collateralValue = (collateral * strkPrice) / PRECISION;
    const maxDebt = (collateralValue * 2n) / 3n;
    const debtRatioBps =
      collateralValue === 0n ? 0n : (debt * 10_000n) / collateralValue;

    if (borrowRateBps > borrower.profile.maxBorrowRateBps && debt > 0n) {
      await repayBorrowerChunk(borrower, provider, engine, myusdAddress, debt);
      return;
    }

    if (
      debtRatioBps < BigInt(borrower.profile.targetDebtRatioBps - 400) &&
      debt < maxDebt
    ) {
      const available = maxDebt > debt ? maxDebt - debt : 0n;
      const mintAmount =
        available < BORROWER_MINT_CHUNK ? available : BORROWER_MINT_CHUNK;
      if (mintAmount > 0n) {
        const tx = await borrower.account.execute([
          {
            contractAddress: engine.address,
            entrypoint: "mint_myusd",
            calldata: [...toUint256(mintAmount)],
          },
        ]);
        await waitForTx(
          provider,
          tx.transaction_hash,
          `${borrower.label} mint`
        );
      }
      return;
    }

    if (
      debtRatioBps > BigInt(borrower.profile.targetDebtRatioBps + 600) &&
      debt > 0n
    ) {
      await repayBorrowerChunk(borrower, provider, engine, myusdAddress, debt);
    }
  } catch (error) {
    logActivity(`${borrower.label} step failed: ${(error as Error).message}`);
  }
};

const repayBorrowerChunk = async (
  borrower: BorrowerActor,
  provider: RpcProvider,
  engine: Contract,
  myusdAddress: string,
  debt: bigint
): Promise<void> => {
  const myusdBalance = await readErc20Balance(
    provider,
    myusdAddress,
    borrower.account.address
  );
  if (myusdBalance === 0n) {
    return;
  }
  const repayAmount = [BORROWER_REPAY_CHUNK, debt, myusdBalance].reduce(
    (a, b) => (a < b ? a : b)
  );
  if (repayAmount === 0n) {
    return;
  }

  const calls: Call[] = [
    {
      contractAddress: myusdAddress,
      entrypoint: "approve",
      calldata: [engine.address, ...toUint256(repayAmount)],
    },
    {
      contractAddress: engine.address,
      entrypoint: "repay_up_to",
      calldata: [...toUint256(repayAmount)],
    },
  ];

  try {
    await approveAndCall(
      borrower.account,
      provider,
      calls,
      `${borrower.label} repay`
    );
  } catch (error) {
    logActivity(`${borrower.label} repay failed: ${(error as Error).message}`);
  }
};

const simulateStakerStep = async (
  staker: StakerActor,
  provider: RpcProvider,
  staking: Contract,
  myusdAddress: string,
  savingsRateBps: number
): Promise<void> => {
  try {
    const myusdBalance = await readErc20Balance(
      provider,
      myusdAddress,
      staker.account.address
    );

    const shares = await callUint256View(
      provider,
      staking.address,
      "get_user_shares",
      [normalizeHex(staker.account.address)]
    );

    if (savingsRateBps < staker.profile.minSavingsRateBps && shares > 0n) {
      try {
        const tx = await staker.account.execute([
          {
            contractAddress: staking.address,
            entrypoint: "withdraw",
            calldata: [],
          },
        ]);
        await waitForTx(
          provider,
          tx.transaction_hash,
          `${staker.label} withdraw`
        );
      } catch (error) {
        logActivity(
          `${staker.label} withdraw failed: ${(error as Error).message}`
        );
      }
      return;
    }

    if (
      savingsRateBps >= staker.profile.minSavingsRateBps &&
      myusdBalance >= MIN_STAKE_CHUNK
    ) {
      const portion =
        (myusdBalance *
          BigInt(Math.min(staker.profile.stakePortionBps, 10000))) /
        10_000n;
      if (portion === 0n) {
        return;
      }
      const calls: Call[] = [
        {
          contractAddress: myusdAddress,
          entrypoint: "approve",
          calldata: [staking.address, ...toUint256(portion)],
        },
        {
          contractAddress: staking.address,
          entrypoint: "stake",
          calldata: [...toUint256(portion)],
        },
      ];
      try {
        await approveAndCall(
          staker.account,
          provider,
          calls,
          `${staker.label} stake`
        );
      } catch (error) {
        logActivity(
          `${staker.label} stake failed: ${(error as Error).message}`
        );
      }
    }
  } catch (error) {
    logActivity(`${staker.label} step failed: ${(error as Error).message}`);
  }
};

const updateUI = async (
  provider: RpcProvider,
  dex: Contract,
  engine: Contract,
  staking: Contract,
  borrowers: BorrowerActor[],
  stakers: StakerActor[],
  myusdAddress: string
): Promise<void> => {
  try {
    const [price, borrowRateBig, savingsRateBig] = await Promise.all([
      callUint256View(provider, dex.address, "current_price"),
      callUint256View(provider, engine.address, "borrow_rate"),
      callUint256View(provider, staking.address, "savings_rate"),
    ]);
    const borrowRate = Number(borrowRateBig);
    const savingsRate = Number(savingsRateBig);

    systemInfoBox.setContent(
      `STRK Price: {yellow-fg}${formatAmount(price)} MyUSD{/yellow-fg} | ` +
        `Borrow Rate: {magenta-fg}${(borrowRate / 100).toFixed(
          2
        )}%{/magenta-fg} | ` +
        `Savings Rate: {cyan-fg}${(savingsRate / 100).toFixed(2)}%{/cyan-fg}`
    );

    const borrowerRows: string[][] = [];
    for (const borrower of borrowers) {
      const normalized = normalizeHex(borrower.account.address);
      const [collateral, debt] = await Promise.all([
        callUint256View(provider, engine.address, "get_user_collateral", [
          normalized,
        ]),
        callUint256View(provider, engine.address, "get_current_debt_value", [
          normalized,
        ]),
      ]);
      const collateralValue = (collateral * price) / PRECISION;
      const ratio =
        collateralValue === 0n ? 0 : Number((debt * 10_000n) / collateralValue);
      borrowerRows.push([
        borrower.account.address.slice(0, 10),
        formatAmount(collateral),
        formatAmount(debt),
        `${(borrower.profile.maxBorrowRateBps / 100).toFixed(1)}%`,
        describeBorrower(ratio, borrowRate, borrower.profile),
      ]);
    }

    borrowersTable.setData({
      headers: ["Address", "Collateral", "Debt", "Max Rate", "Status"],
      data: borrowerRows,
    });

    const stakerRows: string[][] = [];
    for (const staker of stakers) {
      const normalized = normalizeHex(staker.account.address);
      const [balance, shares] = await Promise.all([
        readErc20Balance(provider, myusdAddress, staker.account.address),
        callUint256View(provider, staking.address, "get_user_shares", [
          normalized,
        ]),
      ]);
      stakerRows.push([
        staker.account.address.slice(0, 10),
        formatAmount(balance),
        formatAmount(shares),
        `${(staker.profile.minSavingsRateBps / 100).toFixed(1)}%`,
        describeStaker(savingsRate, staker.profile, shares > 0n),
      ]);
    }

    stakersTable.setData({
      headers: ["Address", "MyUSD", "Staked", "Min Rate", "Status"],
      data: stakerRows,
    });

    screen.render();
  } catch (error) {
    logActivity(`UI refresh error: ${(error as Error).message}`);
  }
};

const main = async (): Promise<void> => {
  const networkName = process.env.NETWORK || process.argv[2] || "devnet";
  const network = networks[networkName as keyof typeof networks];
  if (!network?.provider) {
    throw new Error(`Provider not configured for ${networkName}`);
  }

  initializeUI();
  logActivity(`Connecting to ${networkName}`);

  const deployments = loadDeployments(networkName);
  const provider = network.provider;
  const deployer = network.deployer;

  const engineInfo = deployments.MyUSDEngine;
  const dexInfo = deployments.DEX;
  const stakingInfo = deployments.MyUSDStaking;
  const myusdInfo = deployments.MyUSD;
  const oracleInfo = deployments.Oracle;

  if (!engineInfo || !dexInfo || !stakingInfo || !myusdInfo || !oracleInfo) {
    throw new Error(
      `Missing contract addresses in deployedContracts for ${networkName}`
    );
  }

  const engine = new Contract({
    abi: engineInfo.abi as Abi,
    address: engineInfo.address,
    providerOrAccount: provider,
  });
  const dex = new Contract({
    abi: dexInfo.abi as Abi,
    address: dexInfo.address,
    providerOrAccount: provider,
  });
  const staking = new Contract({
    abi: stakingInfo.abi as Abi,
    address: stakingInfo.address,
    providerOrAccount: provider,
  });
  const myusd = new Contract({
    abi: myusdInfo.abi as Abi,
    address: myusdInfo.address,
    providerOrAccount: provider,
  });

  const selectedAccounts = burnerAccounts
    .slice(0, BORROWER_COUNT + STAKER_COUNT)
    .map(
      (accountData) =>
        new Account({
          provider,
          address: accountData.accountAddress,
          signer: accountData.privateKey,
          cairoVersion: "1",
        })
    );

  for (const account of selectedAccounts) {
    await ensureStrkBalance(provider, account);
  }

  const borrowers = makeBorrowerActors(selectedAccounts);
  const stakers = makeStakerActors(selectedAccounts);

  for (const borrower of borrowers) {
    await seedBorrower(borrower, provider, engine.address, oracleInfo.address);
  }
  await seedStakerBalances(deployer, provider, stakers, myusd.address);

  logActivity("Simulation initialized");

  setInterval(async () => {
    try {
      const [borrowRateBig, strkPrice] = await Promise.all([
        callUint256View(provider, engine.address, "borrow_rate"),
        getStrkPrice(provider, oracleInfo.address),
      ]);
      const borrowRate = Number(borrowRateBig);
      for (const borrower of borrowers) {
        await simulateBorrowerStep(
          borrower,
          provider,
          engine,
          myusd.address,
          borrowRate,
          strkPrice,
          oracleInfo.address
        );
      }
      const savingsRate = Number(
        await callUint256View(provider, staking.address, "savings_rate")
      );
      for (const staker of stakers) {
        await simulateStakerStep(
          staker,
          provider,
          staking,
          myusd.address,
          savingsRate
        );
      }
    } catch (error) {
      logActivity(`Simulation tick error: ${(error as Error).message}`);
    }
  }, SIMULATION_INTERVAL_MS);

  setInterval(() => {
    updateUI(provider, dex, engine, staking, borrowers, stakers, myusd.address);
  }, UI_REFRESH_MS);

  logActivity("Press q to exit.");
};

main().catch((error) => {
  console.error(chalk.red(error));
  process.exit(1);
});
