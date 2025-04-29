"use client";

import { useEffect, useState } from "react";
import type { NextPage } from "next";
import { AddressInput } from "~~/components/scaffold-stark/Input/AddressInput";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark";
import { multiplyTo1e18 } from "~~/utils/scaffold-stark/priceInWei";
import { useAccount } from "@starknet-react/core";
import { formatEther } from "ethers";
import { Address, Balance, IntegerInput } from "~~/components/scaffold-stark";
import { Curve } from "~~/app/dex/_components";
import useScaffoldStrkBalance from "~~/hooks/scaffold-stark/useScaffoldStrkBalance";
import { useTheme } from "next-themes";
import { useScaffoldMultiWriteContract } from "~~/hooks/scaffold-stark/useScaffoldMultiWriteContract";

// REGEX for number inputs (only allow numbers and a single decimal point)
const NUMBER_REGEX = /^\.?\d+\.?\d*$/;

const Dex: NextPage = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [strkToTokenAmount, setStrkToTokenAmount] = useState<string | bigint>(
    "",
  );
  const [tokenToSTRKAmount, setTokenToSTRKAmount] = useState("");
  const [depositAmount, setDepositAmount] = useState<string | bigint>("");
  const [withdrawAmount, setWithdrawAmount] = useState<string | bigint>("");
  const [approveSpender, setApproveSpender] = useState("");
  const [approveAmount, setApproveAmount] = useState("");
  const [accountBalanceOf, setAccountBalanceOf] = useState("");
  const [depositTokenAmount, setDepositTokenAmount] = useState<bigint>(0n);

  const { data: DexInfo } = useDeployedContractInfo("Dex");
  const { data: Strk } = useDeployedContractInfo("Strk");

  const { data: BalloonsInfo } = useDeployedContractInfo("Balloons");
  const { address: connectedAccount } = useAccount();

  const { data: DexBalloonBalance } = useScaffoldReadContract({
    contractName: "Balloons",
    functionName: "balance_of",
    args: [DexInfo?.address?.toString()],
  });

  useEffect(() => {
    if (DexBalloonBalance !== undefined) {
      setIsLoading(false);
    }
  }, [DexBalloonBalance]);

  // useEffect(() => {
  //     if (depositTokenAmount > 0n) {
  //         deposit().catch(console.error);
  //     }
  // }, [depositTokenAmount]);

  const { data: DexTotalLiquidity } = useScaffoldReadContract({
    contractName: "Dex",
    functionName: "get_total_liquidity",
  });

  const { sendAsync: strk_to_token } = useScaffoldMultiWriteContract({
    calls: [
      {
        contractName: "Strk",
        functionName: "approve",
        args: [DexInfo?.address ?? "", multiplyTo1e18(strkToTokenAmount)],
      },
      {
        contractName: "Dex",
        functionName: "strk_to_token",
        args: [multiplyTo1e18(strkToTokenAmount)],
      },
    ],
  });

  const { sendAsync: token_to_strk } = useScaffoldMultiWriteContract({
    calls: [
      {
        contractName: "Balloons",
        functionName: "approve",
        args: [DexInfo?.address, multiplyTo1e18(tokenToSTRKAmount)],
      },
      {
        contractName: "Dex",
        functionName: "token_to_strk",
        args: [multiplyTo1e18(tokenToSTRKAmount)],
      },
    ],
  });

  const { sendAsync: deposit } = useScaffoldMultiWriteContract({
    calls: [
      {
        contractName: "Strk",
        functionName: "approve",
        args: [DexInfo?.address ?? "", multiplyTo1e18(depositAmount)],
      },
      {
        contractName: "Balloons",
        functionName: "approve",
        args: [DexInfo?.address ?? "", depositTokenAmount],
        // args: [DexInfo?.address ?? "", multiplyTo1e18("1.252423607961512528")],
      },
      {
        contractName: "Dex",
        functionName: "deposit",
        args: [multiplyTo1e18(depositAmount)],
      },
    ],
  });

  const { data: getDepositTokenAmount } = useScaffoldReadContract({
    contractName: "Dex",
    functionName: "get_deposit_token_amount",
    args: [multiplyTo1e18(depositAmount)],
    watch: true,
  });

  useEffect(() => {
    if (getDepositTokenAmount) {
      setDepositTokenAmount(BigInt(getDepositTokenAmount?.toString() ?? 0n));
    }
  }, [getDepositTokenAmount]);

  const { sendAsync: withdraw } = useScaffoldWriteContract({
    contractName: "Dex",
    functionName: "withdraw",
    args: [multiplyTo1e18(withdrawAmount)],
  });

  const { sendAsync: balloonsApprove } = useScaffoldWriteContract({
    contractName: "Balloons",
    functionName: "approve",
    args: [
      approveSpender,
      NUMBER_REGEX.test(approveAmount)
        ? multiplyTo1e18(approveAmount)
        : BigInt(approveAmount),
    ],
  });

  const { data: balanceOfWrite } = useScaffoldReadContract({
    contractName: "Balloons",
    functionName: "balance_of",
    args: [accountBalanceOf],
  });

  const { data: contractBalance } = useScaffoldReadContract({
    contractName: "Balloons",
    functionName: "balance_of",
    args: [DexInfo?.address],
  });

  const { data: userBalloons } = useScaffoldReadContract({
    contractName: "Balloons",
    functionName: "balance_of",
    args: [connectedAccount],
  });

  const { data: userLiquidity } = useScaffoldReadContract({
    contractName: "Dex",
    functionName: "get_liquidity",
    args: [connectedAccount],
  });

  const { formatted: formatedContractSTRKBalance } = useScaffoldStrkBalance({
    address: DexInfo?.address || "",
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

  const { resolvedTheme } = useTheme();
  const isDarkMode = resolvedTheme === "dark";

  return (
    <>
      <h1 className="text-center mb-4 mt-5">
        <span className="block text-xl text-right mr-7">
          🎈: {parseFloat(formatEther(userBalloons?.toString() || 0n))}
        </span>
        <span className="block text-xl text-right mr-7">
          💦💦: {parseFloat(formatEther(userLiquidity?.toString() || 0n))}
        </span>
        <span className="block text-2xl mb-2">SpeedRunStark</span>
        <span className="block text-4xl font-bold">
          Challenge 4: ⚖️ Build a DEX{" "}
        </span>
      </h1>
      <div className="items-start pt-10 grid grid-cols-1 md:grid-cols-2 content-start">
        <div className="px-5 py-5">
          <div className="bg-base-100 shadow-lg shadow-secondary border-8 border-secondary rounded-xl p-8 m-8">
            <div className="flex flex-col text-center">
              <span className="text-3xl font-semibold mb-2">DEX Contract</span>
              <span className="block text-2xl mb-2 mx-auto">
                <Address size="xl" address={DexInfo?.address} />
              </span>
              <span className="flex flex-row mx-auto mt-5">
                {" "}
                <Balance className="text-xl" address={DexInfo?.address} /> ⚖️
                {isLoading ? (
                  <span>Loading...</span>
                ) : (
                  <span className="pl-8 text-xl">
                    🎈{" "}
                    {parseFloat(
                      formatEther(DexBalloonBalance?.toString() || 0n),
                    )}
                  </span>
                )}
              </span>
            </div>
            <div className="py-3 px-4">
              <div className="flex mb-4 justify-center items-center">
                <span className="w-1/2">
                  strkToToken{" "}
                  <IntegerInput
                    value={strkToTokenAmount}
                    onChange={(value) => {
                      setTokenToSTRKAmount("");
                      setStrkToTokenAmount(value);
                    }}
                    name="strk_to_token"
                    disableMultiplyBy1e18
                  />
                </span>
                <button
                  className="btn btn-primary h-[2.2rem] min-h-[2.2rem] mt-6 mx-5"
                  onClick={wrapInTryCatch(
                    () => strk_to_token(),
                    "strk_to_token",
                  )}
                >
                  Send
                </button>
              </div>
              <div className="flex justify-center items-center">
                <span className="w-1/2">
                  tokenToSTRK{" "}
                  <IntegerInput
                    value={tokenToSTRKAmount}
                    onChange={(value) => {
                      setStrkToTokenAmount("");
                      setTokenToSTRKAmount(value.toString());
                    }}
                    name="tokenToSTRK"
                    disableMultiplyBy1e18
                  />
                </span>
                <button
                  className="btn btn-primary h-[2.2rem] min-h-[2.2rem] mt-6 mx-5"
                  onClick={wrapInTryCatch(
                    () => token_to_strk(),
                    "token_to_strk",
                  )}
                >
                  Send
                </button>
              </div>
            </div>
            <p className="text-center text-primary-content text-xl mt-8 -ml-8">
              Liquidity (
              {parseFloat(formatEther(DexTotalLiquidity?.toString() || "0"))})
            </p>
            <div className="px-4 py-3">
              <div className="flex mb-4 justify-center items-center">
                <span className="w-1/2">
                  Deposit{" "}
                  <IntegerInput
                    value={depositAmount}
                    onChange={(value) => setDepositAmount(value)}
                    disableMultiplyBy1e18
                  />
                </span>
                <button
                  className="btn btn-primary h-[2.2rem] min-h-[2.2rem] mt-6 mx-5"
                  onClick={wrapInTryCatch(async () => {
                    // setDepositTokenAmount(BigInt(getDepositTokenAmount?.toString() ?? 0n));
                    if (depositTokenAmount > 0n) {
                      deposit().catch(console.error);
                    }
                  }, "deposit")}
                >
                  Send
                </button>
              </div>

              <div className="flex justify-center items-center">
                <span className="w-1/2">
                  Withdraw{" "}
                  <IntegerInput
                    value={withdrawAmount}
                    onChange={(value) => setWithdrawAmount(value)}
                    disableMultiplyBy1e18
                  />
                </span>
                <button
                  className="btn btn-primary h-[2.2rem] min-h-[2.2rem] mt-6 mx-5"
                  onClick={wrapInTryCatch(() => withdraw(), "withdraw")}
                >
                  Send
                </button>
              </div>
            </div>
          </div>

          <div className="space-y-4 bg-base-100 shadow-lg shadow-secondary border-8 border-secondary rounded-xl py-5 p-8 m-8">
            <div className="flex flex-col text-center mt-2 mb-4 px-4">
              <span className="block text-3xl font-semibold mb-2">
                Balloons
              </span>
              <span className="mx-auto">
                <Address size="xl" address={BalloonsInfo?.address} />
              </span>
            </div>

            <div className=" px-4 py-3">
              <div className="flex flex-col gap-4 mb-4 justify-center items-center">
                <span className="w-1/2">
                  Approve{" "}
                  <AddressInput
                    value={approveSpender ?? ""}
                    onChange={(value) => setApproveSpender(value)}
                    placeholder="Address Spender"
                  />
                </span>
                <span className="w-1/2">
                  <IntegerInput
                    value={approveAmount}
                    onChange={(value) => setApproveAmount(value.toString())}
                    placeholder="Amount"
                    disableMultiplyBy1e18
                  />
                </span>
                <button
                  className="btn btn-primary h-[2.2rem] min-h-[2.2rem] mt-auto"
                  onClick={wrapInTryCatch(
                    () => balloonsApprove(),
                    "balloonsApprove",
                  )}
                >
                  Send
                </button>
                <span className="w-1/2">
                  balance_of{" "}
                  <AddressInput
                    value={accountBalanceOf}
                    onChange={(value) => setAccountBalanceOf(value)}
                    placeholder="address Account"
                  />
                </span>
                {balanceOfWrite === undefined ? (
                  <h1></h1>
                ) : (
                  <span className="font-bold bg-primary px-3 rounded-2xl">
                    BAL Balance:{" "}
                    {parseFloat(formatEther(balanceOfWrite?.toString() || "0"))}
                  </span>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="mx-auto p-8 m-8 md:sticky md:top-0">
          <Curve
            addingStrk={
              strkToTokenAmount !== ""
                ? parseFloat(strkToTokenAmount.toString())
                : 0
            }
            addingToken={
              tokenToSTRKAmount !== ""
                ? parseFloat(tokenToSTRKAmount.toString())
                : 0
            }
            strkReserve={parseFloat(formatedContractSTRKBalance)}
            tokenReserve={parseFloat(
              formatEther(contractBalance?.toString() || "0"),
            )}
            width={500}
            height={500}
            isDarkMode={isDarkMode}
          />
        </div>
      </div>
    </>
  );
};

export default Dex;
