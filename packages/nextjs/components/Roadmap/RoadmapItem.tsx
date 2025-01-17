import Image from "next/image";
import { NumberBox } from "../NumberBox";

export const RoadmapItem = ({
  icon,
  title,
  active,
  onClick,
}: {
  icon: string;
  title: string;
  active?: boolean;
  onClick: () => void;
}) => {
  return (
    <div
      className={`${active ? "bg-white border-2 border-[#2835FF] shadow-md" : "bg-[#DCDCDC] border border-[#ADADAD]"} cursor-pointer w-[124px] h-[124px] flex flex-col items-center justify-center gap-1`}
      onClick={onClick}
    >
      <Image src={icon} alt="icon" width={44} height={44} />
      <p className="text-black uppercase text-center">{title}</p>
    </div>
  );
};

export const RoadmapDetail = ({
  number,
  title,
  desc,
  xUrl,
}: {
  number: number;
  title: string;
  desc: string;
  xUrl?: string;
}) => {
  return (
    <div>
      <div className="border-b-2 border-dashed border-black p-4 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <NumberBox number={number} />
          <p className="text-[#0C0C4F] text-xl mt-1 uppercase">{title}</p>
        </div>
        <button className="px-4 py-2 bg-[#4D58FF] font-vt323 uppercase">
          Check latest updates on X
        </button>
      </div>
      <div className="min-h-[150px]">
        <p className="text-[#0C0C4F] p-4">{desc}</p>
      </div>
    </div>
  );
};

export const RoadmapItemMB = ({
  icon,
  title,
  desc,
}: {
  icon: string;
  title: string;
  desc: string;
}) => {
  return (
    <div>
      <div className="relative z-50 bg-white p-4 border-t border-b border-black flex items-center gap-3">
        <Image src={icon} alt="icon" width={22} height={22} />
        <p className="text-black uppercase text-center">{title}</p>
      </div>
      <p className="text-[#0C0C4F] text-sm px-1 pb-10 mt-2 ml-[55px]">{desc}</p>
    </div>
  );
};
