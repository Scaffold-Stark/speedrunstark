import Image from "next/image";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { getMarkdownComponents } from "../GetMarkdownComponents/GetMarkdownComponents";
import ReactMarkdown from "react-markdown";
import { SubmitChallenge } from "./SubmitChallenge";
import { Challenge } from "~~/mockup/type";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import rehypeRaw from "rehype-raw";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  id: string;
  title: string;
  content: any;
  loading: boolean;
  challenge: Challenge;
};

export const ChallengeModalDetailMB = ({
  isOpen,
  onClose,
  id,
  title,
  content,
  loading,
  challenge,
}: Props) => {
  const handleCloseModal = () => {
    onClose();
  };
  const handleMoveonGithub = () => {
    window.open(
      `https://github.com/Scaffold-Stark/speedrunstark/tree/${id}`,
      "_blank",
    );
  };
  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`xl:w-[1200px] w-screen mx-auto md:p-[1px] md:rounded-lg bg-white`}
    >
      <div className="w-full h-full">
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
          </div>
          <p className="text-xl relative z-30 uppercase font-vt323">{title}</p>
        </div>
        <div className="challenge-content p-4 h-full overflow-y-auto">
          {loading && (
            <div className="w-full h-full flex items-center justify-center">
              <span className="text-[#4D58FF] loading loading-spinner loading-lg"></span>
            </div>
          )}

          {!loading && content && (
            <div>
              {/* <SubmitChallenge challenge={challenge} /> */}
              <ReactMarkdown
                rehypePlugins={[rehypeRaw]}
                components={getMarkdownComponents()}
              >
                {content}
              </ReactMarkdown>
              <button
                className="text-[#0C0C4F] mt-5 mx-auto rounded-full border border-[#0C0C4F] py-2 px-3 font-medium hover:bg-secondary-content flex items-center justify-center gap-1 text-center"
                onClick={handleMoveonGithub}
              >
                View it on Github
                <ArrowTopRightOnSquareIcon className="w-[20px]" />
              </button>
            </div>
          )}
        </div>
      </div>
    </GenericModal>
  );
};
