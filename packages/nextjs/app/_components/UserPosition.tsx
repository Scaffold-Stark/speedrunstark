import React, { useMemo } from "react";
import { formatEther, parseEther } from "viem";
import { Address as AddressBlock } from "~~/components/scaffold-stark";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark/useDeployedContractInfo";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { collateralRatio, tokenName } from "~~/utils/constant";
import {
  calculatePositionRatio,
  formatDisplayValue,
  getRatioColorClass,
} from "~~/utils/helpers";
import { decodeUint256Value, notification } from "~~/utils/scaffold-stark";

type UserPositionProps = {
  user: string;
  strkPrice: number;
  connectedAddress: string;
};

const UserPosition = ({
  user,
  strkPrice,
  connectedAddress,
}: UserPositionProps) => {
  const { data: userCollateral } = useScaffoldReadContract({
    contractName: "MyUSDEngine",
    functionName: "get_user_collateral",
    args: [user],
  });
  const userCollateralBigInt = useMemo(
    () => decodeUint256Value(userCollateral),
    [userCollateral],
  );

  const { data: userMinted } = useScaffoldReadContract({
    contractName: "MyUSDEngine",
    functionName: "get_current_debt_value",
    args: [user],
  });
  const userMintedBigInt = useMemo(
    () => decodeUint256Value(userMinted),
    [userMinted],
  );

  const { data: stablecoinEngineContract } =
    useDeployedContractInfo("MyUSDEngine");

  const { data: allowance } = useScaffoldReadContract({
    contractName: "MyUSD",
    functionName: "allowance",
    args: [user, stablecoinEngineContract?.address],
  });

  const { sendAsync: liquidate, isPending: isLiquidating } =
    useScaffoldWriteContract({
      contractName: "MyUSDEngine",
      functionName: "liquidate",
      args: [user],
    });

  const { sendAsync: approve } = useScaffoldWriteContract({
    contractName: "MyUSD",
    functionName: "approve",
    args: [
      stablecoinEngineContract?.address,
      BigInt(
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      ),
    ],
  });

  const mintedAmount = Number(formatEther(userMintedBigInt || 0n));
  const ratio =
    mintedAmount === 0
      ? "N/A"
      : calculatePositionRatio(
          Number(formatEther(userCollateralBigInt || 0n)),
          mintedAmount,
          strkPrice,
        );

  const formattedRatio =
    ratio === "N/A"
      ? "N/A"
      : typeof ratio === "number" && ratio >= 9999
        ? ">9999"
        : ratio.toFixed(2);

  const isPositionSafe = ratio == "N/A" || Number(ratio) >= collateralRatio;
  const liquidatePosition = async () => {
    if (
      allowance === undefined ||
      userMinted === undefined ||
      stablecoinEngineContract === undefined
    )
      return;
    try {
      if (allowance < userMinted) {
        await approve();
      }
      await liquidate();
      const mintedValue =
        Number(formatEther(userMintedBigInt || 0n)) / strkPrice;
      const totalCollateral = Number(formatEther(userCollateralBigInt || 0n));
      const rewardValue =
        mintedValue * 1.1 > totalCollateral
          ? totalCollateral.toFixed(2)
          : (mintedValue * 1.1).toFixed(2);
      const shortAddress = user.slice(0, 6) + "..." + user.slice(-4);
      notification.success(
        <>
          <p className="font-bold mt-0 mb-1">Liquidation successful</p>
          <p className="m-0">You liquidated {shortAddress}&apos;s position.</p>
          <p className="m-0">
            You repaid {Number(formatEther(userMintedBigInt || 0n)).toFixed(2)}{" "}
            {tokenName} and received {rewardValue} in STRK collateral.
          </p>
        </>,
      );
    } catch (e) {
      console.error("Error liquidating position:", e);
    }
  };

  if (userCollateralBigInt === parseEther("10000000000000000000")) return null;

  return (
    <tr
      key={user}
      className={`${connectedAddress === user ? "bg-primary" : ""}`}
    >
      <td>
        <AddressBlock
          address={user as `0x${string}`}
          disableAddressLink
          format="short"
          size="sm"
        />
      </td>
      <td>
        <div
          className="tooltip tooltip-primary"
          data-tip={`${Number(formatEther(userCollateralBigInt || 0n)).toFixed(2)} STRK`}
        >
          {formatDisplayValue(Number(formatEther(userCollateralBigInt || 0n)))}
        </div>
      </td>
      <td>
        <div
          className="tooltip tooltip-primary"
          data-tip={`${Number(formatEther(userMintedBigInt || 0n)).toFixed(2)} ${tokenName}`}
        >
          {formatDisplayValue(Number(formatEther(userMintedBigInt || 0n)))}
        </div>
      </td>
      <td className={getRatioColorClass(ratio)}>
        {formattedRatio === "N/A" ? "N/A" : `${formattedRatio}%`}
      </td>
      <td className="text-center p-1">
        <button
          onClick={liquidatePosition}
          disabled={isPositionSafe}
          className="btn btn-xs btn-ghost"
        >
          {isLiquidating ? (
            <span className="loading loading-spinner loading-sm"></span>
          ) : (
            "Liquidate"
          )}
        </button>
      </td>
    </tr>
  );
};

export default UserPosition;
