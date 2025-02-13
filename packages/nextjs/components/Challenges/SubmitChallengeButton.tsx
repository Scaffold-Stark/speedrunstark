import { useAccount } from "@starknet-react/core";
import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import Image from "next/image";
import { WrongNetworkDropdown } from "../scaffold-stark/CustomConnectButton/WrongNetworkDropdown";
import { useEffect, useState } from "react";
import { getCompletedChallenges } from "~~/services/api";
import { getChallengeId } from "~~/utils/submission";
import { useGlobalState } from "~~/services/store/store";

interface SubmitChallengeButtonProps {
  setOpenSubmit: (open: boolean) => void;
  challengeId: string;
}

export const SubmitChallengeButton = ({
  setOpenSubmit,
  challengeId,
}: SubmitChallengeButtonProps) => {
  const { address, chainId } = useAccount();
  const { targetNetwork } = useTargetNetwork();
  const [showSubmitButton, setShowSubmitButton] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const { submissionTopic } = useGlobalState();

  useEffect(() => {
    if (!address) {
      return;
    }
    if (submissionTopic) {
      return;
    }
    getCompletedChallenges(address)
      .then((response) => {
        const parsedChallengeId = getChallengeId(challengeId);
        const isCompleted = response.includes(parsedChallengeId);
        setSubmitted(isCompleted);
        setShowSubmitButton(!isCompleted);
      })
      .catch((e) => {
        console.error(e);
        setShowSubmitButton(false);
        setSubmitted(false);
      });
  }, [address, challengeId, submissionTopic]);

  if (!address) {
    return (
      <div className="fixed z-[95] md:bottom-5 bottom-3 transform  flex justify-center items-center gap-2 bg-[#ADADAD] md:w-fit w-[90%] px-5 cursor-pointer">
        <p className="text-lg font-vt323 uppercase !text-white">
          wallet not connected
        </p>
      </div>
    );
  }

  if (targetNetwork.id !== chainId) {
    return (
      <div className="fixed z-[95] md:bottom-5 bottom-3 transform flex justify-center items-center md:w-fit !text-white">
        <WrongNetworkDropdown />
      </div>
    );
  }

  if (submitted) {
    return (
      <div className="fixed z-[95] md:bottom-5 bottom-3 transform  flex justify-center items-center gap-2 bg-[#ADADAD] md:w-fit w-[90%] px-5 cursor-pointer">
        <p className="text-lg font-vt323 uppercase !text-white">
          Challenge submitted
        </p>
      </div>
    );
  }

  if (!showSubmitButton) {
    return null;
  }

  return (
    <div
      onClick={() => setOpenSubmit(true)}
      className="fixed z-[95] md:bottom-5 bottom-3 transform  flex justify-center items-center gap-2 bg-[#4D58FF] md:w-fit w-[90%] px-5 cursor-pointer"
    >
      <Image src={"/homescreen/submit.svg"} alt="icon" width={20} height={20} />
      <p className="text-lg font-vt323 uppercase !text-white">
        Submit challenge
      </p>
    </div>
  );
};
