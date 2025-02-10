import Image from "next/image";
import { PersonIcon } from "../icons/Person";
import { CodeIcon } from "../icons/Code";
import { displayAddress } from "~~/utils/utils";
import { useState, useEffect, useCallback } from "react";
import { ReloadIcon } from "@radix-ui/react-icons";
import axios from "axios";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  openDisconnect: () => void;
  title: string;
  address: string;
};

export const WalletAccountModal = ({
  isOpen,
  onClose,
  title,
  openDisconnect,
  address,
}: Props) => {
  const [completedCount, setCompletedCount] = useState<undefined | number>(
    undefined,
  );
  const [requestError, setRequestError] = useState<any>(undefined);
  const request = useCallback(() => {
    setRequestError(undefined);
    axios
      .get(`${process.env.NEXT_PUBLIC_SERVER_BASE_URL}/challenges/${address}`)
      .then((response) => {
        if (
          response &&
          response.data &&
          response.data.completedChallenges &&
          Array.isArray(response.data.completedChallenges)
        ) {
          setCompletedCount(response.data.completedChallenges.length);
        } else {
          setRequestError("request unknown error");
        }
      })
      .catch((error) => {
        setRequestError(error);
      });
  }, [address]);

  useEffect(() => {
    if (!isOpen || !address) {
      return;
    }
    request();
  }, [address, isOpen, request]);
  const handleCloseModal = () => {
    onClose();
  };

  if (!isOpen) return null;

  return (
    <>
      <div
        className={`fixed h-screen w-screen grid top-0 left-0 z-[99] opacity-55 bg-black`}
        onClick={handleCloseModal}
      />

      <div className="absolute md:right-8 md:top-16 right-2 -top-44 z-[100]">
        <div className="w-[300px] relative bg-transparent">
          <div className="absolute md:-top-5 right-5 -bottom-5">
            <Image
              src="/homescreen/arrow-youraccount.svg"
              alt="arrow"
              width={30}
              height={30}
              className="md:block hidden"
            />
            <Image
              src="/homescreen/arrow-youraccount-mb.svg"
              alt="arrow"
              width={30}
              height={30}
              className="md:hidden block"
            />
          </div>
          <div className="bg-[#4D58FF] relative py-2.5 flex items-center justify-center">
            <p className="text-xl relative z-30 uppercase font-vt323">
              {title}
            </p>
          </div>
          <div>
            <div className="bg-white flex items-center gap-2.5 px-4 py-3">
              <PersonIcon color="black" />
              <p className="text-[15px] text-black mt-1 flex-1">
                {displayAddress(address)}
              </p>
              <Image
                src={"/homescreen/disconnect-icon.svg"}
                alt="icon"
                width={16}
                height={16}
                className="cursor-pointer z-[100]"
                onClick={() => {
                  openDisconnect();
                  onClose();
                }}
              />
            </div>
            <div className="h-[1px] w-full bg-black"></div>
            <div className="bg-white flex items-center gap-2.5 px-4 py-3">
              <CodeIcon color="black" width={16} />
              <div className="mt-0.5 flex-1 flex flex-col">
                <p className="text-[15px] text-black ">Completed Challenges</p>
                {requestError && (
                  <p className="text-[12px] text-red-900">
                    Query completed challenges failed.
                  </p>
                )}
              </div>

              {requestError ? (
                <ReloadIcon
                  className="text-red-900 z-50 cursor-pointer"
                  onClick={() => {
                    request();
                  }}
                />
              ) : completedCount !== undefined ? (
                <p className="text-black">{`0${completedCount}`}</p>
              ) : (
                <span className="text-black loading loading-spinner loading-xs"></span>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
};
