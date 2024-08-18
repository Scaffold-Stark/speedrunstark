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
      recipient: deployer.address, // ~~~YOUR FRONTEND ADDRESS HERE~~~~
    },
  });

  // ToDo Checkpoint 2:: Uncomment Vendor deploy lines
  // vendor = await deployContract({
  //  contract: "Vendor",
  //  constructorArgs: {
  //    eth_token_address:
  //     "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
  //    your_token_address: your_token.address,

  // ToDo Checkpoint 2: Add owner address, should be the same as `deployer.address`
  // },
  //});
};

// ToDo Checkpoint 2: Uncomment to `transfer` 1000 tokens to vendor address.
// const transferScript = async (): Promise<void> => {
//transfer 1000 GLD tokens to VendorContract
//  await deployer.execute(
//    [
//      {
//       contractAddress: your_token.address,
//     calldata: [
//     vendor.address,
//   {
//       low: 1_000_000_000_000_000_000_000n, //1000 * 10^18
//       high: 0,
//        },
//      ],
//     entrypoint: "transfer",
//   },
// ],
// {
//  maxFee: 1e18,
//    }
// );
// };

deployScript()
  .then(() => {
    executeDeployCalls().then(() => {
      exportDeployments();
      // ToDo Checkpoint 2: Uncomment `transferScript`.
      // transferScript();
    });
    console.log(green("All Setup Done"));
  })
  .catch(console.error);
