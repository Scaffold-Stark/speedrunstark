import { Abi, Contract, TransactionStatus } from "starknet";
import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
  provider,
} from "./deploy-contract";

import preDeployedContracts from "../../nextjs/contracts/predeployedContracts";

const deployScript = async (): Promise<void> => {
  const { address: diceGameAddr } = await deployContract(
    { owner: deployer.address },
    "DiceGame"
  );
  const ethAbi = preDeployedContracts.devnet.Eth.abi as Abi;
  const ethAddress = preDeployedContracts.devnet.Eth.address as `0x${string}`;

  const ethContract = new Contract(ethAbi, ethAddress, deployer);

  const tx = await ethContract.invoke("transfer", [diceGameAddr, 1000000000n]);
  const receipt = await provider.waitForTransaction(tx.transaction_hash);

  await deployContract(
    {
      dice_game_address: diceGameAddr,
      owner: deployer.address,
    },
    "RiggedRoll"
  );
};

deployScript()
  .then(() => {
    executeDeployCalls().then(() => {
      exportDeployments();
    });
    console.log("All Setup Done");
  })
  .catch(console.error);
