import db from "../config/database.js";


const getNewReleases = async (limit = 10) => {
    const { rows } = await db.query(
        `
    SELECT *
    FROM products
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT $1
    `,
        [limit]
    );
    return rows;
};

const getAllProducts = async (limit = 20) => {
    const { rows } = await db.query(
        `
    SELECT *
    FROM products
    WHERE is_active = true
    ORDER BY sale_price DESC NULLS LAST
    LIMIT $1
    `,
        [limit]
    );
    return rows;
};

export default {
    getNewReleases,
    getAllProducts,
};
