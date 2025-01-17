import { useState } from "react";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import Image from "next/image";
import { NumberBox } from "../NumberBox";
import { ROADMAP_DETAIL_DATA } from "~~/mockup/data";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

const RoadmapItem = ({
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

const RoadmapDetail = ({
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

const ProgressBar = ({
  isActive,
  className,
  fromStep,
  toStep,
}: {
  isActive: boolean;
  className: string;
  fromStep: string;
  toStep: string;
}) => {
  const getOriginAndScale = () => {
    if (fromStep === "build" && toStep === "hack") {
      return {
        origin: "origin-top",
        scale: isActive ? "scale-100" : "scale-y-0",
      };
    }
    if (fromStep === "seed" && toStep === "demo") {
      return {
        origin: "origin-bottom",
        scale: isActive ? "scale-100" : "scale-y-0",
      };
    }
    return {
      origin: "origin-left",
      scale: isActive ? "scale-100" : "scale-x-0",
    };
  };

  const { origin, scale } = getOriginAndScale();

  return (
    <div className={`relative overflow-hidden ${className}`}>
      <div className="absolute inset-0 bg-[#B2B2B2]" />
      <div
        className={`absolute inset-0 transition-transform duration-500 ease-in-out ${origin} ${scale}`}
        style={{ backgroundColor: "#2835FF" }}
      />
    </div>
  );
};

export const RoadmapModal = ({ isOpen, onClose, title }: Props) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [activeStep, setActiveStep] = useState("learn");

  const isProgressActive = (stepId: string) => {
    const steps = ["learn", "build", "hack", "seed", "demo", "fund"];
    const stepIndex = steps.indexOf(stepId);
    const activeIndex = steps.indexOf(activeStep);
    return stepIndex < activeIndex;
  };

  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  const handleCloseModal = () => {
    onClose();
    setIsExpanded(false);
  };

  // Find the active step data
  const activeStepData = ROADMAP_DETAIL_DATA.find(
    (item) => item.id === activeStep,
  );

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`md:shadow-modal max-w-[1200px] w-full mx-auto md:p-[1px] rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
    >
      <div className={`w-full ${isExpanded ? "h-full flex flex-col" : ""}`}>
        <div className="bg-[#4D58FF] relative rounded-t-lg h-[60px] flex items-center justify-center">
          <Image
            src="/homescreen/header-decore.svg"
            alt="icon"
            width={230}
            height={40}
            className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
          />

          <div className="flex items-center gap-1.5 absolute z-30 left-4">
            <CloseIcon onClose={handleCloseModal} />
            <ExpandIcon onExpand={handleExpand} />
          </div>
          <p className="text-xl relative z-30 uppercase font-vt323">{title}</p>
        </div>
        <div className={`${isExpanded ? "flex-1 h-[calc(100%-60px)]" : ""}`}>
          <div className="w-full bg-[#E5E5E5] p-8">
            <div className="flex justify-between items-end">
              {/* Left side */}
              <div className="flex">
                <div>
                  <RoadmapItem
                    icon="/homescreen/roadmap-learn.svg"
                    title="learn"
                    active={activeStep === "learn"}
                    onClick={() => setActiveStep("learn")}
                  />
                </div>
                <ProgressBar
                  isActive={isProgressActive("learn")}
                  className="w-[150px] h-[90px] mt-4"
                  fromStep="learn"
                  toStep="build"
                />
                <div className="flex flex-col">
                  <RoadmapItem
                    icon="/homescreen/roadmap-build.svg"
                    title="build"
                    active={activeStep === "build"}
                    onClick={() => setActiveStep("build")}
                  />
                  <ProgressBar
                    isActive={isProgressActive("build")}
                    className="w-[90px] h-[60px] ml-[18px]"
                    fromStep="build"
                    toStep="hack"
                  />
                  <RoadmapItem
                    icon="/homescreen/roadmap-hack.svg"
                    title="hack"
                    active={activeStep === "hack"}
                    onClick={() => setActiveStep("hack")}
                  />
                </div>
              </div>

              {/* Middle progress bar */}
              <ProgressBar
                isActive={isProgressActive("hack")}
                className="h-[90px] w-full mb-4"
                fromStep="hack"
                toStep="seed"
              />

              {/* Right side */}
              <div>
                <div className="flex">
                  <RoadmapItem
                    icon="/homescreen/roadmap-demo.svg"
                    title="demo"
                    active={activeStep === "demo"}
                    onClick={() => setActiveStep("demo")}
                  />
                  <ProgressBar
                    isActive={isProgressActive("demo")}
                    className="w-[150px] h-[90px] mt-4"
                    fromStep="demo"
                    toStep="fund"
                  />
                  <RoadmapItem
                    icon="/homescreen/roadmap-fund.svg"
                    title="fundraising"
                    active={activeStep === "fund"}
                    onClick={() => setActiveStep("fund")}
                  />
                </div>
                <ProgressBar
                  isActive={isProgressActive("seed")}
                  className="w-[90px] h-[60px] ml-4"
                  fromStep="seed"
                  toStep="demo"
                />
                <div className="flex">
                  <RoadmapItem
                    icon="/homescreen/roadmap-seed.svg"
                    title="seed funding"
                    active={activeStep === "seed"}
                    onClick={() => setActiveStep("seed")}
                  />
                </div>
              </div>
            </div>
          </div>
          {activeStepData && (
            <RoadmapDetail
              number={activeStepData.number}
              title={activeStepData.title}
              desc={activeStepData.desc}
              xUrl={activeStepData.xUrl}
            />
          )}
        </div>
      </div>
    </GenericModal>
  );
};
