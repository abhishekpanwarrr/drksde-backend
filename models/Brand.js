// models/Brand.js
import BaseModel from "./BaseModel.js";
import db from "../config/database.js";

class Brand extends BaseModel {
  constructor() {
    super("brands");
  }

  async findAllWithProductCount() {
    const query = `
      SELECT 
        b.*,
        COUNT(p.product_id) AS product_count
      FROM brands b
      LEFT JOIN products p 
        ON b.brand_id = p.brand_id 
       AND p.is_active = true
      WHERE b.is_active = true
      GROUP BY b.brand_id
      ORDER BY b.name
    `;

    const result = await db.query(query);
    return result.rows;
  }

  async getBrandProducts(brandId, options = {}) {
    const { limit = 50, offset = 0, categoryId } = options;

    let query = `
      SELECT p.*
      FROM products p
      WHERE p.brand_id = $1
        AND p.is_active = true
    `;

    const values = [brandId];
    let counter = 2;

    if (categoryId) {
      query += `
        AND EXISTS (
          SELECT 1
          FROM product_categories pc
          WHERE pc.product_id = p.product_id
            AND pc.category_id = $${counter}
        )
      `;
      values.push(categoryId);
      counter++;
    }

    query += ` ORDER BY p.created_at DESC LIMIT $${counter} OFFSET $${counter + 1}`;
    values.push(limit, offset);

    const result = await db.query(query, values);
    return result.rows;
  }
}

export default new Brand();
