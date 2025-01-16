import { useEffect, useState } from "react";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import Image from "next/image";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

const DATA_VIDEOS = [
  {
    title: "Session 1: Fundamentals",
    date: "07/10/2024",
    desc: "Welcome to the first session of our Bootcamp X, focused on Starknet fundamentals. This session provides a clear overview of Starknet",
    banner: "/homescreen/video-section1.png",
  },
  {
    title: "Session 2: architecture",
    date: "07/10/2024",
    desc: "Welcome to the first session of our Bootcamp X, focused on Starknet fundamentals. This session provides a clear overview of Starknet",
    banner: "",
  },
  {
    title: "Session 3: cairo",
    date: "07/10/2024",
    desc: "Welcome to the first session of our Bootcamp X, focused on Starknet fundamentals. This session provides a clear overview of Starknet",
    banner: "",
  },
];

const ItemVideo = ({ title }: { title: string }) => {
  const formatTitle = (text: string) => {
    const words = text.split(" ");
    const firstLine = words.slice(0, 2).join(" ");
    const secondLine = words.slice(2).join(" ");

    return (
      <>
        <span className="block">{firstLine}</span>
        {secondLine && <span className="block">{secondLine}</span>}
      </>
    );
  };

  return (
    <div className="flex flex-col items-center cursor-pointer">
      <div className="hover:bg-[#E9EAF7] w-full flex items-center justify-center py-1">
        <Image
          src="/homescreen/videos-icon.svg"
          alt="icon"
          width={48}
          height={48}
        />
      </div>
      <div className="bg-white text-black py-1 px-2 w-[152px] min-h-[48px] flex items-center justify-center border border-black">
        <p className="text-sm text-center uppercase leading-tight">
          {formatTitle(title)}
        </p>
      </div>
    </div>
  );
};

const DetailItemVideo = ({
  title,
  date,
  desc,
  banner,
}: {
  title: string;
  date: string;
  desc: string;
  banner: string;
}) => {
  return (
    <div className="flex flex-col px-5 gap-2 h-full">
      <div className="flex-1 flex flex-col gap-4 overflow-y-auto">
        <h3 className="text-xl text-black">{title}</h3>
        <div>
          <Image
            src={banner}
            alt="image"
            width={400}
            height={192}
            className="rounded-xl"
          />
        </div>
        <div className="flex-1">
          <p className="text-sm text-[#4D58FF]">{date}</p>
          <p className="text-[#0C0C4F]">{desc}</p>
        </div>
      </div>
      <div>
        <div className="bg-[#4D58FF] px-4 py-3 flex items-center justify-center gap-1.5 cursor-pointer">
          <Image
            src={"/homescreen/play-video.svg"}
            alt="icon"
            width={16}
            height={16}
          />
          <p className="text-lg text-white uppercase font-vt323">play video</p>
        </div>
      </div>
    </div>
  );
};
export const VideoModal = ({ isOpen, onClose, title }: Props) => {
  const [isExpanded, setIsExpanded] = useState(false);

  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  const handleCloseModal = () => {
    onClose();
    setIsExpanded(false);
  };

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`shadow-modal max-w-[1220px] w-full mx-auto p-[1px] rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
    >
      <div className={`w-full ${isExpanded ? "h-full flex flex-col" : ""}`}>
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
        <div
          className={`py-7 grid grid-cols-3 ${isExpanded ? "flex-1 h-[calc(100%-60px)]" : "h-[70vh]"}`}
        >
          <div className="col-span-2 px-6">
            <div className="mb-7 flex items-end gap-2">
              <p className="text-xl text-black shrink-0">
                Starknet Basecamp X Series
              </p>
              <div className="bg-black h-[1px] w-full mb-2"></div>
            </div>
            <div className="flex items-center gap-2.5">
              {DATA_VIDEOS.map((item) => (
                <ItemVideo key={item.title} title={item.title} />
              ))}
            </div>
          </div>
          <div className="col-span-1">
            <DetailItemVideo {...DATA_VIDEOS[0]} />
          </div>
        </div>
      </div>
    </GenericModal>
  );
};
