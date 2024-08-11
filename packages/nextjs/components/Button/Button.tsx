import React, { ReactNode } from "react";

interface ButtonProps {
  onClick: () => void;
  children: ReactNode;
  isDisable?: boolean;
}

const Button: React.FC<ButtonProps> = ({
  onClick,
  children,
  isDisable = false,
}) => {
  return (
    <button
      className={`py-[5px] px-[10px] sm:px-[20px] sm:py-[10px] bg-base-300 text-base-100  rounded-[8px] sm:text-[14px] text-[12px] ${isDisable ? "cursor-not-allowed opacity-50" : "cursor-pointer"}`}
      onClick={onClick}
      type="button"
      disabled={isDisable || children === "Coming Soon"}
    >
      {children}
    </button>
  );
};

export default Button;
