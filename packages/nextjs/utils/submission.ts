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

export const composeSubmission = (
  challenge: Challenge,
  address: string,
  form: Record<string, string>,
) => {
  const parts = challenge.id.split("-");
  const challengeIndex = parts.length > 1 ? parts[1] : "";
  return {
    address,
    challengeId: `challenge-${challengeIndex}`,
    submission: {
      deployedUrl: form["deployed"] || "",
      contracts: composeContracts(challenge, form),
      repoUrl: form["github"] || "",
    },
  };
};
