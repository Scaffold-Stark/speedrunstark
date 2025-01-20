import React, { useState } from "react";
import Image from "next/image";
import { DATA_VIDEOS } from "~~/mockup/data";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { PlayVideoModal } from "./PlayVideoModal";

type Video = {
  title: string;
  date: string;
  desc: string;
  banner: string;
};

type VideoModalProps = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

const ItemVideo = ({
  title,
  isActive = false,
  onClick,
}: {
  title: string;
  isActive?: boolean;
  onClick: () => void;
}) => {
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
    <div
      className="flex flex-col items-center cursor-pointer transition-all duration-200"
      onClick={onClick}
    >
      <div
        className={`w-full flex items-center justify-center py-1 transition-colors duration-200 ${isActive ? "bg-blue-100" : "hover:bg-gray-100"}`}
      >
        <Image
          src="/homescreen/videos-icon.svg"
          alt="Video thumbnail"
          width={48}
          height={48}
        />
      </div>
      <div
        className={`bg-white min-w-[164px] text-black py-1 px-2 w-full min-h-12 flex items-center justify-center border ${isActive ? "border-blue-500" : "border-black"}`}
      >
        <p className="md:text-sm text-xs text-center uppercase leading-tight">
          {formatTitle(title)}
        </p>
      </div>
    </div>
  );
};

const DetailItemVideo = ({
  video,
  onClick,
}: {
  video: Video;
  onClick: () => void;
}) => {
  const { title, date, desc, banner } = video;

  return (
    <div className="flex flex-col px-5 gap-2 h-full">
      <div className="flex-1 flex flex-col gap-4 overflow-y-auto">
        <h3 className="text-xl text-black font-medium capitalize">{title}</h3>
        {banner && (
          <div className="relative w-full aspect-video">
            <Image
              src={banner}
              alt={title}
              width={400}
              height={192}
              className="rounded-xl object-cover"
            />
          </div>
        )}
        <div className="flex-1">
          <p className="text-sm text-[#4D58FF]">{date}</p>
          <p className="text-gray-800 leading-relaxed">{desc}</p>
        </div>
      </div>
      <button
        className="bg-[#4D58FF] px-4 py-3 flex items-center justify-center gap-2 w-full"
        onClick={onClick}
      >
        <Image
          src="/homescreen/play-video.svg"
          alt="Play icon"
          width={16}
          height={16}
        />
        <span className="text-lg text-white uppercase font-vt323">
          Play video
        </span>
      </button>
    </div>
  );
};

export const VideoModal = ({ isOpen, onClose, title }: VideoModalProps) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [selectedVideoIndex, setSelectedVideoIndex] = useState(0);
  const [openPlayVideo, setOpenPlayVideo] = useState(false);

  const handleCloseModal = () => {
    onClose();
    setIsExpanded(false);
  };

  if (!isOpen) return null;

  if (openPlayVideo)
    return (
      <PlayVideoModal
        isOpen={openPlayVideo}
        onClose={() => setOpenPlayVideo(false)}
        title={DATA_VIDEOS[selectedVideoIndex].title}
        url={DATA_VIDEOS[selectedVideoIndex].url}
        desc={DATA_VIDEOS[selectedVideoIndex].desc}
      />
    );

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`md:shadow-modal max-w-[1200px] w-full mx-auto md:p-[1px] md:rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
    >
      <div className={`w-full ${isExpanded ? "h-full flex flex-col" : ""}`}>
        <div className="bg-[#4D58FF] relative md:rounded-t-lg rounded-none h-[60px] flex items-center justify-center">
          <Image
            src="/homescreen/header-decore.svg"
            alt="Header decoration"
            width={230}
            height={40}
            className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
          />

          <div className="flex items-center gap-1.5 absolute z-30 left-4">
            <CloseIcon onClose={handleCloseModal} />
            <ExpandIcon onExpand={() => setIsExpanded(!isExpanded)} />
          </div>
          <h2 className="text-xl relative z-30 uppercase font-vt323 text-white">
            {title}
          </h2>
        </div>

        <div
          className={`grid md:grid-cols-3 grid-cols-1 py-5 min-h-[600px] h-full max-h-[calc(100vh-114px)] overflow-y-auto`}
        >
          <div className="md:col-span-2 col-span-1 md:px-6 px-3">
            <div className="mb-7 flex items-end gap-2">
              <h3 className="md:text-xl text-base text-black font-medium capitalize shrink-0">
                Starknet Basecamp X Series
              </h3>
              <div className="bg-black h-px w-full mb-2" />
            </div>
            <div className="md:flex hidden flex-wrap gap-4">
              {DATA_VIDEOS.map((video, index) => (
                <ItemVideo
                  key={video.title}
                  title={video.title}
                  isActive={selectedVideoIndex === index}
                  onClick={() => {
                    setSelectedVideoIndex(index);
                  }}
                />
              ))}
            </div>
            <div className="md:hidden grid grid-cols-2 gap-4">
              {DATA_VIDEOS.map((video, index) => (
                <ItemVideo
                  key={video.title}
                  title={video.title}
                  isActive={selectedVideoIndex === index}
                  onClick={() => setOpenPlayVideo(true)}
                />
              ))}
            </div>
          </div>
          <div className="md:block hidden col-span-1 h-full">
            <DetailItemVideo
              video={DATA_VIDEOS[selectedVideoIndex]}
              onClick={() => setOpenPlayVideo(true)}
            />
          </div>
        </div>
      </div>
    </GenericModal>
  );
};
