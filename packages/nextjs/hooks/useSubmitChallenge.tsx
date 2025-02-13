import { useAccount } from "@starknet-react/core";
import axios from "axios";
import { useEffect } from "react";
import toast from "react-hot-toast";
import { getSocket } from "~~/services/socket";
import { useGlobalState } from "~~/services/store/store";
import { removeAnsiComprehensive } from "~~/utils/submission";
import { Cross2Icon } from "@radix-ui/react-icons";

const showMultiLineError = (errorMessages: string[]) => {
  const toastId = toast.error(
    <div className="flex justify-between items-start">
      <div className="flex-1 flex flex-col gap-2">
        {errorMessages.map((error) => (
          <p key={error}>
            {removeAnsiComprehensive(error).replace(/\n/g, " ")}
          </p>
        ))}
      </div>
      <button
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          toast.dismiss(toastId);
        }}
        className="ml-4 text-gray-500 hover:text-gray-700 rounded-full hover:bg-gray-100 transition-colors"
      >
        <Cross2Icon />
      </button>
    </div>,
    {
      duration: Infinity,
      style: {
        maxWidth: "800px",
      },
    },
  );
};

export const useSubmitChallenge = () => {
  const { submissionTopic, setSubmissionTopic } = useGlobalState();
  const { address } = useAccount();

  useEffect(() => {
    if (!submissionTopic) {
      return;
    }
    toast.dismiss();
    const toastId = toast.loading("Loading...");

    function onConnect() {
      toast.loading("0% Waiting for server verification", { id: toastId });
    }

    function onDisconnect() {
      setSubmissionTopic(undefined);
      toast.error("CONNECTION DISCONNECTED UNEXPECTED", { id: toastId });
    }

    function onSubmissionEvent(data: any) {
      if (data && data.status && data.progress && data.message) {
        toast.loading(`${data.progress}% ${data.message}`, { id: toastId });
        if (data.progress === 100) {
          setSubmissionTopic(undefined);
          if (data.success) {
            toast.success("SUCCESSFULLY SUBMITTED", { id: toastId });
            return;
          }
          if (
            data.details &&
            data.details.failedChecks &&
            Array.isArray(data.details.failedChecks) &&
            data.details.failedChecks.length > 0
          ) {
            toast.dismiss(toastId);
            showMultiLineError(data.details.failedChecks);
            return;
          }
          toast.error(data.message || "YOUR SUBMISSION FAILED", {
            id: toastId,
          });
        }
      }
    }

    const socket = getSocket();
    socket.on("connect", onConnect);
    socket.on("disconnect", onDisconnect);
    socket.on(`verification:${submissionTopic}`, onSubmissionEvent);

    return () => {
      socket.off("connect", onConnect);
      socket.off("disconnect", onDisconnect);
      socket.off(`verification:${submissionTopic}`, onSubmissionEvent);
    };
  }, [submissionTopic, setSubmissionTopic]);

  useEffect(() => {
    if (!address) {
      return;
    }
    axios
      .get(`${process.env.NEXT_PUBLIC_SERVER_BASE_URL}/verification/${address}`)
      .then((response) => {
        if (
          response.data &&
          response.data.data &&
          Array.isArray(response.data.data) &&
          response.data.data.length
        ) {
          const submission = response.data.data[0];
          if (!submissionTopic) {
            setSubmissionTopic(submission.verification_id);
          }
        }
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [address]);
};
