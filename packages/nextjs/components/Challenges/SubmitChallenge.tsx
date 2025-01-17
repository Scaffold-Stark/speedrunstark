import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { ExpandIcon } from "../icons/ExpandIcon";
import { useState } from "react";

interface InputField {
  id: string;
  title: string;
  placeholder: string;
}

interface InputURLProps {
  title: string;
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
}

interface DynamicSequentialInputsProps {
  inputFields: InputField[];
}

const InputURL: React.FC<InputURLProps> = ({
  title,
  value,
  onChange,
  placeholder,
}) => {
  return (
    <div className="flex flex-col gap-1">
      <p className="!text-black">{title}</p>
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="!text-[#4D58FF] border-none outline-none px-2 bg-transparent caret-[#4D58FF] appearance-none selection:bg-[#4D58FF/20]"
      />
    </div>
  );
};

const DynamicSequentialInputs: React.FC<DynamicSequentialInputsProps> = ({
  inputFields,
}) => {
  // Initialize state with a record of string values
  const [inputValues, setInputValues] = useState<Record<string, string>>(() =>
    inputFields.reduce((acc, field) => ({ ...acc, [field.id]: "" }), {}),
  );

  const handleInputChange = (id: string, value: string): void => {
    setInputValues((prev) => ({ ...prev, [id]: value }));
  };

  const shouldShowInput = (index: number): boolean => {
    if (index === 0) return true;

    const previousInputs = inputFields.slice(0, index);
    return previousInputs.every((field) => inputValues[field.id]?.trim());
  };

  return (
    <div className="mt-4 pb-8 flex flex-col gap-5">
      {inputFields.map(
        (field, index) =>
          shouldShowInput(index) && (
            <InputURL
              key={field.id}
              title={field.title}
              value={inputValues[field.id]}
              onChange={(value) => handleInputChange(field.id, value)}
              placeholder={field.placeholder}
            />
          ),
      )}
    </div>
  );
};

export const SubmitChallenge = () => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [openSubmit, setOpenSubmit] = useState(false);

  const sampleInputs: InputField[] = [
    {
      id: "deployed",
      title: "Enter Deployed URL",
      placeholder: "Enter deployed URL...",
    },
    {
      id: "nft",
      title: "Enter Simple NFT Contract",
      placeholder: "Enter NFT contract...",
    },
    {
      id: "staker",
      title: "Enter Staker Contract",
      placeholder: "Enter staker contract...",
    },
  ];

  const handleCloseModal = () => {
    setOpenSubmit(false);
    setIsExpanded(false);
  };
  const handleExpand = () => {
    setIsExpanded(!isExpanded);
  };

  return (
    <div>
      <div
        onClick={() => setOpenSubmit(true)}
        className="fixed z-50 bottom-5 transform -translate-x-[62%] left-[62%] flex items-center gap-2 bg-[#4D58FF] w-fit px-4 py-3 cursor-pointer"
      >
        <Image
          src={"/homescreen/submit.svg"}
          alt="icon"
          width={20}
          height={20}
        />
        <p className="text-lg font-vt323 uppercase !text-white">
          Submit challenge
        </p>
      </div>
      {openSubmit && (
        <section
          className={`absolute z-[99] left-1/2 transform -translate-x-1/2 md:shadow-modal max-w-[850px] w-full mx-auto md:p-[1px] md:rounded-lg bg-white ${isExpanded ? "h-[95vh]" : ""}`}
        >
          <div className={`w-full ${isExpanded ? "h-full flex flex-col" : ""}`}>
            <div className="bg-[#4D58FF] relative rounded-t-lg h-[60px] flex items-center justify-center">
              <Image
                src="/homescreen/header-decore.svg"
                alt="icon"
                width={230}
                height={40}
                className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
              />

              <div className="flex items-center gap-1.5 absolute z-30 left-4">
                <CloseIcon onClose={handleCloseModal} />
                <ExpandIcon onExpand={handleExpand} />
              </div>
              <p className="text-xl relative z-30 uppercase font-vt323 !text-white">
                Challenge 01: Simple NFT Example
              </p>
            </div>
          </div>
          <div className="p-4 bg-[#E5E5E5]">
            <div className="flex flex-col gap-2">
              <div
                className="w-full h-[2px] opacity-50"
                style={{
                  backgroundImage:
                    "repeating-linear-gradient(to right, black 0, black 8px, transparent 8px, transparent 15px)",
                }}
              />
              <h3 className="text-black text-[22px]">
                Challenge 01: Simple NFT Example
              </h3>
              <div>
                <p className="text-sm !text-[#939393]">
                  You have to add 1 Deploy URL and 3 Contract Addresses.
                </p>
                <ul className="text-sm !text-[#939393] list-disc list-inside ml-3">
                  <li>
                    Press <span className="text-[#2835FF]">Enter</span> to
                    submit and <span className="text-[#FF282C]">ESC</span> to
                    cancel.
                  </li>
                  <li>
                    Make sure that repo is{" "}
                    <span className="uppercase text-[#2835FF]">public</span> or
                    github user “
                    <span className="text-[#2835FF]">0xquantum3labs</span>” has
                    read access.
                  </li>
                </ul>
              </div>
              <div
                className="w-full h-[2px] opacity-50"
                style={{
                  backgroundImage:
                    "repeating-linear-gradient(to right, black 0, black 8px, transparent 8px, transparent 15px)",
                }}
              />
            </div>
            <div className="mt-4 pb-8 flex flex-col gap-5">
              <DynamicSequentialInputs inputFields={sampleInputs} />
            </div>
          </div>
        </section>
      )}
    </div>
  );
};
