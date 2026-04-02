import node from "@astrojs/node";
import react from "@astrojs/react";
import emdash, { local } from "emdash/astro";
import { sqlite, postgres } from "emdash/db";
import { defineConfig } from "astro/config";

// Auto-detect database: PostgreSQL when DB_HOST is set (Quant Cloud managed DB),
// otherwise SQLite on the EFS-mounted /data volume.
const database = process.env.DB_HOST
  ? postgres({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT || 5432),
      database: process.env.DB_DATABASE || "emdash",
      user: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
    })
  : sqlite({ url: `file:${process.env.EMDASH_DB_PATH || "/data/data.db"}` });

export default defineConfig({
  output: "server",
  adapter: node({ mode: "standalone" }),
  image: {
    experimentalLayout: "constrained",
  },
  integrations: [
    react(),
    emdash({
      database,
      storage: local({
        directory: process.env.EMDASH_UPLOADS_DIR || "/data/uploads",
        baseUrl: "/_emdash/api/media/file",
      }),
      mediaEndpoint: "/_emdash/api/media/file",
    }),
  ],
  devToolbar: { enabled: false },
});
