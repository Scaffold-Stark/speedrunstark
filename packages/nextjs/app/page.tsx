"use client";
import Image from "next/image";
import { useState } from "react";
import { BackgroundTexture } from "~~/components/BackgroundTexture";
import { ChallengeModal } from "~~/components/Challenges/ChallengeModal";
import { HomeItem } from "~~/components/HomeItem";
import { Readme } from "~~/components/Readme";
import { RecentlyVied } from "~~/components/RecentlyVied";
import { RoadmapModal } from "~~/components/Roadmap/RoadmapModal";
import { VideoModal } from "~~/components/Videos/VideoModal";
import { DATA_MENU, DATA_MENU_SOCIAL } from "~~/mockup/data";

const Home = () => {
  const [openChallenge, setOpenChallenge] = useState(false);
  const [openVideo, setOpenVideo] = useState(false);
  const [openRoadmap, setOpenRoadmap] = useState(false);
  const handleItemClick = (type: string) => {
    if (type === "challenge") {
      setOpenChallenge(true);
    }
    if (type === "video") {
      setOpenVideo(true);
    }
    if (type === "roadmap") {
      setOpenRoadmap(true);
    }
  };

  return (
    <div className="bg-[#0F0F6D] h-full relative md:px-8 px-3 md:py-6 py-3">
      <ChallengeModal
        isOpen={openChallenge}
        onClose={() => setOpenChallenge(false)}
        title="Challenges"
      />
      <VideoModal
        isOpen={openVideo}
        onClose={() => setOpenVideo(false)}
        title="Videos"
      />
      <RoadmapModal
        isOpen={openRoadmap}
        onClose={() => setOpenRoadmap(false)}
        title="roadmap"
      />
      <Image
        src={"/homescreen/middle-screen.png"}
        alt="logo"
        width={634}
        height={148}
        className="md:w-[634px] md:h-[148px] w-[320px] h-[90px] absolute left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2"
      />
      <BackgroundTexture />
      <div className="relative z-40 h-full">
        <div className="flex flex-col gap-8">
          {DATA_MENU.map((item) => (
            <HomeItem
              key={item.name}
              {...item}
              onclick={() => handleItemClick(item.type)}
            />
          ))}
        </div>

        <div className="absolute right-0 z-40 transform top-1/4 -translate-y-1/4">
          <div className="md:block hidden">
            <Readme />
          </div>
          <div className="flex flex-col mt-5 gap-8 items-end">
            {DATA_MENU_SOCIAL.map((item) => (
              <HomeItem
                key={item.name}
                {...item}
                // onclick={() => handleItemClick(item.type)}
              />
            ))}
          </div>
        </div>
        <div className="md:block hidden absolute bottom-10 z-40 transform left-1/2 -translate-x-1/2 max-w-[666px] w-full">
          <RecentlyVied onClickItem={handleItemClick} />
        </div>
      </div>
    </div>
  );
};

export default Home;
