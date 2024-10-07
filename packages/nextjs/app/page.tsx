"use client";
import Image from "next/image";
import type { NextPage } from "next";
import { useAccount } from "@starknet-react/core";

const Home: NextPage = () => {
  const connectedAddress = useAccount();
  return (
    <div className="flex items-center flex-col flex-grow pt-10 text-neutral">
      <div className="px-5 w-[90%] md:w-[75%]">
        <h1 className="text-center mb-6">
          <span className="block text-2xl mb-2">SpeedRunStarknet</span>
          <span className="block text-4xl font-bold">
            Challenge #3: 🎲 Dice Game
          </span>
        </h1>
        <div className="flex flex-col items-center justify-center">
          <Image
            src="/hero3.png"
            width="727"
            height="231"
            alt="challenge banner"
            className="rounded-xl border-4 border-primary"
          />
          <div className="max-w-3xl">
            <p className="text-lg mt-10">
              🎰 Randomness is tricky on a public deterministic blockchain. The
              block hash is an easy to use, but very weak form of randomness.
              This challenge will give you an example of a contract using block
              hash to create random numbers. This randomness is exploitable.
              Other, stronger forms of randomness include commit/reveal schemes,
              oracles, or VRF from Chainlink.
            </p>
            <p className="text-lg mt-2">
              👍 One day soon, randomness will be built into the Starknet!
            </p>
            <p className="text-lg mt-2">
              🧤 Every time a player rolls the dice, they are required to send
              .002 Eth. 40 percent of this value is added to the current prize
              amount while the other 60 percent stays in the contract to fund
              future prizes. Once a prize is won, the new prize amount is set to
              10% of the total balance of the DiceGame contract.
            </p>
            <p className="text-lg mt-2">
              🧨 Your job is to attack the Dice Game contract! You will create a
              new contract that will predict the randomness ahead of time and
              only roll the dice when you′re guaranteed to be a winner!
            </p>
            <p className="text-lg mt-2">
              💬 Meet other builders working on this challenge and get help in
              the{" "}
              <a
                href="https://t.me/+wO3PtlRAreo4MDI9"
                target="_blank"
                rel="noreferrer"
                className="underline"
              >
                Telegram Group
              </a>
            </p>
            <p className="text-center text-lg font-medium">
              <a
                href="https://speedrunstark.com/"
                target="_blank"
                rel="noreferrer"
                className="underline"
              >
                SpeedrunStark.com
              </a>
              !
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
