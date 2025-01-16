import Image from "next/image";
import { useState } from "react";
import { ConnectWalletModal } from "./ConnectWalletModal";
import { DisconnectModal } from "./DisconnectModal";
import { WalletAccountModal } from "./WalletAccountModal";

export const AccountButton = () => {
  const [openAccount, setOpenAccount] = useState(false);
  const [openWallet, setOpenWallet] = useState(false);
  const [openDisconnect, setOpenDisconnect] = useState(false);

  return (
    <div className="relative">
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
        <p className="text-[15px] mt-1">0xda...ea12</p>
      </div>
      <div className="cursor-pointer" onClick={() => setOpenWallet(true)}>
        Connect Wallet
      </div>
      <ConnectWalletModal
        isOpen={openWallet}
        title="Connect Wallet"
        onClose={() => setOpenWallet(false)}
      />
      <WalletAccountModal
        title="Your Account"
        isOpen={openAccount}
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
