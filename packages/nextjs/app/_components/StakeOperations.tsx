import React, { useEffect, useMemo, useState } from "react";
import TooltipInfo from "./TooltipInfo";
import { parseEther } from "viem";
import { useAccount } from "~~/hooks/useAccount";
import { IntegerInput } from "~~/components/scaffold-stark";
import { useScaffoldContract } from "~~/hooks/scaffold-stark/useScaffoldContract";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import {
  useScaffoldMultiWriteContract,
  createContractCall,
} from "~~/hooks/scaffold-stark/useScaffoldMultiWriteContract";
import { notification } from "~~/utils/scaffold-stark";
import { decodeUint256Value } from "~~/utils/scaffold-stark/number";

const StakeOperations = () => {
  const { address } = useAccount();
  const [stakeAmount, setStakeAmount] = useState("");
  const [withdrawDisabled, setWithdrawDisabled] = useState(true);

  const { data: myUSDCStakingContract } = useScaffoldContract({
    contractName: "MyUSDStaking",
  });

  const stakeAmountBigInt = useMemo(
    () => (stakeAmount ? parseEther(stakeAmount) : 0n),
    [stakeAmount],
  );

  const { sendAsync: stakeMulticall } = useScaffoldMultiWriteContract({
    calls: useMemo(
      () =>
        myUSDCStakingContract?.address && stakeAmountBigInt > 0n
          ? [
              createContractCall("MyUSD", "approve", [
                myUSDCStakingContract.address,
                stakeAmountBigInt,
              ]),
              createContractCall("MyUSDStaking", "stake", [stakeAmountBigInt]),
            ]
          : [],
      [myUSDCStakingContract?.address, stakeAmountBigInt],
    ),
  });

  const { sendAsync: withdraw } = useScaffoldWriteContract({
    contractName: "MyUSDStaking",
    functionName: "withdraw",
    args: [],
  });

  const { data: totalShares } = useScaffoldReadContract({
    contractName: "MyUSDStaking",
    functionName: "total_shares",
    args: [address],
  });

  useEffect(() => {
    setWithdrawDisabled(
      totalShares ? decodeUint256Value(totalShares) === 0n : true,
    );
  }, [totalShares]);

  const handleStake = async () => {
    try {
      await stakeMulticall();
      setStakeAmount("");
    } catch (error) {
      console.error("Error staking:", error);
    }
  };

  const handleWithdraw = async () => {
    try {
      await withdraw();
    } catch (error) {
      console.error("Error withdrawing:", error);
    }
  };

  const handleAmountChange =
    (setter: (value: string) => void) => (value: string | bigint) => {
      setter(typeof value === "bigint" ? value.toString() : value);
    };

  return (
    <div className="card bg-base-100 w-96 shadow-xl indicator">
      <TooltipInfo
        top={3}
        right={3}
        infoText="Use these controls to stake or unstake MyUSD"
      />
      <div className="card-body">
        <h2 className="card-title">Stake Operations (MyUSD)</h2>

        <div className="form-control">
          <label className="label">
            <span className="label-text">Stake</span>
          </label>
          <div className="flex gap-2 items-center">
            <IntegerInput
              value={stakeAmount}
              onChange={handleAmountChange(setStakeAmount)}
              placeholder="Amount"
              disableMultiplyBy1e18
            />
            <button
              className="btn btn-sm btn-primary"
              onClick={handleStake}
              disabled={!stakeAmount}
            >
              Stake
            </button>
          </div>
        </div>

        <div className="form-control">
          <label className="label">
            <span className="label-text">Withdraw</span>
          </label>
          <div className="flex gap-2 items-center">
            <button
              className="btn btn-sm btn-primary"
              onClick={handleWithdraw}
              disabled={withdrawDisabled}
            >
              Withdraw
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StakeOperations;
