import Image from "next/image";
import { BackgroundTexture } from "~~/components/BackgroundTexture";
import { HomeItem } from "~~/components/HomeItem";
import { CloseIcon } from "~~/components/icons/CloseIcon";
import { Readme } from "~~/components/Readme";
import { RecentlyVied } from "~~/components/RecentlyVied";

const DATA_MENU = [
  {
    icon: "/homescreen/challenges.png",
    name: "Challenges",
  },
  {
    icon: "/homescreen/mustwatch.png",
    name: "Must Watch",
  },
  {
    icon: "/homescreen/roadmap.png",
    name: "Roadmap",
  },
  {
    icon: "/homescreen/starklings.png",
    name: "starklings",
  },
  {
    icon: "/homescreen/readme.png",
    name: "read_me",
  },
];

const HomeScreen: React.FC = () => {
  return (
    <div className="bg-[#0F0F6D] h-full relative px-8 py-6">
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
            <HomeItem key={item?.name} {...item} />
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
