import Redis from "ioredis";

const redis = new Redis({
    host: process.env.REDIS_HOST || "127.0.0.1",
    port: Number(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,

    // 🚫 Disable retries & offline queue
    maxRetriesPerRequest: null,
    enableOfflineQueue: false,

    // 🚫 Stop reconnection spam
    retryStrategy: () => null,
});

redis.on("connect", () => {
    console.log("Redis connected");
});

redis.on("error", (err) => {
    console.error("Redis error:", err);
});

export default redis;




// import Redis from "ioredis";

// const redis = new Redis({
//   host: process.env.REDIS_HOST,
//   port: Number(process.env.REDIS_PORT),
//   password: process.env.REDIS_PASSWORD,

//   retryStrategy: (times) => {
//     // exponential backoff, max 2s
//     return Math.min(times * 100, 2000);
//   },
// });

// redis.on("connect", () => {
//   console.log("Redis connected");
// });

// redis.on("error", (err) => {
//   console.error("Redis error:", err.message);
// });

// export default redis;
