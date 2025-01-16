import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { useState } from "react";
import { DATA_WALLET } from "~~/mockup/data";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

const ItemWallet = ({
  name,
  icon,
  isActive,
  onClick,
}: {
  name: string;
  icon: string;
  isActive: boolean;
  onClick: () => void;
}) => {
  return (
    <div
      className={`flex flex-col items-center gap-2 p-4 cursor-pointer ${isActive ? "bg-[#E9EAF7]" : ""}`}
      onClick={onClick}
    >
      <Image src={icon} alt="icon" width={54} height={54} />
      <p className="capitalize text-[#0C0C4F] text-center">
        {name} <br />
        Wallet
      </p>
    </div>
  );
};

export const ConnectWalletModal = ({ isOpen, onClose, title }: Props) => {
  const [selectedWallet, setSelectedWallet] = useState<string>("");

  const handleCloseModal = () => {
    onClose();
  };

  const handleSelectWallet = (walletName: string) => {
    setSelectedWallet(walletName);
  };

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`w-[320px] mx-auto p-[1px] rounded-none bg-white`}
    >
      <div className="bg-[#4D58FF] relative h-[60px] flex items-center justify-center">
        <Image
          src="/homescreen/header-decore.svg"
          alt="icon"
          width={230}
          height={40}
          className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
        />

        <div className="flex items-center gap-1.5 absolute z-30 left-4">
          <CloseIcon onClose={handleCloseModal} />
        </div>
        <p className="text-xl relative z-30 uppercase font-vt323">{title}</p>
      </div>

      <div className="grid grid-cols-2 p-4">
        {DATA_WALLET.map((item) => (
          <ItemWallet
            key={item?.name}
            {...item}
            isActive={selectedWallet === item.name}
            onClick={() => handleSelectWallet(item.name)}
          />
        ))}
      </div>
      <div className="px-1 pb-1">
        <button className="py-2 px-4 font-vt323 text-lg bg-[#4D58FF] w-full uppercase">
          connect
        </button>
      </div>
    </GenericModal>
  );
};
