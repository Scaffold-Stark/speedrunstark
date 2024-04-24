import Image from "next/image";
import type { NextPage } from "next";

const Home: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div className="px-5 w-[90%] md:w-[75%]">
        <h1 className="text-center mb-6 text-primary">
          <span className="block text-2xl mb-2 text-primary">
            SpeedRunStark
          </span>
          <span className="block text-4xl font-bold text-primary">
            Challenge #1: 🥩 Decentralized Staking App
          </span>
        </h1>
        <div className="flex flex-col items-center justify-center">
          <Image
            src="/banner-home.svg"
            width="727"
            height="231"
            alt="challenge banner"
            className="rounded-xl border-4 border-primary"
          />
          <div className="max-w-3xl ">
            <p className="text-center text-lg mt-8 text-primary">
              🦸 A superpower of Ethereum is allowing you, the builder, to
              create a simple set of rules that an adversarial group of players
              can use to work together. In this challenge, you create a
              decentralized application where users can coordinate a group
              funding effort. The users only have to trust the code.
            </p>
            <p className="text-center text-lg text-primary">
              🌟 The final deliverable is deploying a Dapp that lets users send
              ether to a contract and stake if the conditions are met, then
              deploy your app to a public webserver. Submit the url on{" "}
              <a
                href="https://speedrunstark.com/"
                target="_blank"
                rel="noreferrer"
                className="underline text-primary font-bold"
              >
                SpeedRunStark.com
              </a>{" "}
              !
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
