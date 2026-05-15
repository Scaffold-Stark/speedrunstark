import React, { useMemo } from "react";
import { TokenSwapModal } from "./Modals/TokenSwapModal";
import { TokenTransferModal } from "./Modals/TokenTransferModal";
import TooltipInfo from "./TooltipInfo";
import { formatEther } from "viem";
import { hardhat } from "viem/chains";
import { useAccount } from "~~/hooks/useAccount";
import {
  ArrowsRightLeftIcon,
  PaperAirplaneIcon,
} from "@heroicons/react/24/outline";
import { useAnimationConfig } from "~~/hooks/scaffold-stark/useAnimationConfig";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { tokenName } from "~~/utils/constant";
import { decodeUint256Value } from "~~/utils/scaffold-stark/number";
import { devnet } from "@starknet-start/chains";

const TokenActions = () => {
  const { address, chainId: ConnectedChainId } = useAccount();
  const transferModalId = `${tokenName}-transfer-modal`;
  const swapModalId = `${tokenName}-swap-modal`;

  const { data: stablecoinBalance } = useScaffoldReadContract({
    contractName: "MyUSD",
    functionName: "balance_of",
    args: [address],
  });
  const stablecoinBalanceBigInt = useMemo(
    () => decodeUint256Value(stablecoinBalance),
    [stablecoinBalance],
  );

  const { data: strkMyUSDPrice } = useScaffoldReadContract({
    contractName: "Oracle",
    functionName: "get_strk_myusd_price",
  });
  const strkMyUSDPriceBigInt = useMemo(
    () => decodeUint256Value(strkMyUSDPrice),
    [strkMyUSDPrice],
  );

  const { data: strkUSDPrice } = useScaffoldReadContract({
    contractName: "Oracle",
    functionName: "get_strk_usd_price",
  });
  const strkUSDPriceBigInt = useMemo(
    () => decodeUint256Value(strkUSDPrice),
    [strkUSDPrice],
  );
  const strkPriceInUSD = Number(formatEther(strkUSDPriceBigInt || 0n));

  const myUSDPrice =
    1 / (Number(formatEther(strkMyUSDPriceBigInt || 0n)) / strkPriceInUSD);

  const tokenBalance = `${Math.floor(Number(formatEther(stablecoinBalanceBigInt || 0n)) * 100) / 100}`;
  const { showAnimation } = useAnimationConfig(stablecoinBalance);

  return (
    <div className="absolute mt-10 right-0 bg-base-100 w-fit border-base-300 border shadow-md rounded-xl z-10">
      <div className="w-[150px] py-5 flex flex-col items-center gap-1 indicator">
        <TooltipInfo
          top={3}
          right={3}
          infoText={`Here you can send ${tokenName} to any address or swap it`}
        />
        <div className="flex flex-col items-center gap-1">
          <span className="text-sm font-bold">{tokenName} Wallet</span>
          <span className="flex text-sm">
            <span
              className={`transition bg-transparent ${showAnimation ? "bg-warning rounded-xs animate-pulse-fast" : ""}`}
            >
              {tokenBalance}
            </span>
            &nbsp;
            {tokenName}
          </span>
          <span className="flex items-center text-xs">
            1 {tokenName} = &nbsp;
            <span
              className={`transition bg-transparent ${isNaN(myUSDPrice) ? "bg-gray-200 rounded animate-pulse" : ""}`}
            >
              {isNaN(myUSDPrice) ? "..." : `$${myUSDPrice.toFixed(5)}`}
            </span>
          </span>
          <div className="flex gap-2">
            <label
              htmlFor={`${transferModalId}`}
              className="btn btn-primary btn-circle btn-xs"
            >
              <PaperAirplaneIcon className="h-3 w-3" />
            </label>
            {ConnectedChainId === devnet.id && (
              <label
                htmlFor={`${swapModalId}`}
                className="btn btn-primary btn-circle btn-xs"
              >
                <ArrowsRightLeftIcon className="h-3 w-3" />
              </label>
            )}
          </div>
        </div>
      </div>
      <TokenTransferModal
        tokenBalance={tokenBalance}
        connectedAddress={address || ""}
        modalId={`${transferModalId}`}
      />
      <TokenSwapModal
        tokenBalance={tokenBalance}
        connectedAddress={address || ""}
        STRKprice={Number(formatEther(strkMyUSDPriceBigInt || 0n)).toFixed(2)}
        modalId={`${swapModalId}`}
      />
    </div>
  );
};

export default TokenActions;
