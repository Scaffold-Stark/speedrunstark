import React from "react";
import { LanguageButton } from "./Language/LanguageButton";
import { AccountButton } from "./Wallet/AccountInfor";
import Image from "next/image";

export const Header = () => {
  return (
    <div className="bg-[#4D58FF] md:px-6 md:py-4 px-2 py-3 flex justify-between relative z-50">
      <div>
        <div onClick={() => (window.location.href = "/")}>
          <Image
            src={"/homescreen/starknet-logo.svg"}
            alt="logo"
            width={120}
            height={28}
          />
        </div>
      </div>
      <div className="flex items-center md:gap-6 gap-2">
        <LanguageButton />
        <AccountButton />
      </div>
    </div>
  );
};
