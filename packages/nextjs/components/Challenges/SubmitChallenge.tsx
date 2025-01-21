import { useState } from "react";
import { ConfirmSubmitModal } from "./ConfirmSubmitModal";
import { DynamicSequentialInputs } from "./DynamicSequentialInputs";
import { Challenge } from "~~/mockup/type";
import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";

export const SubmitChallenge = ({ challenge }: { challenge: Challenge }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [openSubmit, setOpenSubmit] = useState(false);
  const [openConfirmSubmit, setOpenConfirmSubmit] = useState(false);

  const handleCloseModal = () => {
    setOpenSubmit(false);
    setIsExpanded(false);
  };
  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  const handleSubmit = (isAllValidated: boolean) => {
    if (isAllValidated) {
      setOpenConfirmSubmit(true);
    }
  };

  return (
    <div className="flex justify-center">
      <div
        onClick={() => setOpenSubmit(true)}
        className="fixed z-[95] md:bottom-5 bottom-3 transform  flex justify-center items-center gap-2 bg-[#4D58FF] md:w-fit w-[90%] px-5 cursor-pointer"
      >
        <Image
          src={"/homescreen/submit.svg"}
          alt="icon"
          width={20}
          height={20}
        />
        <p className="text-lg font-vt323 uppercase !text-white">
          Submit challenge
        </p>
      </div>
      {openSubmit && (
        <section
          className={`overflow-hidden absolute z-[98] md:top-1/2 top-0 left-1/2 transform md:-translate-y-1/2 -translate-x-1/2 md:shadow-modal max-w-[850px] w-full mx-auto md:p-[1px] md:rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
        >
          <div className={`w-full`}>
            <div className="bg-[#4D58FF] relative md:rounded-t-lg h-[60px] flex items-center justify-center">
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
              <p className="text-xl relative z-30 uppercase font-vt323 !text-white">
                {challenge?.challenge}: {challenge?.name}
              </p>
            </div>
          </div>
          <div className="p-4 md:bg-[#E5E5E5] bg-white md:h-full h-[calc(100vh-112px)]">
            <div className="flex flex-col gap-2">
              <div
                className="w-full h-[2px] opacity-50"
                style={{
                  backgroundImage:
                    "repeating-linear-gradient(to right, black 0, black 8px, transparent 8px, transparent 15px)",
                }}
              />
              <h3 className="text-black text-[22px]">
                {challenge?.challenge}: {challenge?.name}
              </h3>
              <div>
                <p className="text-sm !text-[#939393]">
                  You have to add {challenge.inputURL?.length} Deploy URL.
                </p>
                <ul className="text-sm !text-[#939393] list-disc list-inside ml-3">
                  <li>
                    Press <span className="text-[#2835FF]">Enter</span> to
                    submit and <span className="text-[#FF282C]">ESC</span> to
                    cancel.
                  </li>
                  <li>
                    Make sure that repo is{" "}
                    <span className="uppercase text-[#2835FF]">public</span> or
                    github user &quot;
                    <span className="text-[#2835FF]">0xquantum3labs</span>
                    &quot;, &quot;
                    <span className="text-[#2835FF]">Nadai2010</span>&quot; has
                    read access.
                  </li>
                </ul>
              </div>
              <div
                className="w-full h-[2px] opacity-50"
                style={{
                  backgroundImage:
                    "repeating-linear-gradient(to right, black 0, black 8px, transparent 8px, transparent 15px)",
                }}
              />
            </div>
            <div className="mt-4 pb-8 flex flex-col gap-5">
              <DynamicSequentialInputs
                inputFields={challenge.inputURL}
                onSubmit={handleSubmit}
              />
            </div>
          </div>
        </section>
      )}
      {openConfirmSubmit && (
        <ConfirmSubmitModal onClose={() => setOpenConfirmSubmit(false)} />
      )}
    </div>
  );
};
