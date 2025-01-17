import Image from "next/image";
import { ComingSoon } from "../Tooltips/Comingsoon";

export const ChallengeItem = ({
  id,
  name,
  active,
  comming,
  isBurn,
  onSelect,
  onOpenDetail,
}: {
  id: string;
  name: string;
  active?: boolean;
  comming?: boolean;
  isBurn?: boolean;
  onSelect: (id: string) => void;
  onOpenDetail?: any;
}) => {
  const handleClick = () => {
    const isMediumScreen = window.matchMedia("(min-width: 768px)").matches;

    if (!isMediumScreen) {
      onOpenDetail();
    }
    onSelect(id);
  };
  return (
    <div
      className={`flex items-center gap-3 p-4 border-b border-[#000] md:max-w-[300px] w-full ${
        comming ? "cursor-not-allowed" : "cursor-pointer"
      }`}
      style={{
        background: active ? "#E5E5E5" : "white",
      }}
      onClick={handleClick}
    >
      <Image
        src={"/homescreen/challenge-icon.svg"}
        alt="icon"
        width={18}
        height={18}
      />
      <p className="text-black w-full truncate flex-1">{name}</p>
      {isBurn && (
        <Image
          src={"/homescreen/fire-icon.svg"}
          alt="icon"
          width={18}
          height={18}
        />
      )}
      {comming && (
        <div className="coming-container">
          <p className="coming-text">Coming Soon</p>
          <div className="coming-tooltip">
            <ComingSoon />
          </div>
        </div>
      )}
    </div>
  );
};
