import Image from "next/image";

interface IProps {
  onExpand: () => void;
}

export const ExpandIcon = ({ onExpand }: IProps) => {
  return (
    <div
      className="p-1 border border-black w-fit rounded-full cursor-pointer bg-[#FF0]"
      onClick={onExpand}
    >
      <Image
        src={"/homescreen/expand-icon.svg"}
        alt="icon"
        width={12}
        height={12}
      />
    </div>
  );
};
