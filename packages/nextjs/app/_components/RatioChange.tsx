import React, { useMemo } from "react";
import { formatEther } from "viem";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { calculatePositionRatio, getRatioColorClass } from "~~/utils/helpers";
import { decodeUint256Value } from "~~/utils/scaffold-stark";

type UserPositionProps = {
  user: string;
  strkPrice: number;
  inputAmount: number;
};

const RatioChange = ({ user, strkPrice, inputAmount }: UserPositionProps) => {
  const { data: userCollateral } = useScaffoldReadContract({
    contractName: "MyUSDEngine",
    functionName: "get_user_collateral",
    args: [user],
  });

  const { data: userMinted } = useScaffoldReadContract({
    contractName: "MyUSDEngine",
    functionName: "get_current_debt_value",
    args: [user],
  });

  const userCollateralBigInt = useMemo(
    () => decodeUint256Value(userCollateral),
    [userCollateral],
  );

  const userMintedBigInt = useMemo(
    () => decodeUint256Value(userMinted),
    [userMinted],
  );

  const mintedAmount = Number(formatEther(userMintedBigInt || 0n));
  const ratio =
    mintedAmount === 0
      ? "N/A"
      : calculatePositionRatio(
          Number(formatEther(userCollateralBigInt || 0n)),
          mintedAmount,
          strkPrice,
        );

  const getNewRatio = (mintedAmount: number, inputAmount: number) => {
    const newMintedAmount = mintedAmount + inputAmount;
    if (newMintedAmount < 0) {
      return <span className={getRatioColorClass(1)}>N/A</span>;
    } else if (newMintedAmount === 0) {
      return <span className={getRatioColorClass(1000)}>∞</span>;
    }
    const newRatio = calculatePositionRatio(
      Number(formatEther(userCollateralBigInt || 0n)),
      newMintedAmount,
      strkPrice,
    );
    return (
      <span className={getRatioColorClass(newRatio)}>
        {newRatio > 9999 ? ">9999" : newRatio.toFixed(2)}%
      </span>
    );
  };

  if (inputAmount === 0 || isNaN(inputAmount)) {
    return null;
  }

  return (
    <div className="text-sm">
      {ratio === "N/A" ? (
        <span className={`${getRatioColorClass(1000)}`}>∞</span>
      ) : (
        <span className={`${getRatioColorClass(ratio)} mx-0`}>
          {ratio > 9999 ? ">9999" : ratio.toFixed(2)}%
        </span>
      )}{" "}
      → {getNewRatio(mintedAmount, inputAmount)}
    </div>
  );
};

export default RatioChange;
