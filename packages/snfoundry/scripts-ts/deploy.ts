import { Abi, Contract, constants } from "starknet";
import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
  provider,
} from "./deploy-contract";
import { green } from "./helpers/colorize-log";

import preDeployedContracts from "../../nextjs/contracts/predeployedContracts";

const deployScript = async (): Promise<void> => {
  const { address: diceGameAddr } = await deployContract({
    contract: "DiceGame",
    constructorArgs: {
      strk_token_address:
        "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d",
    },
    options: {
      maxFee: BigInt(5000000000000),
      version: constants.TRANSACTION_VERSION.V3,
    },
  });

  const strkAbi = preDeployedContracts.devnet.Strk.abi as Abi;
  const strkAddress = preDeployedContracts.devnet.Strk.address as `0x${string}`;

  const strkContract = new Contract(strkAbi, strkAddress, deployer);

  // 0.05 Strk
  const strkAmount = 50000000000000000n;

  const tx = await strkContract.populate("transfer", [diceGameAddr, strkAmount]);

  const { transaction_hash: txH } = await deployer.execute(tx, {
    version: constants.TRANSACTION_VERSION.V3,
    maxFee: BigInt(5000000000000),
  });

  const txReceipt = await provider.waitForTransaction(txH);

  // ToDo Checkpoint 2: Deploy RiggedRoll contract
  //   await deployContract({
  //     contract: "RiggedRoll",
  //     constructorArgs: {
  //       dice_game_address: diceGameAddr,
  //       owner: deployer.address,
  //     },
  //   });
};

const main = async (): Promise<void> => {
  try {
    await deployScript();
    await executeDeployCalls();
    exportDeployments();

    console.log(green("All Setup Done!"));
  } catch (err) {
    console.log(err);
    process.exit(1); //exit with error so that non subsequent scripts are run
  }
};

main();
