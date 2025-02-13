import { Challenge } from "~~/mockup/type";

const composeContracts = (
  challenge: Challenge,
  form: Record<string, string>,
) => {
  if (!challenge.inputURL) {
    return [];
  }
  if (challenge.id === "challenge-0-simple-nft") {
    return [form["sc"] || ""];
  } else if (challenge.id === "challenge-1-decentralized-staking") {
    return [form["staker"] || "", form["external"] || ""];
  } else if (challenge.id === "challenge-2-token-vendor") {
    return [form["vendor"] || "", form["yourToken"] || ""];
  } else if (challenge.id === "challenge-3-dice-game") {
    return [form["dicegame"] || "", form["riggedRoll"] || ""];
  }
  return [];
};

export const getChallengeId = (challengeId: string) => {
  const parts = challengeId.split("-");
  const challengeIndex = parts.length > 1 ? parts[1] : "";
  return `challenge-${challengeIndex}`;
};

export const composeSubmission = (
  challenge: Challenge,
  address: string,
  form: Record<string, string>,
) => {
  return {
    address,
    challengeId: getChallengeId(challenge.id),
    submission: {
      deployedUrl: form["deployed"] || "",
      contracts: composeContracts(challenge, form),
      repoUrl: form["github"] || "",
    },
  };
};

export const removeAnsiComprehensive = (str: string): string => {
  return str.replace(
    /[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g,
    "",
  );
};
