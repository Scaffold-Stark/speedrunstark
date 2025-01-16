import Image from "next/image";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

export const WalletModal = ({ isOpen, onClose, title }: Props) => {
  const handleCloseModal = () => {
    onClose();
  };
  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`w-[320px] mx-auto p-[1px] rounded-lg bg-white `}
    >
      <div>
        <div className="bg-[#4D58FF] relative rounded-t-lg h-[60px] flex items-center justify-center">
          
          <h2 className="text-xl relative z-30 uppercase font-vt323 text-white">
            {title}
          </h2>
        </div>
      </div>
    </GenericModal>
  );
};
