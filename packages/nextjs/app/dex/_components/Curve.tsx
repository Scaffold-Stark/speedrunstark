import { FC, useEffect, useRef } from "react";

const drawArrow = (
  ctx: CanvasRenderingContext2D,
  x1: number,
  y1: number,
  x2: number,
  y2: number,
) => {
  const [dx, dy] = [x1 - x2, y1 - y2];
  const norm = Math.sqrt(dx * dx + dy * dy);
  const [udx, udy] = [dx / norm, dy / norm];
  const size = norm / 7;
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
  ctx.moveTo(x2, y2);
  ctx.lineTo(x2 + udx * size - udy * size, y2 + udx * size + udy * size);
  ctx.moveTo(x2, y2);
  ctx.lineTo(x2 + udx * size + udy * size, y2 - udx * size + udy * size);
  ctx.stroke();
};

export interface ICurveProps {
  strkReserve: number;
  tokenReserve: number;
  addingStrk: number;
  addingToken: number;
  width: number;
  height: number;
  isDarkMode: boolean;
}

export const Curve: FC<ICurveProps> = (props: ICurveProps) => {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) {
      return;
    }

    const textSize = 12;

    const width = canvas.width;
    const height = canvas.height;

    if (props.strkReserve && props.tokenReserve) {
      const k = props.strkReserve * props.tokenReserve;

      const ctx = canvas.getContext("2d");
      if (ctx == null) {
        return;
      }
      ctx.clearRect(0, 0, width, height);

      let maxX = k / (props.strkReserve / 4);
      let minX = 0;

      if (props.addingStrk || props.addingToken) {
        maxX = k / (props.strkReserve * 0.4);
        //maxX = k/(props.strkReserve*0.8)
        minX = k / Math.max(0, 500 - props.strkReserve);
      }

      const maxY = (maxX * height) / width;
      const minY = (minX * height) / width;

      const plotX = (x: number) => {
        return ((x - minX) / (maxX - minX)) * width;
      };

      const plotY = (y: number) => {
        return height - ((y - minY) / (maxY - minY)) * height;
      };
      if (props.isDarkMode) {
        ctx.strokeStyle = "#bbbbbb";
      } else {
        ctx.strokeStyle = "#000000";
      }
      ctx.fillStyle = "#000000";
      ctx.font = textSize + "px Arial";
      // +Y axis
      ctx.beginPath();
      ctx.moveTo(plotX(minX), plotY(0));
      ctx.lineTo(plotX(minX), plotY(maxY));
      ctx.stroke();
      // +X axis
      ctx.beginPath();
      ctx.moveTo(plotX(0), plotY(minY));
      ctx.lineTo(plotX(maxX), plotY(minY));
      ctx.stroke();

      ctx.lineWidth = 2;
      ctx.beginPath();
      let first = true;
      for (let x = minX; x <= maxX; x += maxX / width) {
        /////
        const y = k / x;
        /////
        if (first) {
          ctx.moveTo(plotX(x), plotY(y));
          first = false;
        } else {
          ctx.lineTo(plotX(x), plotY(y));
        }
      }
      ctx.stroke();

      ctx.lineWidth = 1;

      if (props.addingStrk) {
        const newStrkReserve =
          props.strkReserve + parseFloat(props.addingStrk.toString());

        ctx.fillStyle = "#bbbbbb";
        ctx.beginPath();
        ctx.arc(
          plotX(newStrkReserve),
          plotY(k / newStrkReserve),
          5,
          0,
          2 * Math.PI,
        );
        ctx.fill();

        ctx.strokeStyle = "#009900";
        drawArrow(
          ctx,
          plotX(props.strkReserve),
          plotY(props.tokenReserve),
          plotX(newStrkReserve),
          plotY(props.tokenReserve),
        );

        if (props.isDarkMode) {
          ctx.fillStyle = "#bbbbbb";
        } else {
          ctx.fillStyle = "#000000";
        }
        ctx.fillText(
          "" + props.addingStrk + " STRK input",
          plotX(props.strkReserve) + textSize,
          plotY(props.tokenReserve) - textSize,
        );

        ctx.strokeStyle = "#990000";
        drawArrow(
          ctx,
          plotX(newStrkReserve),
          plotY(props.tokenReserve),
          plotX(newStrkReserve),
          plotY(k / newStrkReserve),
        );

        const amountGained =
          Math.round(
            (10000 * (props.addingStrk * props.tokenReserve)) / newStrkReserve,
          ) / 10000;

        if (props.isDarkMode) {
          ctx.fillStyle = "#bbbbbb";
        } else {
          ctx.fillStyle = "#000000";
        }
        ctx.fillText(
          "" + amountGained + " 🎈 output (-0.3% fee)",
          plotX(newStrkReserve) + textSize,
          plotY(k / newStrkReserve),
        );
      } else if (props.addingToken) {
        const newTokenReserve =
          props.tokenReserve + parseFloat(props.addingToken.toString());

        ctx.fillStyle = "#bbbbbb";
        ctx.beginPath();
        ctx.arc(
          plotX(k / newTokenReserve),
          plotY(newTokenReserve),
          5,
          0,
          2 * Math.PI,
        );
        ctx.fill();

        //console.log("newTokenReserve",newTokenReserve)
        ctx.strokeStyle = "#990000";
        drawArrow(
          ctx,
          plotX(props.strkReserve),
          plotY(props.tokenReserve),
          plotX(props.strkReserve),
          plotY(newTokenReserve),
        );

        if (props.isDarkMode) {
          ctx.fillStyle = "#bbbbbb";
        } else {
          ctx.fillStyle = "#000000";
        }
        ctx.fillText(
          "" + props.addingToken + " 🎈 input",
          plotX(props.strkReserve) + textSize,
          plotY(props.tokenReserve),
        );

        ctx.strokeStyle = "#009900";
        drawArrow(
          ctx,
          plotX(props.strkReserve),
          plotY(newTokenReserve),
          plotX(k / newTokenReserve),
          plotY(newTokenReserve),
        );

        const amountGained =
          Math.round(
            (10000 * (props.addingToken * props.strkReserve)) / newTokenReserve,
          ) / 10000;
        //console.log("amountGained",amountGained)
        if (props.isDarkMode) {
          ctx.fillStyle = "#bbbbbb";
        } else {
          ctx.fillStyle = "#000000";
        }
        ctx.fillText(
          "" + amountGained + " STRK output (-0.3% fee)",
          plotX(k / newTokenReserve) + textSize,
          plotY(newTokenReserve) - textSize,
        );
      }

      ctx.fillStyle = "#0000FF";
      ctx.beginPath();
      ctx.arc(
        plotX(props.strkReserve),
        plotY(props.tokenReserve),
        5,
        0,
        2 * Math.PI,
      );
      ctx.fill();
    }
  }, [props]);

  return (
    <div
      style={{ position: "relative", width: props.width, height: props.height }}
    >
      <canvas
        style={{ position: "absolute", left: 0, top: 0 }}
        ref={ref}
        width={props.width}
        height={props.height}
      />
      <div style={{ position: "absolute", left: "20%", bottom: -20 }}>
        -- STRK Reserve --{">"}
      </div>
      <div
        style={{
          position: "absolute",
          left: -20,
          bottom: "20%",
          transform: "rotate(-90deg)",
          transformOrigin: "0 0",
        }}
      >
        -- Token Reserve --{">"}
      </div>
    </div>
  );
};
