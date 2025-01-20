import Image from "next/image";
import { PersonIcon } from "../icons/Person";
import { CodeIcon } from "../icons/Code";
import { displayAddress } from "~~/utils/utils";
import { useState, useEffect } from "react";

type Props = {
  isOpen: boolean;
  onClose: () => void;
  openDisconnect: () => void;
  title: string;
  address: string;
};

type BurnerAccount = {
  address: string;
  privateKey: string;
};

export const WalletAccountModal = ({
  isOpen,
  onClose,
  title,
  openDisconnect,
  address,
}: Props) => {
  const [burnerAccounts, setBurnerAccounts] = useState<BurnerAccount[]>([]);
  const [showBurnerList, setShowBurnerList] = useState(false);

  useEffect(() => {
    // Load burner accounts from localStorage
    const loadBurnerAccounts = () => {
      const accounts: BurnerAccount[] = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key?.startsWith('burner-')) {
          try {
            const accountData = JSON.parse(localStorage.getItem(key) || '');
            accounts.push({
              address: accountData.address,
              privateKey: accountData.privateKey
            });
          } catch (error) {
            console.error('Error parsing burner account:', error);
          }
        }
      }
      setBurnerAccounts(accounts);
    };

    if (isOpen) {
      loadBurnerAccounts();
    }
  }, [isOpen]);

  const handleCloseModal = () => {
    setShowBurnerList(false);
    onClose();
  };

  const toggleBurnerList = () => {
    setShowBurnerList(!showBurnerList);
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
              <p className="text-[15px] text-black mt-0.5 flex-1">
                Completed Challenges
              </p>
              <p className="text-black">04</p>
            </div>

            {/* Burner Accounts Section */}
            {burnerAccounts.length > 0 && (
              <>
                <div className="h-[1px] w-full bg-black"></div>
                <div 
                  className="bg-white flex items-center gap-2.5 px-4 py-3 cursor-pointer hover:bg-gray-50"
                  onClick={toggleBurnerList}
                >
                  <Image
                    src="/homescreen/burner-wallet-icon.svg"
                    alt="burner"
                    width={16}
                    height={16}
                  />
                  <p className="text-[15px] text-black mt-0.5 flex-1">
                    Burner Accounts ({burnerAccounts.length})
                  </p>
                  <Image
                    src={showBurnerList ? "/homescreen/arrow-up.svg" : "/homescreen/arrow-down.svg"}
                    alt="arrow"
                    width={12}
                    height={12}
                  />
                </div>

                {/* Burner Accounts List */}
                {showBurnerList && (
                  <div className="bg-white px-4 py-2 max-h-[200px] overflow-y-auto">
                    {burnerAccounts.map((account, index) => (
                      <div 
                        key={account.address} 
                        className="flex items-center gap-2 py-2 hover:bg-gray-50 rounded px-2"
                      >
                        <div className="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center text-xs">
                          {index + 1}
                        </div>
                        <p className="text-[13px] text-black flex-1">
                          {displayAddress(account.address)}
                        </p>
                      </div>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </>
  );
};