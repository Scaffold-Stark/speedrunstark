import Image from "next/image";
import { useState } from "react";
import { ConnectWalletModal } from "./ConnectWalletModal";
import { DisconnectModal } from "./DisconnectModal";
import { WalletAccountModal } from "./WalletAccountModal";
import { useAccount } from "@starknet-react/core";
import { displayAddress } from "~~/utils/utils";

export const AccountButton = () => {
  const [openAccount, setOpenAccount] = useState(false);
  const [openWallet, setOpenWallet] = useState(false);
  const [openDisconnect, setOpenDisconnect] = useState(false);
  const { address } = useAccount();

  return (
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
      {!address ? (
        <div>
          <div className="cursor-pointer" onClick={() => setOpenWallet(true)}>
            Connect Wallet
          </div>
          <ConnectWalletModal
            isOpen={openWallet}
            title="Connect Wallet"
            onClose={() => setOpenWallet(false)}
          />
        </div>
      ) : (
        <WalletAccountModal
          title="Your Account"
          isOpen={openAccount}
          address={address}
          onClose={() => setOpenAccount(false)}
          openDisconnect={() => setOpenDisconnect(true)}
        />
      )}

      <DisconnectModal
        title="Disconnect"
        isOpen={openDisconnect}
        onClose={() => setOpenDisconnect(false)}
      />
    </div>
  );
};
