export const BackgroundTexture = () => {
  const numberOfLines = Math.floor(100 / 0.4);

  return (
    <div className="absolute z-10 top-0 left-0 h-full w-full">
      {Array.from({ length: numberOfLines }).map((_, index) => (
        <div
          key={index}
          className="w-full h-[1px] bg-[#FFFFFF0D]"
          style={{ marginTop: index === 0 ? 0 : "4px" }}
        ></div>
      ))}
    </div>
  );
};
