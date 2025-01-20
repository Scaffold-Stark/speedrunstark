import type { Metadata } from "next";
import { ScaffoldStarkAppWithProviders } from "~~/components/ScaffoldStarkAppWithProviders";
import "~~/styles/globals.css";
import { ThemeProvider } from "~~/components/ThemeProvider";
import { Aldrich, VT323 } from "next/font/google";
import localFont from "next/font/local";

export const metadata: Metadata = {
  title: "SpeedRun Stark",
  description: "Fast track your starknet journey",
  icons: "/logo.ico",
};

const aldrich = Aldrich({
  subsets: ["latin"],
  weight: "400",
  variable: "--font-aldrich",
  display: "swap",
});

const vt323 = VT323({
  subsets: ["latin"],
  weight: "400",
  variable: "--font-vt323",
  display: "swap",
});

const digital = localFont({
  src: "../../../packages/nextjs/public/fonts/DigitalNumbers-Regular.ttf",
  variable: "--font-digital",
});

const ScaffoldStarkApp = ({ children }: { children: React.ReactNode }) => {
  return (
    <html suppressHydrationWarning>
      <body
        className={`${aldrich.variable} ${vt323.variable} ${digital.variable}`}
      >
        <ThemeProvider enableSystem>
          <ScaffoldStarkAppWithProviders>
            {children}
          </ScaffoldStarkAppWithProviders>
        </ThemeProvider>
      </body>
    </html>
  );
};

export default ScaffoldStarkApp;
