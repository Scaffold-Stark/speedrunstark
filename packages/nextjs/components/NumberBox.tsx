export const NumberBox = ({ number }: { number: number }) => {
  return (
    <div
      className="bg-[#EAEAEA] w-[18px] h-[18px] flex items-center justify-center rounded-[3px]"
      style={{
        boxShadow:
          "-2.323px 0px 1.626px 0px rgba(223, 223, 223, 0.25) inset, 2.323px 0px 1.626px 0px rgba(0, 0, 0, 0.25) inset, 0px -2.323px 2.323px 0px rgba(0, 0, 0, 0.25) inset, 0px 2.323px 0.813px 0px #FFF inset",
      }}
    >
      <span className="text-[10px] text-black font-digital">{number}</span>
    </div>
  );
};
