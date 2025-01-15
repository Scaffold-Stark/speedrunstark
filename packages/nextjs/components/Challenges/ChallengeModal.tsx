import { useState } from "react";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import Image from "next/image";
import { triggerAsyncId } from "async_hooks";

const DATA_CHALLENGE = [
  {
    name: "Simple NFT Example",
    isBurn: true,
  },
  {
    name: "Decentralized Staking App",
    isBurn: true,
  },
  {
    name: "Token Vendor",
    isBurn: true,
  },
  {
    name: "Dice Game",
  },
  {
    name: "Build a DEX",
  },
  {
    name: "A State Channel Application",
  },
  {
    name: "Multisig Wallet Challenge",
    comming: true,
  },
  {
    name: "Building Cohort Challenge",
    comming: true,
  },
];

type Props = {
  isOpen: boolean;
  onClose: () => void;
};

const ChallengeItem = ({
  name,
  active,
  comming,
  isBurn,
}: {
  name: string;
  active?: boolean;
  comming?: boolean;
  isBurn?: boolean;
}) => {
  return (
    <div
      className="flex items-center gap-3 cursor-pointer p-4 border-b border-[#000] max-w-[300px] w-full"
      style={{
        background: active ? "#E5E5E5" : "white",
      }}
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
        <p className="text-sm bg-[#2835FF] rounded px-1">Coming Soon</p>
      )}
    </div>
  );
};

export const ChallengeModal = ({ isOpen, onClose }: Props) => {
  return (
    <>
      <GenericModal
        animate
        isOpen={isOpen}
        onClose={onClose}
        className={`w-[1200px] mx-auto p-[1px] rounded-lg bg-white`}
      >
        <div className="w-full">
          <div className="bg-[#4D58FF]  rounded-t-lg relative h-[60px] flex items-center justify-center">
            <div className="flex items-center gap-1.5 absolute left-4">
              <CloseIcon />
              <ExpandIcon />
            </div>
            <p className="text-lg">Challenges</p>
          </div>
          <div className="flex">
            <div>
              <p className="text-[#333333] font-vt323 text-center py-1">
                12 challenges available
              </p>
              <div className="pb-8 overflow-y-scroll">
                {DATA_CHALLENGE.map((item) => (
                  <ChallengeItem key={item.name} {...item} />
                ))}
              </div>
            </div>
            <div></div>
          </div>
        </div>
      </GenericModal>
    </>
  );
};
