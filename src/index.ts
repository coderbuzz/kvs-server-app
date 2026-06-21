import { KVStore } from "@coderbuzz/kvs";
import { createServer } from "@coderbuzz/kvs-server";

const accessToken = process.env.ACCESS_TOKEN;
if (!accessToken) {
  console.error("ACCESS_TOKEN environment variable is required");
  process.exit(1);
}

const port = parseInt(process.env.PORT || "3000", 10);
const hostname = process.env.HOSTNAME || "0.0.0.0";
const dbPath = process.env.DB_PATH || "kv.db";

console.log(`Starting KVS server...`);
console.log(`  Database: ${dbPath}`);
console.log(`  Listening: ${hostname}:${port}`);

const store = new KVStore(dbPath);
const server = createServer(store, { port, hostname, accessToken });

await server.run();

console.log(`KVS server ready on ${hostname}:${port}`);

const shutdown = () => {
  console.log("\nShutting down...");
  server.stop();
  store.close();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
