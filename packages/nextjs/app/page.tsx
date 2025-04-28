"use client";

import type { NextPage } from "next";
import Image from "next/image";
import { useAccount } from "@starknet-react/core";

const Home: NextPage = () => {
  const connectedAddress = useAccount();
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5 w-[90%] md:w-[75%]">
          <h1 className="text-center mb-6">
            <span className="block text-2xl mb-2">SpeedRunStark</span>
            <span className="block text-4xl font-bold">
              Challenge #4: 💱 Dex 💰
            </span>
          </h1>
          <div className="flex flex-col items-center justify-center">
            <Image
              src="/hero4.png"
              width="727"
              height="231"
              alt="challenge banner"
              className="rounded-xl border-4 border-primary"
            />
            <div className="max-w-3xl">
              <p className="text-center text-lg mt-8">
                💱 This challenge will help you build/understand a simple decentralized exchange, with one token-pair
                (ERC20 BALLOONS ($BAL) and STRK). This repo is an updated version of the{" "}
                <a
                    href="https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90"
                    target="_blank"
                    rel="noreferrer"
                    className="underline"
                >
                  original tutorial
                </a>{" "}
                and challenge repos before it. Please read the intro for a background on what we are building first!
              </p>
              <p className="text-center text-lg">
                🌟 The final deliverable is an app that allows users to seamlessly trade ERC20 BALLOONS ($BAL) with
                STRK in a decentralized manner. Users will be able to connect their wallets, view their token
                balances, and buy or sell their tokens according to a price formula! Submit the url on{" "}
                <a
                  href="https://www.speedrunstark.com/"
                  target="_blank"
                  rel="noreferrer"
                  className="underline"
                >
                  SpeedrunStark.com
                </a>{" "}
                !
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-container flex-grow w-full mt-16 px-8 py-12">
        <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
          <div className="flex flex-col bg-base-100 relative text-[12px] px-10 py-10 text-center items-center max-w-xs rounded-3xl border border-gradient">
            <div className="trapeze"></div>
            <Image
              src="/debug-icon.svg"
              alt="icon"
              width={26}
              height={30}
            ></Image>
            <p>
              Tinker with your smart contract using the{" "}
              <Link href="/debug" passHref className="link">
                Debug Contracts
              </Link>{" "}
              tab.
            </p>
          </div>
          <div className="flex flex-col bg-base-100 relative text-[12px] px-10 py-10 text-center items-center max-w-xs rounded-3xl border border-gradient">
            <div className="trapeze"></div>
            <Image
              src="/explorer-icon.svg"
              alt="icon"
              width={20}
              height={32}
            ></Image>
            <p>
              Play around with Multiwrite transactions using
              useScaffoldMultiWrite() hook
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
