import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
} from "./deploy-contract";
import { green } from "./helpers/colorize-log";

const deployScript = async (): Promise<void> => {
  const { address: exampleContractAddr } = await deployContract({
    contract: "ExampleExternalContract",
  });
  await deployContract({
    contract: "Staker",
    constructorArgs: {
      strk_contract: '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d',
      external_contract_address: exampleContractAddr,
    },
  });
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
