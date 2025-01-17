import { useEffect, useState } from "react";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import Image from "next/image";
import ReactMarkdown from "react-markdown";
import { getMarkdownComponents } from "../GetMarkdownComponents/GetMarkdownComponents";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { DATA_CHALLENGE_V2 } from "~~/mockup/data";
import { ComingSoon } from "../Tooltips/Comingsoon";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

type FetchState = {
  loading: boolean;
  error: string | null;
  data: string | null;
};

const ChallengeItem = ({
  id,
  name,
  active,
  comming,
  isBurn,
  onSelect,
}: {
  id: string;
  name: string;
  active?: boolean;
  comming?: boolean;
  isBurn?: boolean;
  onSelect: (id: string) => void;
}) => {
  const [isHovering, setIsHovering] = useState(false);
  return (
    <div
      className={`flex items-center gap-3 p-4 border-b border-[#000] max-w-[300px] w-full ${
        comming ? "cursor-not-allowed" : "cursor-pointer"
      }`}
      style={{
        background: active ? "#E5E5E5" : "white",
      }}
      onClick={() => !comming && onSelect(id)}
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

export const ChallengeModal = ({ isOpen, onClose, title }: Props) => {
  const [fetchState, setFetchState] = useState<FetchState>({
    loading: false,
    error: null,
    data: null,
  });
  const [selectedId, setSelectedId] = useState<string>(DATA_CHALLENGE_V2[0].id);
  const [isExpanded, setIsExpanded] = useState(false);

  const handleMoveonGithub = () => {
    window.open(
      `https://github.com/Scaffold-Stark/speedrunstark/tree/${selectedId}`,
      "_blank",
    );
  };

  const handleSelectChallenge = (id: string) => {
    setSelectedId(id);
  };

  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  const handleCloseModal = () => {
    onClose();
    setIsExpanded(false);
    setSelectedId(DATA_CHALLENGE_V2[0].id);
  };

  useEffect(() => {
    const getMarkdown = async () => {
      setFetchState({
        loading: true,
        error: null,
        data: null,
      });

      try {
        const response = await fetch(
          `https://raw.githubusercontent.com/Scaffold-Stark/speedrunstark/${selectedId}/README.md`,
        );

        if (!response.ok) {
          throw new Error(`Failed to fetch markdown: ${response.statusText}`);
        }

        let markdownData = await response.text();
        const baseUrl = `https://raw.githubusercontent.com/Scaffold-Stark/speedrunstark/${selectedId}/`;

        markdownData = markdownData.replace(
          /!\[(.*?)\]\((?!https?)(.*?)\)/g,
          `![$1](${baseUrl}$2)`,
        );

        setFetchState({
          loading: false,
          error: null,
          data: markdownData,
        });
      } catch (error) {
        setFetchState({
          loading: false,
          error:
            error instanceof Error
              ? error.message
              : "An error occurred while fetching the content",
          data: null,
        });
      }
    };

    if (selectedId) {
      getMarkdown();
    }
  }, [selectedId]);

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`shadow-modal w-[1200px] mx-auto p-[1px] rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
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
        <div
          className={`flex ${isExpanded ? "flex-1 h-[calc(100%-60px)]" : ""}`}
        >
          <div>
            <p className="text-[#333333] font-vt323 text-center py-1">
              12 challenges available
            </p>
            <div>
              {DATA_CHALLENGE_V2.map((item) => (
                <ChallengeItem
                  key={item.id}
                  {...item}
                  active={item.id === selectedId}
                  onSelect={handleSelectChallenge}
                />
              ))}
            </div>
          </div>
          <div
            className={`p-4 w-full bg-[#E5E5E5] challenge-content min-h-[600px] ${
              isExpanded
                ? "h-full overflow-y-auto"
                : "max-h-[600px] overflow-y-scroll"
            }`}
          >
            <div className="fixed z-50 bottom-5 transform -translate-x-[62%] left-[62%] flex items-center gap-2 bg-[#4D58FF] w-fit px-4 py-3 cursor-pointer">
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
            {fetchState.loading && (
              <div className="w-full h-full flex items-center justify-center">
                <span className="text-[#4D58FF] loading loading-spinner loading-lg"></span>
              </div>
            )}

            {fetchState.error && (
              <div className="w-full h-full flex flex-col items-center justify-center">
                <p className="text-lg font-semibold mb-2">
                  Error loading challenge content
                </p>
                <p className="text-sm">{fetchState.error}</p>
              </div>
            )}

            {!fetchState.loading && !fetchState.error && fetchState.data && (
              <div className="relative">
                <ReactMarkdown components={getMarkdownComponents()}>
                  {fetchState.data}
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
      </div>
    </GenericModal>
  );
};
