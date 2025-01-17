import { useState } from "react";
import { LanguageModal } from "./LanguageModal";

export const LanguageButton = () => {
  const [openLanguage, setOpenLanguage] = useState(false);

  return (
    <div>
      <button
        className="uppercase border border-black md:py-0 py-1 px-2 md:px-4 md:pb-1 md:pt-1.5 md:text-sm text-xs text-[#333] bg-white"
        onClick={() => setOpenLanguage(true)}
      >
        language: EN
      </button>
      <LanguageModal
        title="choose your language"
        isOpen={openLanguage}
        onClose={() => setOpenLanguage(false)}
      />
    </div>
  );
};
