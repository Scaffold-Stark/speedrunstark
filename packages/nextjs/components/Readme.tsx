import Image from "next/image";
import { CloseIcon } from "./icons/CloseIcon";

const DATA_JOURNEY = [
  "Watch our foundational videos",
  "Practice with Starklings",
  "Solve Speedrun Challenges",
  "Ship your first dApp",
];

const NumberBox = ({ number }: { number: number }) => {
  return (
    <div
      className="bg-[#EAEAEA] w-[18px] h-[18px] flex items-center justify-center rounded-[3px]"
      style={{
        boxShadow:
          "-2.323px 0px 1.626px 0px rgba(223, 223, 223, 0.25) inset, 2.323px 0px 1.626px 0px rgba(0, 0, 0, 0.25) inset, 0px -2.323px 2.323px 0px rgba(0, 0, 0, 0.25) inset, 0px 2.323px 0.813px 0px #FFF inset",
      }}
    >
      <span className="text-[10px] text-black">{number}</span>
    </div>
  );
};

export const Readme = () => {
  return (
    <div className="p-0.5 bg-white w-fit">
      <div className="p-2.5 bg-[#4D58FF] flex justify-center relative">
        <div className="absolute left-2.5 transform -translate-y-1/2 top-1/2">
          <CloseIcon />
        </div>
        <p className="uppercase text-xl font-vt323">read me</p>
      </div>
      <div className="p-4 border-b border-black">
        <Image
          src={"/homescreen/starknet-logo-dark.svg"}
          width={106}
          height={25}
          alt="logo"
        />
        <p className="text-[#0C0C4F] leading-5 mt-3">
          Learn how to build on Starknet. <br /> The superpowers and the
          gotchas.
        </p>
      </div>
      <div className="p-4">
        <h4
          className="text-[#0C0C4F] text-xl mb-2"
          style={{
            WebkitTextStrokeWidth: "0.800000011920929",
            WebkitTextStrokeColor: "#0C0C4F",
          }}
        >
          Your journey:
        </h4>
        <div>
          {DATA_JOURNEY.map((item, index) => (
            <div key={item} className="flex items-center gap-3">
              <NumberBox number={index + 1} />
              <p className="text-[#0c0c4f]">{item}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
