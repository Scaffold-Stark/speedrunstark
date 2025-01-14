import Image from "next/image";

const HeaderLogo = () => {
  return (
    <Image
      src={"/homescreen/starknet-logo.svg"}
      alt="logo"
      width={120}
      height={28}
    />
  );
};

export default HeaderLogo;
