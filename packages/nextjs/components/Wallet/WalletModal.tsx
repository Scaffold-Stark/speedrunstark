import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { PersonIcon } from "../icons/Person";
import { CodeIcon } from "../icons/Code";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

export const WalletModal = ({ isOpen, onClose, title }: Props) => {
  const handleCloseModal = () => {
    onClose();
  };

  if (!isOpen) return null;

  return (
    <>
      <div
        className={`fixed h-screen w-screen grid  top-0 left-0 z-[99] opacity-55 bg-black`}
        onClick={handleCloseModal}
      />

      <div className="absolute right-8 top-16 z-[100]">
        <div className="w-[300px] relative bg-transparent">
          <div className="absolute -top-5 right-5">
            <Image
              src="/homescreen/arrow-youraccount.svg"
              alt="arrow"
              width={30}
              height={30}
            />
          </div>
          <div className="bg-[#4D58FF] relative py-2.5 flex items-center justify-center">
            <p className="text-xl relative z-30 uppercase font-vt323">
              {title}
            </p>
          </div>
          <div>
            <div className="bg-white flex items-center gap-2.5 px-4 py-3">
              <PersonIcon color="black" />
              <p className="text-[15px] text-black mt-1 flex-1">0xda...ea12</p>
              <Image
                src={"/homescreen/disconnect-icon.svg"}
                alt="icon"
                width={16}
                height={16}
                className="cursor-pointer"
              />
            </div>
            <div className="h-[1px] w-full bg-black"></div>
            <div className="bg-white flex items-center gap-2.5 px-4 py-3">
              <CodeIcon color="black" width={16} />
              <p className="text-[15px] text-black mt-0.5 flex-1">
                Completed Challenges
              </p>
              <p className="text-black">04</p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default WalletModal;
