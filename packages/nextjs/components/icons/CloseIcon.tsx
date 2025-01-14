import Image from "next/image";

export const CloseIcon = () => {
  return (
    <div className="bg-[#FF5F5B] border border-black rounded-full p-1 cursor-pointer w-fit">
      <Image
        src={"/homescreen/close-icon.svg"}
        width={12}
        height={12}
        alt="icon"
      />
    </div>
  );
};
