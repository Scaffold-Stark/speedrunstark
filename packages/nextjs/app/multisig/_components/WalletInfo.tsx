import React from "react";
import CopyToClipboard from "react-copy-to-clipboard";
import { Address, Balance, BlockieAvatar } from "~~/components/scaffold-stark";
import { notification } from "~~/utils/scaffold-stark";
import { convertFeltToAddress, formatAddress } from "../utils";
import { WalletInfoProps } from "../types";
import ResetDataButton from "./ResetDataButton";

const WalletInfo: React.FC<WalletInfoProps> = ({
  deployedContractData,
  contractStrkBalance,
  signers,
  loadingSigners,
  loadSigners,
  account,
  quorum,
}) => {
  return (
    <div className="border border-gradient p-6 rounded-lg shadow-md">
      <div className="flex items-center gap-2 justify-between mb-3">
        <h3 className="text-xl font-semibold ">Wallet Information</h3>
        <ResetDataButton />
      </div>
      {deployedContractData && (
        <div className="flex justify-between gap-5">
          <div className="mb-4 flex flex-col gap-1">
            <div className="text-sm">
              <span className="font-semibold">Contract Address:</span>
              <Address address={deployedContractData.address} />
            </div>
            <div className="text-sm">
              <span className="font-semibold">Signers:</span>
              <span className="ml-2">
                {loadingSigners ? "Loading..." : signers.length}
              </span>
            </div>
            <div className="text-sm">
              <span className="font-semibold">Quorum:</span>
              <span className="ml-2">{quorum}</span>
            </div>
          </div>
          <div className="text-sm font-semibold text-right">
            <Balance address={deployedContractData.address} className="text-network"/>
          </div>
        </div>
      )}

      <div className="mt-4">
        <h4 className="font-semibold mb-2">Current Signers:</h4>
        {signers.length === 0 ? (
          <div className="text-gray-400">No signers found</div>
        ) : (
          <div className="space-y-2 max-h-40 overflow-y-auto">
            {signers.map((address, index) => (
              <div
                key={index}
                className="text-sm p-2 rounded border border-gradient flex justify-between items-center"
              >
                <div className="flex items-center gap-2">
                  <BlockieAvatar
                    address={convertFeltToAddress(address)}
                    size={16}
                  />
                  <CopyToClipboard
                    text={convertFeltToAddress(address)}
                    onCopy={() => {
                      notification.success("Copy successfully!");
                    }}
                  >
                    <span className="font-mono break-all cursor-pointer">
                      {formatAddress(convertFeltToAddress(address))}
                    </span>
                  </CopyToClipboard>
                </div>
                {convertFeltToAddress(address) === account?.address && (
                  <span className="text-xs bg-blue-600 px-2 py-1 rounded ml-2 text-white">
                    You
                  </span>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <button
        onClick={loadSigners}
        disabled={loadingSigners || !account || !deployedContractData}
        className="text-white mt-4 w-full rounded-md py-2 text-sm font-medium bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed"
      >
        {loadingSigners ? "Loading..." : "Refresh Signers"}
      </button>
    </div>
  );
};

export default WalletInfo;
