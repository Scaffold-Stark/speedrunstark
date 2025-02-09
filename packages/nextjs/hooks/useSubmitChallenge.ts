import { useEffect } from "react";
import toast from "react-hot-toast";
import { socket } from "~~/services/socket";
import { useGlobalState } from "~~/services/store/store";

export const useSubmitChallenge = () => {
  const { submissionTopic, setSubmissionStatus, setSubmissionTopic } =
    useGlobalState();

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
        }
      }
    }

    socket.on("connect", onConnect);
    socket.on("disconnect", onDisconnect);
    socket.on(`verification:${submissionTopic}`, onSubmissionEvent);

    return () => {
      socket.off("connect", onConnect);
      socket.off("disconnect", onDisconnect);
      socket.off(`verification:${submissionTopic}`, onSubmissionEvent);
    };
  }, [submissionTopic, setSubmissionStatus, setSubmissionTopic]);
};
