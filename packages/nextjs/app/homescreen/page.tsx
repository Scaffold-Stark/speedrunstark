"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { BackgroundTexture } from "~~/components/BackgroundTexture";
import { ChallengeModal } from "~~/components/Challenges/ChallengeModal";
import { HomeItem } from "~~/components/HomeItem";
import { Readme } from "~~/components/Readme";
import { RecentlyVied } from "~~/components/RecentlyVied";

const DATA_MENU = [
  {
    icon: "/homescreen/challenges.png",
    name: "Challenges",
    type: "challenge",
  },
  {
    icon: "/homescreen/mustwatch.png",
    name: "Must Watch",
    type: "mustwatch",
  },
  {
    icon: "/homescreen/roadmap.png",
    name: "Roadmap",
    type: "roadmap",
  },
  {
    icon: "/homescreen/starklings.png",
    name: "starklings",
    type: "starklings",
  },
  {
    icon: "/homescreen/readme.png",
    name: "read_me",
    type: "readme",
  },
] as const;

const HomeScreen: React.FC = () => {
  const [openChallenge, setOpenChallenge] = useState(false);

  const handleItemClick = (type: string) => {
    if (type === "challenge") {
      setOpenChallenge(true);
    }
  };

  return (
    <div className="bg-[#0F0F6D] h-full relative px-8 py-6">
      <ChallengeModal
        isOpen={openChallenge}
        onClose={() => setOpenChallenge(false)}
      />
      <Image
        src={"/homescreen/middle-screen.png"}
        alt="logo"
        width={634}
        height={148}
        className="absolute left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2"
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
        <div className="absolute right-6 z-40 transform top-1/4 -translate-y-1/4">
          <Readme />
        </div>
        <div className="absolute bottom-10 z-40 transform left-1/2 -translate-x-1/2 max-w-[666px] w-full">
          <RecentlyVied />
        </div>
      </div>
    </div>
  );
};

export default HomeScreen;