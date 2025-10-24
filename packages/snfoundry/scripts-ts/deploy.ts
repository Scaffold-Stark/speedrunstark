import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
  assertDeployerDefined,
  assertRpcNetworkActive,
  assertDeployerSignable,
} from "./deploy-contract";
import { green } from "./helpers/colorize-log";

const deployScript = async (): Promise<void> => {
  // 	await deployContract({
  // 	  contract: "MultisigWallet",
  // 	  constructorArgs: {
  // 		quorum: 1,
  // 		signers: [
  // 		  deployer.address,
  // 		  "0x078662e7352d062084b0010068b99288486c2d8b914f6e2a55ce945f8792c8b1",
  // 		],
  // 	  },
  // 	},
  // );

  await deployContract({
    contract: "CustomMultisigWallet",
    constructorArgs: {
      quorum: 1,
      signer: deployer.address,
    },
  });
};

const main = async (): Promise<void> => {
  try {
    assertDeployerDefined();

    await Promise.all([assertRpcNetworkActive(), assertDeployerSignable()]);

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
