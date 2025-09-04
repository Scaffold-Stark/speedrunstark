"use client";

import type { NextPage } from "next";
import { Address } from "~~/components/scaffold-stark/Address";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-stark/useScaffoldEventHistory";
import { formatEther } from "ethers";

const Events: NextPage = () => {
  const { data: strkToTokenEvent, isLoading: isStrkToTokenEventLoading } =
    useScaffoldEventHistory({
      contractName: "Dex",
      eventName: "StrkToTokenSwap",
      fromBlock: 0n,
    });

  const { data: tokenToStrkEvent, isLoading: isTokenToStrkEventLoading } =
    useScaffoldEventHistory({
      contractName: "Dex",
      eventName: "TokenToStrkSwap",
      fromBlock: 0n,
    });

  const {
    data: liquidityProvideEvent,
    isLoading: isLquidityProvideEventLoading,
  } = useScaffoldEventHistory({
    contractName: "Dex",
    eventName: "LiquidityProvided",
    fromBlock: 0n,
  });

  const {
    data: liquidityRemovedEvent,
    isLoading: isLiquidityRemovedEventLoading,
  } = useScaffoldEventHistory({
    contractName: "Dex",
    eventName: "LiquidityRemoved",
    fromBlock: 0n,
  });

  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div>
        <div className="text-center mb-4">
          <span className="block text-2xl font-bold">
            STRK To Balloons Events
          </span>
        </div>
        {isStrkToTokenEventLoading ? (
          <div className="flex justify-center items-center mt-8">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="overflow-x-auto shadow-lg">
            <table className="table table-zebra w-full">
              <thead>
                <tr>
                  <th className="bg-secondary text-white">Address</th>
                  <th className="bg-secondary text-white">Amount of STRK in</th>
                  <th className="bg-secondary text-white">
                    Amount of Balloons out
                  </th>
                </tr>
              </thead>
              <tbody>
                {!strkToTokenEvent || strkToTokenEvent.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="text-center">
                      No events found
                    </td>
                  </tr>
                ) : (
                  strkToTokenEvent?.map((event, index) => {
                    return (
                      <tr key={index}>
                        <td className="text-center">
                          <Address
                            address={`0x${BigInt(event.args.swapper).toString(16)}`}
                          />
                        </td>
                        <td>{formatEther(event.args.strk_input).toString()}</td>
                        <td>
                          {formatEther(event.args.token_output).toString()}
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
      {
        <div className="mt-14">
          <div className="text-center mb-4">
            <span className="block text-2xl font-bold">
              Balloons To STRK Events
            </span>
          </div>
          {isTokenToStrkEventLoading ? (
            <div className="flex justify-center items-center mt-8">
              <span className="loading loading-spinner loading-lg"></span>
            </div>
          ) : (
            <div className="overflow-x-auto shadow-lg">
              <table className="table table-zebra w-full">
                <thead>
                  <tr>
                    <th className="bg-secondary text-white">Address</th>
                    <th className="bg-secondary text-white">
                      Amount of Balloons in
                    </th>
                    <th className="bg-secondary text-white">
                      Amount of STRK out
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {!tokenToStrkEvent || tokenToStrkEvent.length === 0 ? (
                    <tr>
                      <td colSpan={3} className="text-center">
                        No events found
                      </td>
                    </tr>
                  ) : (
                    tokenToStrkEvent?.map((event, index) => {
                      return (
                        <tr key={index}>
                          <td className="text-center">
                            <Address
                              address={`0x${BigInt(event.args.swapper).toString(16)}`}
                            />
                          </td>
                          <td>
                            {formatEther(event.args.tokens_input).toString()}
                          </td>
                          <td>
                            {formatEther(event.args.strk_output).toString()}
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
      }
      {/* ToDo Checkpoint 3: Uncomment Sell Token Events*/}
      {/* {<div className="mt-14">
        <div className="text-center mb-4">
          <span className="block text-2xl font-bold">Liquidity Provided Events</span>
        </div>
        {isLquidityProvideEventLoading ? (
          <div className="flex justify-center items-center mt-8">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="overflow-x-auto shadow-lg">
            <table className="table table-zebra w-full">
              <thead>
                <tr>
                  <th className="bg-secondary text-white">Address</th>
                  <th className="bg-secondary text-white">Amount of STRK in</th>
                  <th className="bg-secondary text-white">Amount of Ballons out</th>
                  <th className="bg-secondary text-white">Lİquidity Minted</th>
                </tr>
              </thead>
              <tbody>
                {!liquidityProvideEvent || liquidityProvideEvent.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="text-center">
                      No events found
                    </td>
                  </tr>
                ) : (
                    liquidityProvideEvent?.map((event, index) => {
                    return (
                      <tr key={index}>
                        <td className="text-center">
                          <Address
                          address={`0x${BigInt(event.args.liquidity_provider).toString(16)}`}
                           />
                        </td>
                        <td>{formatEther(event.args.strk_input).toString()}</td>
                        <td>
                          {formatEther(event.args.tokens_input).toString()}
                        </td>
                        <td>
                          {formatEther(event.args.liquidity_minted).toString()}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>} */}
      {/* ToDo Checkpoint 3: Uncomment Sell Token Events*/}
      {/* {<div className="mt-14">
        <div className="text-center mb-4">
          <span className="block text-2xl font-bold">Liquidity Removed Events</span>
        </div>
        {isLiquidityRemovedEventLoading ? (
          <div className="flex justify-center items-center mt-8">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <div className="overflow-x-auto shadow-lg">
            <table className="table table-zebra w-full">
              <thead>
                <tr>
                  <th className="bg-secondary text-white">Address</th>
                  <th className="bg-secondary text-white">Amount of STRK Out</th>
                  <th className="bg-secondary text-white">Amount of Balloons Out</th>
                  <th className="bg-secondary text-white">Liquidity Withdrawn</th>
                </tr>
              </thead>
              <tbody>
                {!liquidityRemovedEvent || liquidityRemovedEvent.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="text-center">
                      No events found
                    </td>
                  </tr>
                ) : (
                    liquidityRemovedEvent?.map((event, index) => {
                    return (
                      <tr key={index}>
                        <td className="text-center">
                          <Address
                          address={`0x${BigInt(event.args.liquidity_remover).toString(16)}`}
                           />
                        </td>
                        <td>{formatEther(event.args.strk_output).toString()}</td>
                        <td>
                          {formatEther(event.args.tokens_output).toString()}
                        </td>
                        <td>
                          {formatEther(event.args.liquidity_withdrawn).toString()}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>} */}
    </div>
  );
};

export default Events;
