import {
  deployContract,
  executeDeployCalls,
  deployer,
  exportDeployments,
} from "./deploy-contract";
import { green } from "./helpers/colorize-log";

let your_token: any;
let vendor: any;
const deployScript = async (): Promise<void> => {
  your_token = await deployContract({
    contract: "YourToken",
    constructorArgs: {
      recipient: deployer.address, // In devnet, your deployer.address is by default the first pre-deployed account: 0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691
    },
  });

  // ToDo Checkpoint 2: Uncomment Vendor deploy lines
  // ToDo Checkpoint 2: Add owner to Vendor constructor

  //   vendor = await deployContract({
  //     contract: "Vendor",
  //     constructorArgs: {
  //       strk_token_address:
  //         "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d",
  //       your_token_address: your_token.address,
  //     },
  //   });
};

// ToDo Checkpoint 2: Uncomment transferScript to transfer 1000 GLD tokens to VendorContract
// const transferScript = async (): Promise<void> => {
//   await deployer.execute(
//     [
//       {
//         contractAddress: your_token.address,
//         calldata: [
//           vendor.address,
//           {
//             low: 1_000_000_000_000_000_000_000n, //1000 * 10^18
//             high: 0,
//           },
//         ],
//         entrypoint: "transfer",
//       },
//     ],
//     {
//       maxFee: 1e15,
//       version: 0x3,
//     }
//   );
// };

deployScript()
  .then(() => {
    executeDeployCalls().then(() => {
      exportDeployments();
      // ToDo Checkpoint 2: Uncomment call to `transferScript`
      // transferScript();
    });
    console.log(green("All Setup Done"));
  })
  .catch(console.error);
