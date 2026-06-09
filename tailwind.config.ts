import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#1D9E75",
          50: "#E8F7F1",
          100: "#C5EBDD",
          200: "#8FD7BB",
          300: "#59C399",
          400: "#2DAB7F",
          500: "#1D9E75",
          600: "#177E5E",
          700: "#125F47",
          800: "#0C3F2F",
          900: "#062018",
        },
        navy: {
          DEFAULT: "#0F172A",
          50: "#F8FAFC",
          100: "#F1F5F9",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#475569",
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A",
          950: "#020617",
        },
      },
      animation: {
        "pulse-slow": "pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        "fire-flicker": "fireFlicker 1.5s ease-in-out infinite",
        "ring-fill": "ringFill 1s ease-out forwards",
      },
      keyframes: {
        fireFlicker: {
          "0%, 100%": { transform: "scale(1)", opacity: "1" },
          "50%": { transform: "scale(1.1)", opacity: "0.8" },
        },
        ringFill: {
          "0%": { strokeDashoffset: "283" },
          "100%": { strokeDashoffset: "var(--ring-offset)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
