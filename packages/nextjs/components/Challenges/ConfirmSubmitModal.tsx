import Image from "next/image";
import { CloseIcon } from "../icons/CloseIcon";

export const ConfirmSubmitModal = ({ onClose }: { onClose: () => void }) => {
  return (
    <div className="overflow-hidden absolute z-[98] md:top-1/2 top-0 left-1/2 transform md:-translate-y-1/2 -translate-x-1/2 md:shadow-modal max-w-[320px] w-full mx-auto md:p-[1px] bg-white">
      <div className={`w-full pb-1`}>
        <div className="bg-[#4D58FF] relative h-[60px] flex items-center justify-center">
          <div className="flex items-center gap-1.5 absolute z-30 left-4">
            <CloseIcon onClose={onClose} />
          </div>
          <p className="text-xl relative z-30 uppercase font-vt323 !text-white">
            confirmation
          </p>
        </div>
        <div className="py-8 px-1 flex flex-col items-center">
          <Image
            src={"/homescreen/confirm.svg"}
            alt="icon"
            width={40}
            height={40}
          />
          <p className="text-center">Are you sure to sumbit your challenge?</p>
        </div>
        <div className="flex items-center gap-2.5 px-1">
          <div
            onClick={onClose}
            className="uppercase w-full text-center py-2 bg-[#FF282C] flex justify-center items-center gap-2 cursor-pointer"
          >
            <Image
              src={"/homescreen/cancel.svg"}
              alt="icon"
              width={24}
              height={24}
            />
            <p className="md:text-lg text-sm font-vt323 uppercase !text-white">
              cancel
            </p>
          </div>
          <div
            onClick={onClose} //add submit here
            className="uppercase w-full text-center py-2 bg-[#4D58FF] flex justify-center items-center gap-2 cursor-pointer"
          >
            <Image
              src={"/homescreen/submit.svg"}
              alt="icon"
              width={24}
              height={24}
            />
            <p className="md:text-lg text-sm font-vt323 uppercase !text-white">
              confirm
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
