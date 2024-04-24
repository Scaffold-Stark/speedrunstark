import { DebugContracts } from "./_components/DebugContracts";
import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-stark/getMetadata";

export const metadata = getMetadata({
  title: "Debug Contracts",
  description:
    "Debug your deployed 🏗 Scaffold-Stark 2 contracts in an easy way",
});

const Debug: NextPage = () => {
  return (
    <>
      <DebugContracts />
      <div className="text-center mt-8 bg-base-300 p-10 ">
        <h1 className="text-4xl my-0 text-neutral-content">Debug Contracts</h1>
        <p className="text-neutral-content">
          You can debug & interact with your deployed contracts here.
          <br /> Check {""}
          <code className="italic bg-base-300 font-bold [word-spacing:-0.5rem] px-1 text-neutral-content">
            packages / nextjs / app / debug / page.tsx
          </code>
        </p>
      </div>
    </>
  );
};

export default Debug;
