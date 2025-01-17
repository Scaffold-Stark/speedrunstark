import Image from "next/image";

export const ComingSoon = () => {
  return (
    <div className="w-[325px] relative">
      <Image
        src={"/homescreen/arrow-tooltip.svg"}
        width={20}
        height={20}
        alt="icon"
        className="absolute -left-3 top-2 z-[99]"
      />
      <div className="bg-[#4D58FF] p-2 flex items-center justify-between">
        <p className="text-white font-vt323 text-xl">Challenge</p>
        <p className="text-sm text-[#2835FF] px-1 pt-0.5 bg-white rounded">
          Coming Soon
        </p>
      </div>
      <div className="bg-white px-4 py-3">
        <p className="text-black">Building Cohort Challenge</p>
      </div>
    </div>
  );
};
