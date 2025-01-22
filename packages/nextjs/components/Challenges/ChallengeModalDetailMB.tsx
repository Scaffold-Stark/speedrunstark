import Image from "next/image";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { getMarkdownComponents } from "../GetMarkdownComponents/GetMarkdownComponents";
import ReactMarkdown from "react-markdown";
import { SubmitChallenge } from "./SubmitChallenge";
import { Challenge } from "~~/mockup/type";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  content: any;
  loading: boolean;
  challenge: Challenge;
};

export const ChallengeModalDetail = ({
  isOpen,
  onClose,
  title,
  content,
  loading,
  challenge,
}: Props) => {
  const handleCloseModal = () => {
    onClose();
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
              <ReactMarkdown components={getMarkdownComponents()}>
                {content}
              </ReactMarkdown>
            </div>
          )}
        </div>
      </div>
    </GenericModal>
  );
};
