import Image from "next/image";
import { HomeItem } from "./HomeItem";
import { CloseIcon } from "./icons/CloseIcon";
import { useState } from "react";
import { DATA_MENU_BOT } from "~~/mockup/data";

export const RecentlyVied = ({onClickItem} : {onClickItem  : (type : string) => void}) => {
  const [dislay, setDisplay] = useState(true);

  if (!dislay) return null;

  return (
    <div>
      <div className="flex items-center justify-center bg-[#4D58FF] py-2.5 px-6 relative">
        <Image
          src="/homescreen/header-decore.svg"
          alt="icon"
          width={230}
          height={40}
          className="absolute left-1/2 transform -translate-x-1/2 z-10"
        />
        <div className="absolute left-6 transform top-1/2 -translate-y-1/2 z-50">
          <CloseIcon onClose={() => setDisplay(false)} />
        </div>
        <p className="font-vt323 uppercase text-xl relative z-10">
          recently vied
        </p>
      </div>
      <div className="flex gap-8 bg-white p-5 justify-between overflow-x-auto">
        {DATA_MENU_BOT.map((item) => (
          <HomeItem
            key={item?.name}
            {...item}
            theme="secondary"
            onclick={() => onClickItem(item.type)}
          />
        ))}
      </div>
    </div>
  );
};
