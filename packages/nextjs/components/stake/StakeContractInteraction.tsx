"use client";

import { useAccount, useBalance } from "@starknet-react/core";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark";
import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import { useScaffoldContractRead } from "~~/hooks/scaffold-stark/useScaffoldContractRead";
import { useScaffoldContractWrite } from "~~/hooks/scaffold-stark/useScaffoldContractWrite";
import { ETHToPrice } from "~~/components/stake/ETHToPrice";
import { Address } from "~~/components/scaffold-stark";
import { ethers } from "ethers";
import humanizeDuration from "humanize-duration";
import { uint256 } from "starknet-dev";
import { BigNumberish } from "starknet";
import { useScaffoldMultiContractWrite } from "~~/hooks/scaffold-stark/useScaffoldMultiContractWrite";

export const StakeContractInteraction = ({ address }: { address?: string }) => {
  const { address: connectedAddress } = useAccount();
  const { data: StakerContract } = useDeployedContractInfo("Challenge1");
  const { data: ExampleExternalContact } = useDeployedContractInfo(
    "ExampleExternalContract",
  );
  const { data: stakerContractBalance } = useBalance({
    address: StakerContract?.address,
  });
  const { data: exampleExternalContractBalance } = useBalance({
    address: ExampleExternalContact?.address,
  });

  const { targetNetwork } = useTargetNetwork();

  // Contract Read Actions
  const { data: threshold } = useScaffoldContractRead({
    contractName: "Challenge1",
    functionName: "threshold",
    watch: true,
  });
  const { data: timeLeft } = useScaffoldContractRead({
    contractName: "Challenge1",
    functionName: "time_left",
    watch: true,
  });

  const { data: isStakingCompleted } = useScaffoldContractRead({
    contractName: "Challenge1",
    functionName: "completed",
    watch: true,
  });
  const { data: myStake } = useScaffoldContractRead({
    contractName: "Challenge1",
    functionName: "balances",
    args: [connectedAddress ?? ""],
    watch: true,
  });

  // Contract Write Actions
  const { writeAsync: stakeStark } = useScaffoldContractWrite({
    contractName: "Challenge1",
    functionName: "stake",
    args: [BigInt(0)],
  });
  const { writeAsync: execute } = useScaffoldContractWrite({
    contractName: "Challenge1",
    functionName: "execute",
  });
  const { writeAsync: withdrawETH } = useScaffoldContractWrite({
    contractName: "Challenge1",
    functionName: "withdraw",
  });

  const { writeAsync: stakeEth } = useScaffoldMultiContractWrite({
    calls: [
      {
        contractName: "Eth",
        functionName: "approve",
        args: [StakerContract?.address ?? "", 5 * 10 ** 17],
      },
      {
        contractName: "Challenge1",
        functionName: "stake",
        args: [5 * 10 ** 17],
      },
    ],
  });

  const wrapInTryCatch =
    (fn: () => Promise<any>, errorMessageFnDescription: string) => async () => {
      try {
        await fn();
      } catch (error) {
        console.error(
          `Error calling ${errorMessageFnDescription} function`,
          error,
        );
      }
    };

  return (
    <div className="flex items-center flex-col flex-grow w-full px-4 gap-12">
      {isStakingCompleted && (
        <div className="flex flex-col items-center gap-2 bg-base-100 border-8 border-secondary  rounded-xl p-6 mt-12 w-full max-w-lg">
          <p className="block m-0 font-semibold">
            🎉 &nbsp; Staking App triggered `ExampleExternalContract` &nbsp; 🎉{" "}
          </p>
          <div className="flex items-center">
            <ETHToPrice
              value={
                exampleExternalContractBalance != null
                  ? exampleExternalContractBalance.toString()
                  : undefined
              }
              className="text-[1rem]"
            />
            <p className="block m-0 text-lg -ml-1">staked !!</p>
          </div>
        </div>
      )}
      <div
        className={`flex flex-col items-center space-y-8 bg-base-100  border-8 border-primary rounded-xl p-6 w-full max-w-lg ${
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
            <p className="block text-xl mt-0 mb-1 font-semibold">Time Left</p>
            <p className="m-0 p-0">
              {timeLeft ? `${humanizeDuration(Number(timeLeft) * 1000)}` : 0}
            </p>
          </div>
          <div className="flex flex-col items-center w-1/2">
            <p className="block text-xl mt-0 mb-1 font-semibold">You Staked</p>
            <span>
              {myStake
                ? `${myStake} ${targetNetwork.nativeCurrency.symbol}`
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
                    ? stakerContractBalance.formatted
                    : undefined
                }
              />
            }
            <span>/</span>
            {<ETHToPrice value={threshold ? `${threshold}` : undefined} />}
          </div>
        </div>
        <div className="flex flex-col space-y-5">
          <div className="flex space-x-7">
            <button
              className="btn btn-primary uppercase text-base-100"
              onClick={wrapInTryCatch(execute, "execute")}
            >
              Execute!
            </button>
            <button
              className="btn btn-primary uppercase text-base-100"
              onClick={wrapInTryCatch(withdrawETH, "stakeETH")}
            >
              Withdraw
            </button>
          </div>
          <button
            className="btn btn-primary uppercase text-base-100"
            onClick={wrapInTryCatch(stakeEth, "stakeETH")}
          >
            🥩 Stake 0.5 ether!
          </button>
        </div>
      </div>
    </div>
  );
};
