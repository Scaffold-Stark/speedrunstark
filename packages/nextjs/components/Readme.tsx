import Image from "next/image";
import { CloseIcon } from "./icons/CloseIcon";
import { NumberBox } from "./NumberBox";
import { DATA_JOURNEY } from "~~/mockup/data";

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
