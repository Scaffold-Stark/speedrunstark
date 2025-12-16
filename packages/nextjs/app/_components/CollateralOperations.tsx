import React, { useMemo, useState } from "react";
import TooltipInfo from "./TooltipInfo";
import { parseEther } from "viem";
import { IntegerInput } from "~~/components/scaffold-stark";
import {
  useScaffoldMultiWriteContract,
  createContractCall,
} from "~~/hooks/scaffold-stark/useScaffoldMultiWriteContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { useScaffoldContract } from "~~/hooks/scaffold-stark/useScaffoldContract";

const CollateralOperations = () => {
  const [collateralAmount, setCollateralAmount] = useState("");
  const [withdrawAmount, setWithdrawAmount] = useState("");

  const { data: engineContractData } = useScaffoldContract({
    contractName: "MyUSDEngine",
  });

  const collateralAmountBigInt = useMemo(
    () => (collateralAmount ? parseEther(collateralAmount) : 0n),
    [collateralAmount],
  );

  const { sendAsync: addCollateralMulticall } = useScaffoldMultiWriteContract({
    calls: useMemo(
      () =>
        engineContractData?.address && collateralAmountBigInt > 0n
          ? [
              createContractCall("Strk", "approve", [
                engineContractData.address,
                collateralAmountBigInt,
              ]),
              createContractCall("MyUSDEngine", "add_collateral", [
                collateralAmountBigInt,
              ]),
            ]
          : [],
      [engineContractData?.address, collateralAmountBigInt],
    ),
  });

  const { sendAsync: withdrawCollateral } = useScaffoldWriteContract({
    contractName: "MyUSDEngine",
    functionName: "withdraw_collateral",
    args: [withdrawAmount ? parseEther(withdrawAmount) : 0n],
  });

  const handleAmountChange =
    (setter: (value: string) => void) => (value: string | bigint) => {
      if (typeof value === "bigint") {
        setter(value.toString());
        return;
      }
      setter(value);
    };

  const handleAddCollateral = async () => {
    try {
      await addCollateralMulticall();
      setCollateralAmount("");
    } catch (error) {
      console.error("Error adding collateral:", error);
    }
  };

  const handleWithdrawCollateral = async () => {
    try {
      await withdrawCollateral();
      setWithdrawAmount("");
    } catch (error) {
      console.error("Error withdrawing collateral:", error);
    }
  };

  return (
    <div className="card bg-base-100 w-96 shadow-xl indicator">
      <TooltipInfo
        top={3}
        right={3}
        infoText="Use these controls to add or withdraw collateral from the MyUSDEngine pool"
      />
      <div className="card-body">
        <h2 className="card-title">Collateral Operations (STRK)</h2>

        <div className="form-control">
          <label className="label">
            <span className="label-text">Add Collateral</span>
          </label>
          <div className="flex gap-2 items-center">
            <IntegerInput
              value={collateralAmount}
              onChange={handleAmountChange(setCollateralAmount)}
              placeholder="Amount"
              disableMultiplyBy1e18
            />
            <button
              className="btn btn-sm btn-primary"
              onClick={handleAddCollateral}
              disabled={!collateralAmount}
            >
              Add
            </button>
          </div>
        </div>

        <div className="form-control">
          <label className="label">
            <span className="label-text">Withdraw Collateral</span>
          </label>
          <div className="flex gap-2 items-center">
            <IntegerInput
              value={withdrawAmount}
              onChange={handleAmountChange(setWithdrawAmount)}
              placeholder="Amount"
              disableMultiplyBy1e18
            />
            <button
              className="btn btn-sm btn-primary"
              onClick={handleWithdrawCollateral}
              disabled={!withdrawAmount}
            >
              Withdraw
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CollateralOperations;
