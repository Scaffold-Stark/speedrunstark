import { deployContract, exportDeployments } from "./deploy-contract";

const deployScript = async (): Promise<void> => {
  const { address: exampleContractAddr } = await deployContract(
    null,
    "ExampleExternalContract"
  );
  await deployContract(
    {
      eth_contract:
        "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
      external_contract_address: exampleContractAddr,
    },
    "Staker"
  );
};

deployScript()
  .then(() => {
    exportDeployments();
    console.log("All Setup Done");
  })
  .catch(console.error);
