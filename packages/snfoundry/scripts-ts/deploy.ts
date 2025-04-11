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
      eth_token_address:
        "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
    },
    options: {
      maxFee: BigInt(5000000000000),
      version: constants.TRANSACTION_VERSION.V3,
    },
  });

  const ethAbi = preDeployedContracts.devnet.Eth.abi as Abi;
  const ethAddress = preDeployedContracts.devnet.Eth.address as `0x${string}`;

  const ethContract = new Contract(ethAbi, ethAddress, deployer);

  // 0.05 Eth
  const ethAmount = 50000000000000000n;

  const tx = await ethContract.populate("transfer", [diceGameAddr, ethAmount]);

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

deployScript()
  .then(async () => {
    await executeDeployCalls();
    exportDeployments();

    console.log(green("All Setup Done"));
  })
  .catch(console.error);
