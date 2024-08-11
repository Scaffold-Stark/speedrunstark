"use client";
import React from "react";
import { NextPage } from "next";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-stark/useScaffoldEventHistory";
import { Address } from "~~/components/scaffold-stark";
import { formatEther } from "ethers";

interface StakeEvent {
  args: {
    sender: string;
    amount: bigint;
  };
}
const Staking: NextPage = () => {
  // @ts-ignore
  const { data: stakeEvents, isLoading } = useScaffoldEventHistory<StakeEvent>({
    contractName: "Staker",
    eventName: "contracts::Staker::Staker::Stake",
    watch: true,
    fromBlock: 0n,
  });
  console.log(stakeEvents);

  if (isLoading)
    return (
      <div className="flex justify-center items-center mt-10">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );

  return (
    <div className="flex items-center flex-col flex-grow pt-10 text-neutral">
      <div className="px-5">
        <h1 className="text-center mb-3">
          <span className="block text-2xl font-bold">All Staking Events</span>
        </h1>
      </div>
      <div className="overflow-x-auto border border-secondary">
        <table className="table table-zebra w-full">
          <thead>
            <tr>
              <th className="bg-secondary text-white">From</th>
              <th className="bg-secondary text-white">Value</th>
            </tr>
          </thead>
          <tbody>
            {!stakeEvents || stakeEvents.length === 0 ? (
              <tr>
                <td colSpan={3} className="text-center">
                  No events found
                </td>
              </tr>
            ) : (
              stakeEvents?.map((event: StakeEvent, index) => {
                return (
                  <tr key={index}>
                    <td>
                      <Address address={`0x${event.args.sender}`} />
                    </td>
                    <td>
                      {event.args.amount &&
                        formatEther(BigInt(event.args.amount))}{" "}
                      ETH
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Staking;
