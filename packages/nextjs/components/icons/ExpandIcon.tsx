import Image from "next/image";

export const ExpandIcon = () => {
  return (
    <div className="p-1 border border-black w-fit rounded-full cursor-pointer bg-[#FF0]">
      <Image
        src={"/homescreen/expand-icon.svg"}
        alt="icon"
        width={12}
        height={12}
      />
    </div>
  );
};
