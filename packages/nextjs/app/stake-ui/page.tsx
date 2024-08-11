"use client";

import type { NextPage } from "next";
import { StakeContractInteraction } from "~~/components/stake/StakeContractInteraction";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark";

const StakerUI: NextPage = () => {
  const { data: StakerContract } = useDeployedContractInfo("Staker");

  return (
    <StakeContractInteraction
      key={StakerContract?.address}
      address={StakerContract?.address}
    />
  );
};

export default StakerUI;
