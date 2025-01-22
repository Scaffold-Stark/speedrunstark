import { useEffect, useState } from "react";
import { DATA_CHALLENGE_V2 } from "~~/mockup/data";
import { ChallengeModalDetail } from "./ChallengeModalDetailMB";
import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import { ChallengeItem } from "./ChallengeItem";
import { SubmitChallenge } from "./SubmitChallenge";
import { getMarkdownComponents } from "../GetMarkdownComponents/GetMarkdownComponents";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import ReactMarkdown from "react-markdown";
import { Challenge } from "~~/mockup/type";
import rehypeRaw from "rehype-raw";

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

export const ChallengeModal = ({ isOpen, onClose, title }: Props) => {
  const [openDetailMB, setOpenDetailMB] = useState(false);
  const [fetchState, setFetchState] = useState<FetchState>({
    loading: false,
    error: null,
    data: null,
  });
  const [selectedChallenge, setSelectedChallenge] = useState<Challenge>(
    DATA_CHALLENGE_V2[0],
  );
  const [isExpanded, setIsExpanded] = useState(false);

  const handleMoveonGithub = () => {
    window.open(
      `https://github.com/Scaffold-Stark/speedrunstark/tree/${selectedChallenge.id}`,
      "_blank",
    );
  };

  const handleSelectChallenge = (challenge: Challenge) => {
    setSelectedChallenge(challenge);
  };

  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  const handleCloseModal = () => {
    onClose();
    setIsExpanded(false);
    setSelectedChallenge(DATA_CHALLENGE_V2[0]);
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
          `https://raw.githubusercontent.com/Scaffold-Stark/speedrunstark/${selectedChallenge.id}/README.md`,
        );

        if (!response.ok) {
          throw new Error(`Failed to fetch markdown: ${response.statusText}`);
        }

        let markdownData = await response.text();
        const baseUrl = `https://raw.githubusercontent.com/Scaffold-Stark/speedrunstark/${selectedChallenge.id}/`;

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

    if (selectedChallenge.id) {
      getMarkdown();
    }
  }, [selectedChallenge.id]);

  if (openDetailMB) {
    return (
      <ChallengeModalDetail
        isOpen={openDetailMB}
        title={"Challenge"}
        content={fetchState.data}
        onClose={() => setOpenDetailMB(false)}
        loading={fetchState.loading}
        challenge={selectedChallenge}
      />
    );
  }

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`md:shadow-modal max-w-[1200px] w-full mx-auto md:p-[1px] md:rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
    >
      <div className={`w-full ${isExpanded ? "h-full flex flex-col" : ""}`}>
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
          <p className="text-xl relative z-30 uppercase font-vt323">{title}</p>
        </div>
        <div
          className={`flex flex-col md:flex-row ${isExpanded ? "flex-1 h-[calc(100%-60px)]" : ""}`}
        >
          <div>
            <p className="text-[#333333] font-vt323 text-center py-1">
              {DATA_CHALLENGE_V2.length} challenges available
            </p>
            <div>
              {DATA_CHALLENGE_V2.map((challenge) => (
                <ChallengeItem
                  key={challenge.id}
                  {...challenge}
                  active={challenge.id === selectedChallenge.id}
                  onSelect={() => handleSelectChallenge(challenge)}
                  onOpenDetail={() => setOpenDetailMB(true)}
                />
              ))}
            </div>
          </div>
          <div
            className={`lg:block hidden p-4 w-full bg-[#E5E5E5] challenge-content min-h-[600px] ${
              isExpanded
                ? "h-full overflow-y-auto"
                : "max-h-[600px] overflow-y-scroll"
            }`}
          >
            {/* <SubmitChallenge challenge={selectedChallenge} /> */}
            {fetchState.loading && (
              <div className="w-[850px] h-full flex items-center justify-center">
                <span className="text-[#4D58FF] loading loading-spinner loading-lg"></span>
              </div>
            )}

            {fetchState.error && (
              <div className="w-[850px] h-full flex flex-col items-center justify-center">
                <p className="text-lg font-semibold mb-2">
                  Error loading challenge content
                </p>
                <p className="text-sm">{fetchState.error}</p>
              </div>
            )}

            {!fetchState.loading && !fetchState.error && fetchState.data && (
              <div className="relative">
                <ReactMarkdown
                  rehypePlugins={[rehypeRaw]}
                  components={getMarkdownComponents()}
                >
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
