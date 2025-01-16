import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import Image from "next/image";
import { DATA_LANGUAGE } from "~~/mockup/data";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

const ItemLanguage = ({
  title,
  language,
}: {
  title: string;
  language: string;
}) => {
  return (
    <div className="hover:border hover:border-[#A8A8A8] cursor-pointer h-[156px] flex flex-col gap-2 justify-center items-center bg-[#F1F1F1] rounded-md">
      <h3 className="text-4xl text-[#787878] text-center uppercase">{title}</h3>
      <p className="text-sm text-[#787878] text-center uppercase">{language}</p>
    </div>
  );
};

export const LanguageModal = ({ isOpen, onClose, title }: Props) => {
  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={onClose}
      className={`w-[500px] mx-auto p-[1px] bg-white rounded-none`}
    >
      <div className={`w-ful`}>
        <div className="bg-[#4D58FF] relative h-[60px] flex items-center justify-center">
          <Image
            src="/homescreen/header-decore.svg"
            alt="icon"
            width={230}
            height={40}
            className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
          />

          <div className="flex items-center gap-1.5 absolute z-30 left-4">
            <CloseIcon onClose={onClose} />
          </div>
          <p className="text-xl relative z-30 uppercase font-vt323">{title}</p>
        </div>
        <div className="grid grid-cols-3 gap-1 py-2 px-1">
          {DATA_LANGUAGE.map((item) => (
            <ItemLanguage key={item.title} {...item} />
          ))}
        </div>
        <button className="uppercase w-full text-center py-2 bg-[#4D58FF] text-lg font-vt323">
          confirm
        </button>
      </div>
    </GenericModal>
  );
};
