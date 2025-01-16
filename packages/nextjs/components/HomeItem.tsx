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
        className={`pb-0.5 pt-1.5 text-[13px] px-1 ${theme === "primary" ? "w-[110px]" : "w-[130px]"}  text-center uppercase`}
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
