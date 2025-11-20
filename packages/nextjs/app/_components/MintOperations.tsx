import React, { useMemo, useState } from "react";
import RatioChange from "./RatioChange";
import TooltipInfo from "./TooltipInfo";
import { formatEther, parseEther } from "viem";
import { useAccount } from "~~/hooks/useAccount";
import { IntegerInput } from "~~/components/scaffold-stark";
import { useScaffoldContract } from "~~/hooks/scaffold-stark/useScaffoldContract";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { tokenName } from "~~/utils/constant";
import { notification } from "~~/utils/scaffold-stark";
import { decodeUint256Value } from "~~/utils/scaffold-stark";

const MintOperations = () => {
  const [mintAmount, setMintAmount] = useState("");
  const [burnAmount, setBurnAmount] = useState("");

  const { address } = useAccount();

  const { data: strkMyUSDPrice } = useScaffoldReadContract({
    contractName: "Oracle",
    functionName: "get_strk_myusd_price",
  });

  const { data: engineContractData } = useScaffoldContract({
    contractName: "MyUSDEngine",
  });

  const { sendAsync: mintMyUSD } = useScaffoldWriteContract({
    contractName: "MyUSDEngine",
    functionName: "mint_myusd",
    args: [mintAmount ? parseEther(mintAmount) : 0n],
  });

  const { sendAsync: repayUpTo } = useScaffoldWriteContract({
    contractName: "MyUSDEngine",
    functionName: "repay_up_to",
    args: [burnAmount ? parseEther(burnAmount) : 0n],
  });

  const { sendAsync: approve } = useScaffoldWriteContract({
    contractName: "MyUSD",
    functionName: "approve",
    args: [
      engineContractData?.address,
      burnAmount ? parseEther(burnAmount) : 0n,
    ],
  });

  const { data: currentDebtValue } = useScaffoldReadContract({
    contractName: "MyUSDEngine",
    functionName: "get_current_debt_value",
    args: [address],
  });

  const strkMyUSDPriceBigInt = useMemo(
    () => decodeUint256Value(strkMyUSDPrice) ?? 0n,
    [strkMyUSDPrice],
  );

  const currentDebtValueBigInt = useMemo(
    () => decodeUint256Value(currentDebtValue),
    [currentDebtValue],
  );

  const handleAmountChange =
    (setter: (value: string) => void) => (value: string | bigint) => {
      setter(typeof value === "bigint" ? value.toString() : value);
    };

  const handleMint = async () => {
    try {
      await mintMyUSD();
      setMintAmount("");
    } catch (error) {
      console.error("Error minting MyUSD:", error);
    }
  };

  const handleBurn = async () => {
    try {
      await approve();
      await repayUpTo();
      setBurnAmount("");
    } catch (error) {
      console.error("Error burning MyUSD:", error);
    }
  };

  const handleRepayAll = async () => {
    if (!currentDebtValueBigInt) {
      notification.error("No debt value found");
      return;
    }
    const extraRepayment = currentDebtValueBigInt + parseEther("0.1");
    try {
      await approve();
      await repayUpTo({
        args: [extraRepayment],
      });
      setBurnAmount("");
    } catch (error) {
      console.error("Error repaying all:", error);
    }
  };

  return (
    <div className="card bg-base-100 w-96 shadow-xl indicator">
      <TooltipInfo
        top={3}
        right={3}
        infoText={`Use these controls to mint and burn ${tokenName} from the MyUSDEngine pool`}
      />
      <div className="card-body">
        <div className="w-full flex justify-between">
          <h2 className="card-title">Mint Operations ({tokenName})</h2>
        </div>

        <div className="form-control">
          <label className="label flex justify-between">
            <span className="label-text">Mint</span>{" "}
            {address && (
              <RatioChange
                user={address}
                strkPrice={Number(formatEther(strkMyUSDPriceBigInt))}
                inputAmount={Number(mintAmount)}
              />
            )}
          </label>
          <div className="flex gap-2 items-center">
            <IntegerInput
              value={mintAmount}
              onChange={handleAmountChange(setMintAmount)}
              placeholder="Amount"
              disableMultiplyBy1e18
            />
            <button
              className="btn btn-sm btn-primary"
              onClick={handleMint}
              disabled={!mintAmount}
            >
              Mint
            </button>
          </div>
        </div>

        <div className="form-control">
          <div className="label flex justify-between">
            <div className="flex gap-2 items-center">
              <span className="label-text">Repay</span>
              <button
                className="btn btn-xs btn-primary text-xs font-medium mb-1"
                disabled={!currentDebtValueBigInt}
                onClick={handleRepayAll}
              >
                Repay All
              </button>
            </div>
            {address && (
              <RatioChange
                user={address}
                strkPrice={Number(formatEther(strkMyUSDPriceBigInt))}
                inputAmount={-Number(burnAmount)}
              />
            )}
          </div>
          <div className="flex gap-2 items-center">
            <IntegerInput
              value={burnAmount}
              onChange={handleAmountChange(setBurnAmount)}
              placeholder="Amount"
              disableMultiplyBy1e18
            />
            <button
              className="btn btn-sm btn-primary"
              onClick={handleBurn}
              disabled={!burnAmount}
            >
              Repay
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MintOperations;
