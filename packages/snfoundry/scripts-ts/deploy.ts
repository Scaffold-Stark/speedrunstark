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
      eth_contract:
        "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
      external_contract_address: exampleContractAddr,
    },
  });
};

deployScript()
  .then(async () => {
    await executeDeployCalls();
    exportDeployments();

    console.log(green("All Setup Done"));
  })
  .catch(console.error);
