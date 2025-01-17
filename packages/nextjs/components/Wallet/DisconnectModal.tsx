import Image from "next/image";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { useDisconnect } from "@starknet-react/core";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

export const DisconnectModal = ({ isOpen, onClose, title }: Props) => {
  const { disconnect } = useDisconnect();
  const handleDisconnectWallet = () => {
    disconnect();
    onClose();
    localStorage.removeItem("lastUsedConnector");
    localStorage.removeItem("chainId");
  };

  const handleCloseModal = () => {
    onClose();
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
      <div className="flex flex-col gap-3 items-center justify-center px-3 py-8">
        <Image
          src={"/homescreen/sure-icon.svg"}
          alt="icon"
          width={46}
          height={46}
        />
        <p className="max-w-[216px] text-center text-[#0C0C4F]">
          Are you sure to disconnect your wallet?
        </p>
      </div>
      <div className="grid grid-cols-2 gap-3 px-1">
        <button
          className="uppercase py-2 px-4 bg-[#4D58FF] font-vt323 text-lg"
          onClick={handleCloseModal}
        >
          Cancel
        </button>
        <button
          className="bg-[#FF282C] uppercase py-2 px-4 font-vt323 text-lg"
          onClick={handleDisconnectWallet}
        >
          Disconnect
        </button>
      </div>
    </GenericModal>
  );
};
