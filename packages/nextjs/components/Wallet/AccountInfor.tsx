import Image from "next/image";
import { useState } from "react";
import { ConnectWalletModal } from "./ConnectWalletModal";
import { DisconnectModal } from "./DisconnectModal";
import { WalletAccountModal } from "./WalletAccountModal";
import { useAccount } from "@starknet-react/core";
import { displayAddress } from "~~/utils/utils";
import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import { WrongNetworkDropdown } from "../scaffold-stark/CustomConnectButton/WrongNetworkDropdown";

export const AccountButton = () => {
  const [openAccount, setOpenAccount] = useState(false);
  const [openWallet, setOpenWallet] = useState(false);
  const [openDisconnect, setOpenDisconnect] = useState(false);
  const { address, chainId, status } = useAccount();
  const { targetNetwork } = useTargetNetwork();

  return status == "disconnected" ? (
    <div>
      <div
        className="cursor-pointer text-center md:text-base text-xs"
        onClick={() => setOpenWallet(true)}
      >
        Connect Wallet
      </div>
      <ConnectWalletModal
        title="Connect Wallet"
        isOpen={openWallet}
        onClose={() => setOpenWallet(false)}
      />
    </div>
  ) : chainId !== targetNetwork.id ? (
    <div className="cursor-pointer text-center md:text-base text-xs">
      <WrongNetworkDropdown />
    </div>
  ) : (
    <div className="relative">
      {address && (
        <div
          className="flex items-center gap-2.5 cursor-pointer"
          onClick={() => setOpenAccount(true)}
        >
          <Image
            src={"/homescreen/person.png"}
            alt="icon"
            width={16}
            height={16}
          />
          <p className="text-[15px] mt-1">{displayAddress(address)}</p>
        </div>
      )}
      <WalletAccountModal
        title="Your Account"
        isOpen={openAccount}
        address={address ?? ""}
        onClose={() => setOpenAccount(false)}
        openDisconnect={() => setOpenDisconnect(true)}
      />

      <DisconnectModal
        title="Disconnect"
        isOpen={openDisconnect}
        onClose={() => setOpenDisconnect(false)}
      />
    </div>
  );
};
