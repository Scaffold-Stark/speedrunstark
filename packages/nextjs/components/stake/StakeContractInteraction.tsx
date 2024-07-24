"use client";

import { useAccount, useBalance } from "@starknet-react/core";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark";
import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { ETHToPrice } from "~~/components/stake/ETHToPrice";
import { Address } from "~~/components/scaffold-stark";
import humanizeDuration from "humanize-duration";
import { useScaffoldMultiWriteContract } from "~~/hooks/scaffold-stark/useScaffoldMultiWriteContract";

function formatEther(weiValue: number) {
  const etherValue = weiValue / 1e18;
  return etherValue.toFixed(1);
}

export const StakeContractInteraction = ({ address }: { address?: string }) => {
  const { address: connectedAddress } = useAccount();
  const { data: StakerContract } = useDeployedContractInfo("Staker");
  const { data: ExampleExternalContact } = useDeployedContractInfo(
    "ExampleExternalContract",
  );
  const { data: stakerContractBalance, refetch: refetchStakeContract } =
    useBalance({
      address: StakerContract?.address,
    });
  const {
    data: exampleExternalContractBalance,
    refetch: refetchExampleExternalContract,
  } = useBalance({
    address: ExampleExternalContact?.address,
  });

  const { targetNetwork } = useTargetNetwork();

  // Contract Read Actions
  const { data: threshold } = useScaffoldReadContract({
    contractName: "Staker",
    functionName: "threshold",
    watch: true,
  });
  const { data: timeLeft } = useScaffoldReadContract({
    contractName: "Staker",
    functionName: "time_left",
    watch: true,
  });

  const { data: isStakingCompleted } = useScaffoldReadContract({
    contractName: "Staker",
    functionName: "completed",
    watch: true,
  });
  const { data: myStake } = useScaffoldReadContract({
    contractName: "Staker",
    functionName: "balances",
    args: [connectedAddress ?? ""],
    watch: true,
  });

  const { writeAsync: execute } = useScaffoldWriteContract({
    contractName: "Staker",
    functionName: "execute",
  });
  const { writeAsync: withdrawETH } = useScaffoldWriteContract({
    contractName: "Staker",
    functionName: "withdraw",
  });

  const { writeAsync: stakeEth } = useScaffoldMultiWriteContract({
    calls: [
      {
        contractName: "Eth",
        functionName: "approve",
        args: [StakerContract?.address ?? "", 5 * 10 ** 17],
      },
      {
        contractName: "Staker",
        functionName: "stake",
        args: [5 * 10 ** 17],
      },
    ],
  });

  const wrapInTryCatch =
    (fn: () => Promise<any>, errorMessageFnDescription: string) => async () => {
      try {
        await fn().then(() => {
          refetchStakeContract();
          refetchExampleExternalContract();
        });
      } catch (error) {
        console.error(
          `Error calling ${errorMessageFnDescription} function`,
          error,
        );
      }
    };

  return (
    <div className="flex items-center flex-col flex-grow w-full px-4 gap-12 text-neutral justify-center">
      {isStakingCompleted && (
        <div className="flex flex-col items-center gap-2 bg-base-100 border-8 border-secondary  rounded-xl p-6 mt-12 w-full max-w-lg">
          <p className="block m-0 font-semibold text-neutral">
            🎉 &nbsp; Staking App triggered `ExampleExternalContract` &nbsp; 🎉{" "}
          </p>
          <div className="flex items-center">
            <ETHToPrice
              value={
                exampleExternalContractBalance != null
                  ? exampleExternalContractBalance.formatted
                  : undefined
              }
              className="text-[1rem]"
            />
            <p className="block m-0 text-lg -ml-1 text-neutral">staked !!</p>
          </div>
        </div>
      )}
      <div
        className={`flex flex-col items-center space-y-8 bg-base-100  border-8 border-secondary rounded-xl p-6 w-full max-w-lg text-neutral${
          !isStakingCompleted ? "mt-24" : ""
        }`}
      >
        <div className="flex flex-col w-full items-center">
          <p className="block text-2xl mt-0 mb-2 font-semibold">
            Staker Contract
          </p>
          <Address address={StakerContract?.address} size="xl" />
        </div>
        <div className="flex items-start justify-around w-full">
          <div className="flex flex-col items-center justify-center w-1/2">
            <p className="block text-xl mt-0 mb-1 font-semibold text-neutral">
              Time Left
            </p>
            <p className="m-0 p-0">
              {timeLeft
                ? `${humanizeDuration(Number(timeLeft) * 1000)} left`
                : "0"}
            </p>
          </div>
          <div className="flex flex-col items-center w-1/2">
            <p className="block text-xl mt-0 mb-1 font-semibold text-neutral">
              You Staked
            </p>
            <span>
              {myStake
                ? `${formatEther(Number(myStake))} ${targetNetwork.nativeCurrency.symbol}`
                : "0"}
            </span>
          </div>
        </div>
        <div className="flex flex-col items-center shrink-0 w-full">
          <p className="block text-xl mt-0 mb-1 font-semibold">Total Staked</p>
          <div className="flex space-x-2">
            {
              <ETHToPrice
                value={
                  stakerContractBalance != null
                    ? `${formatEther(Number(stakerContractBalance.value))}${targetNetwork.nativeCurrency.symbol}`
                    : undefined
                }
              />
            }
            <span>/</span>
            {
              <ETHToPrice
                value={
                  threshold
                    ? `${formatEther(Number(threshold))} ${targetNetwork.nativeCurrency.symbol}`
                    : undefined
                }
              />
            }
          </div>
        </div>
        <div className="flex flex-col space-y-5">
          <div className="flex space-x-7">
            <button
              className="btn btn-secondary uppercase text-white"
              onClick={wrapInTryCatch(execute, "execute")}
            >
              Execute!
            </button>
            <button
              className="btn btn-secondary uppercase text-white"
              onClick={wrapInTryCatch(withdrawETH, "stakeETH")}
            >
              Withdraw
            </button>
          </div>
          <button
            className="btn btn-secondary uppercase text-white"
            onClick={wrapInTryCatch(stakeEth, "stakeETH")}
          >
            🥩 Stake 0.5 ether!
          </button>
        </div>
      </div>
    </div>
  );
};
