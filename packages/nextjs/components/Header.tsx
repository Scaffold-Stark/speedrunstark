import React, { useCallback, useRef, useState } from "react";
import { BugAntIcon } from "@heroicons/react/24/outline";
import { useOutsideClick } from "~~/hooks/scaffold-stark";
import { usePathname } from "next/navigation";
import { FaucetButton } from "~~/components/scaffold-stark/FaucetButton";
import HeaderLogo from "./HeaderLogo";
import Image from "next/image";

type HeaderMenuLink = {
  label: string;
  href: string;
  icon?: React.ReactNode;
};

export const menuLinks: HeaderMenuLink[] = [
  {
    label: "Home",
    href: "/",
  },
  {
    label: "Debug Contracts",
    href: "/debug",
    icon: <BugAntIcon className="h-4 w-4" />,
  },
];

export const Header = () => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const burgerMenuRef = useRef<HTMLDivElement>(null);
  const pathname = usePathname();
  useOutsideClick(
    burgerMenuRef,
    useCallback(() => setIsDrawerOpen(false), []),
  );

  return (
    <div className="bg-[#4D58FF] px-6 py-4 flex justify-between">
      <div>
        {pathname !== "/" && (
          <div onClick={() => (window.location.href = "/")}>
            <HeaderLogo />
          </div>
        )}
      </div>
      <div className="flex items-center gap-6">
        <button className="uppercase border border-black px-4 pb-1 pt-1.5 text-sm text-[#333] bg-white">
          language: EN:
        </button>
        <div className="flex items-center gap-2.5 cursor-pointer">
          <Image
            src={"/homescreen/person.png"}
            alt="icon"
            width={16}
            height={16}
          />
          <p className="text-[15px]">0xda...ea12</p>
        </div>
      </div>
    </div>
  );
};
