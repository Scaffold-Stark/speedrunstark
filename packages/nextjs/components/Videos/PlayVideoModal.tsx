import { useState } from "react";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import ReactPlayer from "react-player";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  url: string;
};
export const PlayVideoModal = ({ isOpen, onClose, title, url }: Props) => {
  const [isExpanded, setIsExpanded] = useState(false);

  const handleCloseModal = () => {
    onClose();
  };

  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`w-[1220px] mx-auto p-[1px] rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
    >
      <div>
        <div className="bg-[#4D58FF] relative rounded-t-lg h-[60px] flex items-center justify-center">
          <Image
            src="/homescreen/header-decore.svg"
            alt="icon"
            width={230}
            height={40}
            className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
          />

          <div className="flex items-center gap-1.5 absolute z-30 left-4">
            <CloseIcon onClose={handleCloseModal} />
            <ExpandIcon onExpand={handleExpand} />
          </div>
          <p className="text-lg relative z-30 uppercase font-vt323">{title}</p>
        </div>
        <div className="pb-1">
          <ReactPlayer
            url={`${url}`}
            width={"100%"}
            height={isExpanded ? "calc(95vh - 65px)" : 700}
            playing
          />
        </div>
      </div>
    </GenericModal>
  );
};
