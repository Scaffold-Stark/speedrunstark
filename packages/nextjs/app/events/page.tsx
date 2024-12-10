"use client";

import type { NextPage } from "next";
import { Address } from "~~/components/scaffold-stark/Address";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-stark/useScaffoldEventHistory";
import { formatEther } from "ethers";

const Events: NextPage = () => {
  const { data: buyTokenEvents, isLoading: isBuyEventsLoading } =
    useScaffoldEventHistory({
      contractName: "Vendor",
      eventName: "contracts::Vendor::Vendor::BuyTokens",
      fromBlock: 0n,
    });

  const { data: sellTokenEvents, isLoading: isSellEventsLoading } =
    useScaffoldEventHistory({
      contractName: "Vendor",
      eventName: "contracts::Vendor::Vendor::SellTokens",
      fromBlock: 0n,
    });

  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div>
        <div className="text-center mb-4">
          <span className="block text-2xl font-bold">Buy Token Events</span>
        </div>
        {isBuyEventsLoading ? (
          <div className="flex justify-center items-center mt-8">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="overflow-x-auto shadow-lg">
            <table className="table table-zebra w-full">
              <thead>
                <tr>
                  <th className="bg-secondary text-white">Buyer</th>
                  <th className="bg-secondary text-white">Amount of ETH</th>
                  <th className="bg-secondary text-white">Amount of Tokens</th>
                </tr>
              </thead>
              <tbody>
                {!buyTokenEvents || buyTokenEvents.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="text-center">
                      No events found
                    </td>
                  </tr>
                ) : (
                  buyTokenEvents?.map((event, index) => {
                    return (
                      <tr key={index}>
                        <td className="text-center">
                          <Address
                            address={`0x${BigInt(event.args.buyer).toString(16)}`}
                          />
                        </td>
                        <td>{formatEther(event.args.eth_amount).toString()}</td>
                        <td>
                          {formatEther(event.args.tokens_amount).toString()}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
      {/* ToDo Checkpoint 3: Uncomment Sell Token Events*/}
      {/*<div className="mt-14">
        <div className="text-center mb-4">
          <span className="block text-2xl font-bold">Sell Token Events</span>
        </div>
        {isSellEventsLoading ? (
          <div className="flex justify-center items-center mt-8">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="overflow-x-auto shadow-lg">
            <table className="table table-zebra w-full">
              <thead>
                <tr>
                  <th className="bg-secondary text-white">Seller</th>
                  <th className="bg-secondary text-white">Amount of ETH</th>
                  <th className="bg-secondary text-white">Amount of Tokens</th>
                </tr>
              </thead>
              <tbody>
                {!sellTokenEvents || sellTokenEvents.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="text-center">
                      No events found
                    </td>
                  </tr>
                ) : (
                  sellTokenEvents?.map((event, index) => {
                    return (
                      <tr key={index}>
                        <td className="text-center">
                          <Address 
                          address={`0x${BigInt(event.args.seller).toString(16)}`}
                           />
                        </td>
                        <td>{formatEther(event.args.eth_amount).toString()}</td>
                        <td>
                          {formatEther(event.args.tokens_amount).toString()}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>*/}
    </div>
  );
};

export default Events;
