// scripts/migrate.js
const db = require("../config/database");
const fs = require("fs");
const path = require("path");

async function runMigrations() {
  const client = await db.pool.connect();

  try {
    await client.query("BEGIN");

    console.log("Starting database migrations...");

    // Read migration file
    const migrationPath = path.join(__dirname, "..", "migrations", "schema.sql");
    const migrationSQL = fs.readFileSync(migrationPath, "utf8");

    // Execute migration
    await client.query(migrationSQL);

    await client.query("COMMIT");
    console.log("Migrations completed successfully!");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Migration failed:", error);
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

runMigrations();
