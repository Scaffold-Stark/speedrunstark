import {
  deployContract,
  executeDeployCalls,
  deployer,
  exportDeployments,
} from "./deploy-contract";

let your_token: any;
let vendor: any;
const deployScript = async (): Promise<void> => {
  your_token = await deployContract(
    {
      recipient: deployer.address, // ~~~YOUR FRONTEND ADDRESS HERE~~~~
    },
    "YourToken"
  );

  // Todo: Uncomment Vendor deploy lines
  //   vendor = await deployContract(
  //     {
  //       eth_token_address:
  //         "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
  //       your_token_address: your_token.address,
  //     // Todo: Add owner address, should be the same as `deployer.address`
  //     },
  //     "Vendor"
  //   );
  // };

  // const transferScript = async (): Promise<void> => {
  // //transfer 1000 GLD tokens to VendorContract
  // await deployer.execute(
  // 	[
  // 	  {
  // 		contractAddress: your_token.address,
  // 		calldata: [
  // 		  vendor.address,
  // 		  {
  // 			low: 1_000_000_000_000_000_000_000n, //1000 * 10^18
  // 			high: 0,
  // 		  },
  // 		],
  // 		entrypoint: "transfer",
  // 	  },
  // 	],
  // 	{
  // 	  maxFee: 1e18,
  // 	}
  //   );
};

deployScript()
  .then(() => {
    executeDeployCalls().then(() => {
      exportDeployments();
      //transferScript();
    });
    console.log("All Setup Done");
  })
  .catch(console.error);
