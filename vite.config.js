
import path from "path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      // eslint-disable-next-line no-undef
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    rollupOptions: {
      onwarn(warning, warn) {
        // Suppress certain warnings in Docker environment
        if (warning.code === "MODULE_LEVEL_DIRECTIVE") {
          return;
        }
        warn(warning);
      },
    },
  },

  server: {
    host: "0.0.0.0", // Allow external connections
    port: parseInt(process.env.PORT) || 80,
  },
  preview: {
    host: "0.0.0.0",
    port: parseInt(process.env.PORT) || 80,
  },
});