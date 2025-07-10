"use client";

import type { NextPage } from "next";
import { Address } from "~~/components/scaffold-stark";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-stark/useScaffoldEventHistory";

const Transfers: NextPage = () => {
  const { data: transferEvents, isLoading } = useScaffoldEventHistory({
    contractName: "YourCollectible",
    eventName: "Transfer",
    fromBlock: 0n,
    watch: true,
  });

  //console.log(transferEvents)
  if (isLoading)
    return (
      <div className="flex justify-center items-center mt-10">
        <span className="loading loading-spinner loading-xl"></span>
      </div>
    );

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-4xl font-bold">
              All Transfers Events
            </span>
          </h1>
        </div>
        <div className="overflow-x-auto shadow-lg">
          <table className="table table-zebra w-full">
            <thead>
              <tr>
                <th className="bg-secondary text-white">Token Id</th>
                <th className="bg-secondary text-white">From</th>
                <th className="bg-secondary text-white">To</th>
              </tr>
            </thead>
            <tbody>
              {!transferEvents || transferEvents.length === 0 ? (
                <tr>
                  <td colSpan={3} className="text-center">
                    No events found
                  </td>
                </tr>
              ) : (
                transferEvents?.map((event, index) => {
                  return (
                    <tr key={index}>
                      <th className="text-center">
                        {event.args.token_id?.toString()}
                      </th>
                      <td>
                        {" "}
                        <Address
                          address={`0x${event.args.from.toString(16)}`}
                        />{" "}
                      </td>
                      <td>
                        {" "}
                        <Address
                          address={`0x${event.args.to.toString(16)}`}
                        />{" "}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
};

export default Transfers;
