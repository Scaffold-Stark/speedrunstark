import { deployContract, deployer, exportDeployments,provider } from "./deploy-contract";
const { RpcProvider, Account } = require("starknet-dev");

const deployScript = async (): Promise<void> => {
	const your_token = await deployContract(
    {
      name: "Gold",
      symbol: "GLD",
      fixed_supply: 2_000_000_000_000_000_000_000n, //2000 * 10^18
      recipient: deployer.address,
    },
    "YourToken"
  );

  const vendor = await deployContract(
    {
		eth_token_address: "0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7",
      your_token_address: your_token.address,
      owner: deployer.address,
    },
    "Vendor"
  );
  const provider_v6 = new RpcProvider({
    nodeUrl: provider.nodeUrl,
  });
  const deployer_v6 = new Account(provider_v6, deployer.address, deployer.signer, 1);

  
 //transfer 1000 GLD tokens to VendorContract(ch2)
  await deployer_v6.execute(
    [
      {
        contractAddress: your_token.address,
        calldata: [
          vendor.address,
          {
            low:  1_000_000_000_000_000_000_000n, //1000 * 10^18
            high: 0,
          }
        ],
        entrypoint: "transfer",
      }
    ],
    {
      maxFee: 1e18
    }
  );
};

deployScript()
  .then(() => {
    exportDeployments();
    console.log("All Setup Done");
  })
  .catch(console.error);
