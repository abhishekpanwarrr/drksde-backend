// models/Product.js
import db from "../config/database.js";

/**
 * Get all products with filters & joins
 */
const findAllWithDetails = async (options = {}) => {
  const {
    categoryId,
    brandId,
    minPrice,
    maxPrice,
    inStock = true,
    isFeatured,
    search,
    limit = 50,
    offset = 0,
    sortBy = "created_at",
    sortOrder = "DESC",
  } = options;

  let query = `
    SELECT 
      p.*,
      b.name AS brand_name,
      b.logo_url AS brand_logo,
      (
        SELECT pi.image_url
        FROM product_images pi
        WHERE pi.product_id = p.product_id
          AND pi.is_primary = true
        LIMIT 1
      ) AS primary_image,
      (
        SELECT STRING_AGG(c.name, ', ')
        FROM categories c
        JOIN product_categories pc ON c.category_id = pc.category_id
        WHERE pc.product_id = p.product_id
      ) AS categories
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    WHERE p.is_active = true
  `;

  const values = [];
  let counter = 1;

  if (categoryId) {
    query += `
      AND EXISTS (
        SELECT 1 FROM product_categories pc
        WHERE pc.product_id = p.product_id
          AND pc.category_id = $${counter}
      )
    `;
    values.push(categoryId);
    counter++;
  }

  if (brandId) {
    query += ` AND p.brand_id = $${counter}`;
    values.push(brandId);
    counter++;
  }

  if (inStock) {
    query += ` AND p.stock_quantity > 0`;
  }

  if (isFeatured !== undefined) {
    query += ` AND p.is_featured = $${counter}`;
    values.push(isFeatured);
    counter++;
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

  if (search) {
    query += `
      AND (
        p.name ILIKE $${counter}
        OR p.short_description ILIKE $${counter}
        OR p.sku ILIKE $${counter}
      )
    `;
    values.push(`%${search}%`);
    counter++;
  }

  const validSortColumns = ["created_at", "base_price", "name", "stock_quantity"];
  const sortColumn = validSortColumns.includes(sortBy) ? sortBy : "created_at";
  const order = sortOrder.toUpperCase() === "ASC" ? "ASC" : "DESC";

  query += ` ORDER BY ${sortColumn} ${order} LIMIT $${counter} OFFSET $${counter + 1}`;
  values.push(limit, offset);

  const result = await db.query(query, values);
  return result.rows;
};

/**
 * Get product by ID with full details
 */
const findByIdWithDetails = async (id) => {
  const query = `
    SELECT 
      p.*,
      b.name AS brand_name,
      b.description AS brand_description,
      b.logo_url AS brand_logo,
      (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'image_id', pi.image_id,
            'image_url', pi.image_url,
            'alt_text', pi.alt_text,
            'display_order', pi.display_order,
            'is_primary', pi.is_primary
          )
          ORDER BY pi.display_order
        )
        FROM product_images pi
        WHERE pi.product_id = p.product_id
      ) AS images,
      (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'category_id', c.category_id,
            'name', c.name,
            'slug', c.slug,
            'is_primary', pc.is_primary
          )
        )
        FROM categories c
        JOIN product_categories pc ON c.category_id = pc.category_id
        WHERE pc.product_id = p.product_id
      ) AS categories,
      (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'variant_id', pv.variant_id,
            'sku', pv.sku,
            'price_adjustment', pv.price_adjustment,
            'stock_quantity', pv.stock_quantity,
            'image_url', pv.image_url,
            'is_default', pv.is_default,
            'attributes', (
              SELECT JSON_AGG(
                JSON_BUILD_OBJECT(
                  'attribute_name', pa.name,
                  'value', av.value,
                  'hex_code', av.hex_code
                )
              )
              FROM variant_attribute_values vav
              JOIN attribute_values av ON vav.value_id = av.value_id
              JOIN product_attributes pa ON av.attribute_id = pa.attribute_id
              WHERE vav.variant_id = pv.variant_id
            )
          )
        )
        FROM product_variants pv
        WHERE pv.product_id = p.product_id
      ) AS variants
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    WHERE p.product_id = $1
      AND p.is_active = true
  `;

  const result = await db.query(query, [id]);
  return result.rows[0];
};

/**
 * Find product by slug
 */
const findBySlug = async (slug) => {
  const result = await db.query(
    `
    SELECT p.*, b.name AS brand_name, b.logo_url AS brand_logo
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    WHERE p.slug = $1 AND p.is_active = true
    `,
    [slug],
  );
  return result.rows[0];
};

/**
 * Related products
 */
const getRelatedProducts = async (productId, limit = 8) => {
  const result = await db.query(
    `
    WITH product_cats AS (
      SELECT category_id FROM product_categories WHERE product_id = $1
    )
    SELECT DISTINCT p.*, b.name AS brand_name
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    JOIN product_categories pc ON p.product_id = pc.product_id
    WHERE pc.category_id IN (SELECT category_id FROM product_cats)
      AND p.product_id != $1
      AND p.is_active = true
      AND p.stock_quantity > 0
    ORDER BY RANDOM()
    LIMIT $2
    `,
    [productId, limit],
  );

  return result.rows;
};

/**
 * Update stock (transaction-safe)
 */
const updateStock = async (productId, quantityChange, variantId = null) => {
  const client = await db.pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(
      `
      UPDATE products
      SET stock_quantity = stock_quantity + $1,
          updated_at = CURRENT_TIMESTAMP
      WHERE product_id = $2
      `,
      [quantityChange, productId],
    );

    if (variantId) {
      await client.query(
        `
        UPDATE product_variants
        SET stock_quantity = stock_quantity + $1
        WHERE variant_id = $2
        `,
        [quantityChange, variantId],
      );
    }

    await client.query(
      `
      INSERT INTO inventory_logs
        (product_id, variant_id, quantity_change, new_quantity, reason, reference_id)
      VALUES (
        $1, $2, $3,
        (SELECT stock_quantity FROM products WHERE product_id = $1),
        'manual_adjustment',
        'SYSTEM'
      )
      `,
      [productId, variantId, quantityChange],
    );

    await client.query("COMMIT");
    return { success: true };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Full-text product search
 */
const searchProducts = async (searchTerm, options = {}) => {
  const { limit = 20, offset = 0 } = options;

  const result = await db.query(
    `
    SELECT
      p.*,
      b.name AS brand_name,
      (
        SELECT pi.image_url
        FROM product_images pi
        WHERE pi.product_id = p.product_id
          AND pi.is_primary = true
        LIMIT 1
      ) AS primary_image,
      ts_rank(
        to_tsvector('english', p.name || ' ' || p.short_description || ' ' || COALESCE(p.long_description, '')),
        plainto_tsquery('english', $1)
      ) AS relevance
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    WHERE p.is_active = true
      AND (
        p.name ILIKE $2
        OR p.short_description ILIKE $2
        OR p.sku ILIKE $2
        OR to_tsvector(
          'english',
          p.name || ' ' || p.short_description || ' ' || COALESCE(p.long_description, '')
        ) @@ plainto_tsquery('english', $1)
      )
    ORDER BY relevance DESC, p.created_at DESC
    LIMIT $3 OFFSET $4
    `,
    [searchTerm, `%${searchTerm}%`, limit, offset],
  );

  return result.rows;
};

/**
 * Count products
 */
const count = async (conditions = {}) => {
  let query = "SELECT COUNT(*) FROM products WHERE 1=1";
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

export default {
  findAllWithDetails,
  findByIdWithDetails,
  findBySlug,
  getRelatedProducts,
  updateStock,
  searchProducts,
  count,
};
