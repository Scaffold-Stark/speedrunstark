import { deployContract, deployer, exportDeployments } from "./deploy-contract";

const deployScript = async (): Promise<void> => {
  const { address: diceGameAddr } = await deployContract(null, "DiceGame");

  //  await deployContract(
  //    {
  //    dice_game_address: diceGameAddr,
  //  owner: deployer.address,
  // },
  // "RiggedRoll"
  // );

};

deployScript()
  .then(() => {
    exportDeployments();
    console.log("All Setup Done");
  })
  .catch(console.error);
