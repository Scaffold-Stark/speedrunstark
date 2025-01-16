import Image from "next/image";
import { useState } from "react";
import { WalletModal } from "./WalletModal";

export const AccountInfor = () => {
  const [openAccount, setOpenAccount] = useState(false);

  return (
    <div>
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
        <p className="text-[15px]">0xda...ea12</p>
      </div>
      <WalletModal
        title="Your Account"
        isOpen={openAccount}
        onClose={() => setOpenAccount(false)}
      />
    </div>
  );
};
