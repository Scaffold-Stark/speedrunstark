import { useState, useEffect } from "react";

export const BackgroundTexture = () => {
  const [numberOfLines, setNumberOfLines] = useState(0);
  const LINE_SPACING = 8.5;

  useEffect(() => {
    const calculateLines = () => {
      const viewportHeight = window.innerHeight;
      const requiredLines = Math.ceil(viewportHeight / LINE_SPACING) + 2;
      setNumberOfLines(requiredLines);
    };

    calculateLines();
    window.addEventListener("resize", calculateLines);
    return () => window.removeEventListener("resize", calculateLines);
  }, []);

  return (
    <div
      className="fixed z-10 top-0 left-0 min-h-screen w-full overflow-hidden"
      style={{
        display: "grid",
        gridTemplateRows: `repeat(${numberOfLines}, ${LINE_SPACING}px)`,
      }}
    >
      {Array.from({ length: numberOfLines }).map((_, index) => (
        <div
          key={index}
          className="w-full h-px bg-white/5"
          style={{
            transform: index === 0 ? "translateY(0)" : "translateY(-8.5px)",
          }}
        />
      ))}
    </div>
  );
};

export default BackgroundTexture;
