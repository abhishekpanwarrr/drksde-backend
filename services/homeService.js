import redis from "../config/redis.js";
import productRepository from "../repositories/productRepository.js";

const HOME_CACHE_KEY = "home_page_v1";
const HOME_CACHE_TTL = 60; // seconds

const getHomeData = async () => {
    const cached = await redis.get(HOME_CACHE_KEY);

    if (cached) {
        return JSON.parse(cached);
    }

    // 2️⃣ Build fresh data
    const [newReleases, allProducts] = await Promise.all([
        productRepository.getNewReleases(10),
        productRepository.getAllProducts(20),
    ]);

    const homeData = {
        sections: {
            newReleases: {
                title: "New Arrivals",
                items: newReleases,
            },
            allProducts: {
                title: "All Products",
                items: allProducts,
            },
        },
    };

    redis.set(
        HOME_CACHE_KEY,
        JSON.stringify(homeData),
        "EX",
        HOME_CACHE_TTL
    ).catch(() => { });

    return homeData;
};

export default {
    getHomeData,
};
