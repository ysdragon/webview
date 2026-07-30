import { defineConfig } from "vite";
import angular from "@analogjs/vite-plugin-angular";
import { viteSingleFile } from "vite-plugin-singlefile";

export default defineConfig({
  resolve: {
    mainFields: ["module"],
  },
  plugins: [angular({ fastCompile: true }), viteSingleFile()],
});
