import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
} from "./deploy-contract";

const deployScript = async (): Promise<void> => {
	
  const { address: diceGameAddr } = await deployContract({ owner: deployer.address
  }, "DiceGame");

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
