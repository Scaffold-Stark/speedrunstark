import { useState } from "react";
import { LanguageModal } from "./LanguageModal";

export const LanguageButton = () => {
  const [openLanguage, setOpenLanguage] = useState(false);

  return (
    <div>
      <button
        className="uppercase border border-black px-4 pb-1 pt-1.5 text-sm text-[#333] bg-white"
        onClick={() => setOpenLanguage(true)}
      >
        language: EN:
      </button>
      <LanguageModal
        title="choose your language"
        isOpen={openLanguage}
        onClose={() => setOpenLanguage(false)}
      />
    </div>
  );
};
