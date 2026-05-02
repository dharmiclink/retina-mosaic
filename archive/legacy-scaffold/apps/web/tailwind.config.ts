import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        canvas: "#f3f5f7",
        accent: "#0a7f6f",
        ink: "#102a2a"
      }
    }
  },
  plugins: []
};

export default config;
