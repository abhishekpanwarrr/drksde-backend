// config/database.js
import { Pool } from "pg";
import dotenv from "dotenv";
dotenv.config();
console.log("Loaded DB_HOST:", process.env.DB_HOST);
console.log("Loaded DB_NAME:", process.env.DB_NAME);


const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // maximum number of clients in the pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test the connection (runs once on startup)
pool
  .connect()
  .then((client) => {
    console.log("Connected to PostgreSQL database");
    client.release();
  })
  .catch((err) => {
    console.error("Error connecting to PostgreSQL:", err);
  });

const db = {
  query: (text, params) => pool.query(text, params),
  pool,
};

export default db;
