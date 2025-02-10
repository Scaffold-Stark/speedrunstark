import { useAccount } from "@starknet-react/core";
import axios from "axios";
import { useEffect } from "react";
import toast from "react-hot-toast";
import { getSocket } from "~~/services/socket";
import { useGlobalState } from "~~/services/store/store";

export const useSubmitChallenge = () => {
  const { submissionTopic, setSubmissionStatus, setSubmissionTopic } =
    useGlobalState();
  const { address } = useAccount();

  useEffect(() => {
    if (!submissionTopic) {
      return;
    }

    function onConnect() {
      setSubmissionStatus("0% Waiting for server verification");
    }

    function onDisconnect() {
      toast.error("CONNECTION DISCONNECTED UNEXPECTED");
    }

    function onSubmissionEvent(data: any) {
      if (data && data.status && data.progress && data.message) {
        setSubmissionStatus(`${data.progress}% ${data.message}`);
        if (data.progress === 100) {
          if (data.success) {
            toast.success("SUCCESSFULLY SUBMITTED");
          } else {
            toast.error("YOUR SUBMISSION FAILED");
          }
          setSubmissionTopic(undefined);
          setSubmissionStatus(undefined);
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
  }, [submissionTopic, setSubmissionStatus, setSubmissionTopic]);

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
