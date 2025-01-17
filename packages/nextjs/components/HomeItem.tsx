import Image from "next/image";

export const MENU_THEMES = {
  primary: {
    textColor: "#000",
    bgColor: "#FFF",
    border: "1px solid #000",
  },
  secondary: {
    textColor: "#ffffff",
    bgColor: "#4D58FF",
    border: "none",
  },
};

interface IMenu {
  name: string;
  icon: string;
  theme?: keyof typeof MENU_THEMES;
  onclick?: () => void;
  customTheme?: {
    textColor: string;
    bgColor: string;
    border: string;
  };
}

export const HomeItem = ({
  name,
  icon,
  theme = "primary",
  customTheme,
  onclick,
}: IMenu) => {
  const colors = customTheme || MENU_THEMES[theme];

  return (
    <div
      className="flex flex-col gap-2 items-center w-fit cursor-pointer"
      onClick={onclick}
    >
      <Image
        src={icon}
        alt="icon"
        width={45}
        height={45}
        className="min-h-[45px] min-w-[45px]"
      />
      <p
        className={`md:pb-0.5 md:pt-1.5 md:text-[13px] text-[10px] md:px-1 ${theme === "primary" ? "md:w-[110px] w-[90px]" : "md:w-[130px] w-[100px]"}  text-center uppercase`}
        style={{
          backgroundColor: colors.bgColor,
          color: colors.textColor,
          border: colors.border,
        }}
      >
        {name}
      </p>
    </div>
  );
};
