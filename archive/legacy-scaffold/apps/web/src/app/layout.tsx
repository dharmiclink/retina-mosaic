import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Retina Mosaic",
  description: "Continuous video retinal mosaicking web app"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
