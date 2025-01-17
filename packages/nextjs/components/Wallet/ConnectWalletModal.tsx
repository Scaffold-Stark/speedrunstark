import GenericModal from "../scaffold-stark/CustomConnectButton/GenericModal";
import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";
import { useState } from "react";
import { Connector, useConnect } from "@starknet-react/core";
import { useLocalStorage } from "usehooks-ts";
import toast from "react-hot-toast";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  title: string;
};

const ItemWallet = ({
  name,
  icon,
  isActive,
  onClick,
}: {
  name: string;
  icon: string;
  isActive: boolean;
  onClick: () => void;
}) => {
  return (
    <div
      className={`flex flex-col items-center gap-4 p-4 cursor-pointer ${isActive ? "bg-[#E9EAF7]" : ""}`}
      onClick={onClick}
    >
      <div className="w-[54px] h-[54px]">
        <Image
          src={icon}
          alt="icon"
          width={54}
          height={54}
          className="w-full h-full"
        />
      </div>
      <p className="capitalize text-[#0C0C4F] text-center">
        {name} <br />
      </p>
    </div>
  );
};

export const ConnectWalletModal = ({ isOpen, onClose, title }: Props) => {
  const { connectors, connectAsync } = useConnect();
  const [selectedWallet, setSelectedWallet] = useState<Connector>(
    connectors[0],
  );
  const [isBurnerWallet, setIsBurnerWallet] = useState(false);
  const [, setLastConnectionTime] = useLocalStorage<number>(
    "lastConnectedTime",
    0,
  );
  const [, setConnectedChainId] = useLocalStorage<bigint>("chainId", 0n);
  const [lastConnector, setLastConnector] = useLocalStorage<{
    id: string;
    ix?: number;
  }>(
    "lastUsedConnector",
    { id: "" },
    {
      initializeWithValue: false,
    },
  );

  const handleCloseModal = () => {
    onClose();
    setSelectedWallet(connectors[0]);
  };

  const handleSelectWallet = (wallet: any) => {
    setSelectedWallet(wallet);
  };

  const handleConnectWallet = async (
    e: React.MouseEvent<HTMLButtonElement>,
    connector: Connector,
  ) => {
    try {
      if (connector.id === "burner-wallet") {
        setIsBurnerWallet(true);
        return;
      }
      await connectAsync({ connector });
      setLastConnector({ id: connector.id });
      setLastConnectionTime(Date.now());

      if (connector?.chainId) {
        const chainId = await connector.chainId();
        setConnectedChainId(BigInt(chainId.toString()));
        localStorage.setItem("chainId", chainId.toString());
      }
      toast.success("Connect wallet successfully!");
    } catch (error) {
      toast.error(`${error}`);
      setIsBurnerWallet(false);
      setLastConnector({ id: "" });
    } finally {
      handleCloseModal();
    }
  };

  return (
    <GenericModal
      animate
      isOpen={isOpen}
      onClose={handleCloseModal}
      className={`w-[320px] mx-auto md:p-[1px] rounded-none bg-white`}
    >
      <div className="bg-[#4D58FF] relative h-[60px] flex items-center justify-center">
        <Image
          src="/homescreen/header-decore.svg"
          alt="icon"
          width={230}
          height={40}
          className="absolute left-1/2 transform -translate-x-1/2 z-10 w-full h-full"
        />

        <div className="flex items-center gap-1.5 absolute z-30 left-4">
          <CloseIcon onClose={handleCloseModal} />
        </div>
        <p className="text-xl relative z-30 uppercase font-vt323">{title}</p>
      </div>

      <div className="grid grid-cols-2 gap-2 py-4 px-8">
        {connectors.map((connector) => (
          <ItemWallet
            key={connector?.id}
            icon={connector.icon.dark ?? ""}
            name={connector.name}
            isActive={selectedWallet?.name === connector.name}
            // onClick={() => handleSelectWallet(connector.name)}
            onClick={() => handleSelectWallet(connector)}
          />
        ))}
      </div>
      <div className="px-1 pb-1">
        <button
          className="py-2 px-4 font-vt323 text-lg bg-[#4D58FF] w-full uppercase"
          onClick={(e) => {
            handleConnectWallet(e, selectedWallet);
          }}
        >
          connect
        </button>
      </div>
    </GenericModal>
  );
};
