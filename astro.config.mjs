import node from "@astrojs/node";
import react from "@astrojs/react";
import emdash, { local } from "emdash/astro";
import { sqlite, postgres } from "emdash/db";
import { defineConfig } from "astro/config";

// Database selection. Quant Cloud injects DB_HOST for every environment in an
// application with a managed database, whatever its engine. emdash speaks
// SQLite or PostgreSQL only, so use Postgres when the injected port says so
// and fall back to SQLite on the EFS-mounted /data volume otherwise.
const usePostgres =
  process.env.DB_HOST && Number(process.env.DB_PORT || 5432) === 5432;

const database = usePostgres
  ? postgres({
      host: process.env.DB_HOST,
      port: 5432,
      database: process.env.DB_DATABASE || "emdash",
      user: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
    })
  : sqlite({ url: `file:${process.env.EMDASH_DB_PATH || "/data/data.db"}` });

export default defineConfig({
  output: "server",
  adapter: node({ mode: "standalone" }),
  security: {
    allowedDomains: [{}],
  },
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
