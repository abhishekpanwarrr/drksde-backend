// models/Category.js
import db from "../config/database.js";

/**
 * Find categories with full hierarchy (recursive tree)
 */
const findWithHierarchy = async (onlyActive = true) => {
  const query = `
    WITH RECURSIVE category_tree AS (
      SELECT 
        category_id,
        name,
        slug,
        parent_id,
        description,
        image_url,
        display_order,
        is_active,
        1 AS level,
        name AS path,
        ARRAY[category_id] AS path_ids
      FROM categories
      WHERE parent_id IS NULL ${onlyActive ? "AND is_active = true" : ""}

      UNION ALL

      SELECT
        c.category_id,
        c.name,
        c.slug,
        c.parent_id,
        c.description,
        c.image_url,
        c.display_order,
        c.is_active,
        ct.level + 1 AS level,
        ct.path || ' > ' || c.name AS path,
        ct.path_ids || c.category_id
      FROM categories c
      JOIN category_tree ct ON c.parent_id = ct.category_id
      WHERE ${onlyActive ? "c.is_active = true AND" : ""} 1=1
    )
    SELECT
      *,
      (
        SELECT COUNT(*)
        FROM product_categories pc
        WHERE pc.category_id = ct.category_id
      ) AS product_count
    FROM category_tree ct
    ORDER BY ct.path;
  `;

  const result = await db.query(query);
  return result.rows;
};

/**
 * Find category + all children recursively
 */
const findByIdWithChildren = async (id) => {
  const query = `
    WITH RECURSIVE category_tree AS (
      SELECT *
      FROM categories
      WHERE category_id = $1

      UNION ALL

      SELECT c.*
      FROM categories c
      JOIN category_tree ct ON c.parent_id = ct.category_id
      WHERE c.is_active = true
    )
    SELECT * FROM category_tree;
  `;

  const result = await db.query(query, [id]);
  return result.rows;
};

/**
 * Find category by ID
 */
const findById = async (id) => {
  const result = await db.query("SELECT * FROM categories WHERE category_id = $1", [id]);
  return result.rows[0];
};

/**
 * Find all categories with conditions
 */
const findAll = async (conditions = {}) => {
  let query = "SELECT * FROM categories WHERE 1=1";
  const values = [];
  let counter = 1;

  Object.entries(conditions).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      query += ` AND ${key} = $${counter}`;
      values.push(value);
      counter++;
    }
  });

  query += " ORDER BY display_order ASC";

  const result = await db.query(query, values);
  return result.rows;
};

/**
 * Create category
 */
const create = async (data) => {
  const keys = Object.keys(data);
  const values = Object.values(data);

  const columns = keys.join(", ");
  const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");

  const query = `
    INSERT INTO categories (${columns})
    VALUES (${placeholders})
    RETURNING *
  `;

  const result = await db.query(query, values);
  return result.rows[0];
};

/**
 * Update category
 */
const update = async (id, data) => {
  const keys = Object.keys(data);
  if (keys.length === 0) return null;

  const values = Object.values(data);
  const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(", ");

  const query = `
    UPDATE categories
    SET ${setClause}, updated_at = CURRENT_TIMESTAMP
    WHERE category_id = $${keys.length + 1}
    RETURNING *
  `;

  values.push(id);

  const result = await db.query(query, values);
  return result.rows[0];
};

/**
 * Soft delete category
 */
const remove = async (id) => {
  const result = await db.query(
    `
    UPDATE categories
    SET is_active = false, updated_at = CURRENT_TIMESTAMP
    WHERE category_id = $1
    RETURNING *
    `,
    [id],
  );
  return result.rows[0];
};

/**
 * Hard delete category
 */
const hardDelete = async (id) => {
  const result = await db.query("DELETE FROM categories WHERE category_id = $1 RETURNING *", [id]);
  return result.rows[0];
};

/**
 * Count categories
 */
const count = async (conditions = {}) => {
  let query = "SELECT COUNT(*) FROM categories WHERE 1=1";
  const values = [];
  let counter = 1;

  Object.entries(conditions).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      query += ` AND ${key} = $${counter}`;
      values.push(value);
      counter++;
    }
  });

  const result = await db.query(query, values);
  return parseInt(result.rows[0].count, 10);
};

/**
 * Get products under a category
 */
const getCategoryProducts = async (categoryId, options = {}) => {
  const { limit = 50, offset = 0, minPrice, maxPrice, inStock = true, brandIds } = options;

  let query = `
    SELECT DISTINCT p.*, b.name AS brand_name
    FROM products p
    JOIN product_categories pc ON p.product_id = pc.product_id
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    WHERE pc.category_id = $1
      AND p.is_active = true
  `;

  const values = [categoryId];
  let counter = 2;

  if (inStock) {
    query += " AND p.stock_quantity > 0";
  }

  if (minPrice !== undefined) {
    query += `
      AND (
        (p.sale_price IS NOT NULL AND p.sale_price >= $${counter})
        OR p.base_price >= $${counter}
      )
    `;
    values.push(minPrice);
    counter++;
  }

  if (maxPrice !== undefined) {
    query += `
      AND (
        (p.sale_price IS NOT NULL AND p.sale_price <= $${counter})
        OR p.base_price <= $${counter}
      )
    `;
    values.push(maxPrice);
    counter++;
  }

  if (brandIds?.length) {
    query += ` AND p.brand_id IN (${brandIds.map((_, i) => `$${counter + i}`).join(",")})`;
    values.push(...brandIds);
    counter += brandIds.length;
  }

  query += ` ORDER BY p.created_at DESC LIMIT $${counter} OFFSET $${counter + 1}`;
  values.push(limit, offset);

  const result = await db.query(query, values);
  return result.rows;
};

/**
 * Update display order (transaction-safe)
 */
const updateDisplayOrder = async (categories) => {
  const client = await db.pool.connect();

  try {
    await client.query("BEGIN");

    for (const cat of categories) {
      await client.query("UPDATE categories SET display_order = $1 WHERE category_id = $2", [
        cat.display_order,
        cat.category_id,
      ]);
    }

    await client.query("COMMIT");
    return { success: true };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

export default {
  findWithHierarchy,
  findByIdWithChildren,
  findById,
  findAll,
  create,
  update,
  delete: remove,
  hardDelete,
  count,
  getCategoryProducts,
  updateDisplayOrder,
};
