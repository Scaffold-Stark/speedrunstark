import React, { useEffect, useMemo, useState } from "react";
import TooltipInfo from "./TooltipInfo";
import UserPosition from "./UserPosition";
import { formatEther } from "viem";
import { useAccount } from "~~/hooks/useAccount";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-stark/useScaffoldEventHistory";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { decodeUint256Value } from "~~/utils/scaffold-stark/number";

const UserPositionsTable = () => {
  const { address: connectedAddress } = useAccount();
  const [users, setUsers] = useState<string[]>([]);
  const { data: events, isLoading } = useScaffoldEventHistory({
    contractName: "MyUSDEngine",
    eventName: "CollateralAdded",
    watch: true,
    blockData: false,
    transactionData: false,
    receiptData: false,
    fromBlock: 0n,
  });
  const { data: strkPrice } = useScaffoldReadContract({
    contractName: "Oracle",
    functionName: "get_strk_myusd_price",
  });
  const strkPriceBigInt = useMemo(
    () => decodeUint256Value(strkPrice),
    [strkPrice],
  );

  useEffect(() => {
    if (!events) return;

    setUsers((prevUsers) => {
      const uniqueUsers = new Set([...prevUsers]);
      events
        .filter((event) => event && event.args)
        .map((event) => event.parsedArgs?.user)
        .filter((user): user is string => !!user)
        .forEach((user) => uniqueUsers.add(user));
      return uniqueUsers.size > prevUsers.length
        ? Array.from(uniqueUsers)
        : prevUsers;
    });
  }, [events, users]);

  return (
    <div className="card bg-base-100 w-full shadow-xl indicator">
      <TooltipInfo
        top={3}
        right={3}
        infoText="Monitor all MyUSDEngine positions and liquidate undercollateralized accounts. Hover over the values (Collateral and Debt) to see the exact amounts."
      />
      <div className="overflow-x-auto">
        <table className="table">
          <thead>
            <tr>
              <th>Address</th>
              <th>Collateral</th>
              <th>Debt</th>
              <th>Ratio</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {isLoading || events === undefined ? (
              <tr key={"skeleton"}>
                <td>
                  <div className="skeleton w-36 h-6"></div>
                </td>
                <td>
                  <div className="skeleton w-16 h-6"></div>
                </td>
                <td>
                  <div className="skeleton w-16 h-6"></div>
                </td>
                <td>
                  <div className="skeleton w-16 h-6"></div>
                </td>
                <td>
                  <div className="skeleton w-20 h-6"></div>
                </td>
              </tr>
            ) : users.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center">
                  No user positions available
                </td>
              </tr>
            ) : (
              users.map((user) => (
                <UserPosition
                  key={user}
                  user={user}
                  connectedAddress={connectedAddress || ""}
                  strkPrice={Number(formatEther(strkPriceBigInt || 0n))}
                />
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default UserPositionsTable;
