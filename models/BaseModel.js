// models/BaseModel.js
import db from "../config/database.js";

class BaseModel {
  constructor(tableName) {
    this.tableName = tableName;
  }

  async findAll(conditions = {}, options = {}) {
    const { limit = 100, offset = 0, orderBy = "created_at", order = "DESC" } = options;

    let query = `SELECT * FROM ${this.tableName} WHERE 1=1`;
    const values = [];
    let counter = 1;

    // Add conditions
    Object.keys(conditions).forEach((key) => {
      if (conditions[key] !== undefined && conditions[key] !== null) {
        query += ` AND ${key} = $${counter}`;
        values.push(conditions[key]);
        counter++;
      }
    });

    // Ordering & pagination
    query += ` ORDER BY ${orderBy} ${order} LIMIT $${counter} OFFSET $${counter + 1}`;
    values.push(limit, offset);

    const result = await db.query(query, values);
    return result.rows;
  }

  async findById(id) {
    const query = `
      SELECT * FROM ${this.tableName}
      WHERE ${this.tableName.slice(0, -1)}_id = $1
    `;
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  async findOne(conditions) {
    const keys = Object.keys(conditions);
    const values = Object.values(conditions);

    const placeholders = keys.map((key, index) => `${key} = $${index + 1}`).join(" AND ");

    const query = `
      SELECT * FROM ${this.tableName}
      WHERE ${placeholders}
      LIMIT 1
    `;

    const result = await db.query(query, values);
    return result.rows[0];
  }

  async create(data) {
    const keys = Object.keys(data);
    const values = Object.values(data);

    const placeholders = keys.map((_, index) => `$${index + 1}`).join(", ");
    const columns = keys.join(", ");

    const query = `
      INSERT INTO ${this.tableName} (${columns})
      VALUES (${placeholders})
      RETURNING *
    `;

    const result = await db.query(query, values);
    return result.rows[0];
  }

  async update(id, data) {
    const keys = Object.keys(data);
    const values = Object.values(data);

    const setClause = keys.map((key, index) => `${key} = $${index + 1}`).join(", ");

    const query = `
      UPDATE ${this.tableName}
      SET ${setClause}, updated_at = CURRENT_TIMESTAMP
      WHERE ${this.tableName.slice(0, -1)}_id = $${keys.length + 1}
      RETURNING *
    `;

    values.push(id);

    const result = await db.query(query, values);
    return result.rows[0];
  }

  async delete(id) {
    const query = `
      UPDATE ${this.tableName}
      SET is_active = false, updated_at = CURRENT_TIMESTAMP
      WHERE ${this.tableName.slice(0, -1)}_id = $1
      RETURNING *
    `;

    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  async hardDelete(id) {
    const query = `
      DELETE FROM ${this.tableName}
      WHERE ${this.tableName.slice(0, -1)}_id = $1
      RETURNING *
    `;

    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  async count(conditions = {}) {
    let query = `SELECT COUNT(*) FROM ${this.tableName} WHERE 1=1`;
    const values = [];
    let counter = 1;

    Object.keys(conditions).forEach((key) => {
      if (conditions[key] !== undefined && conditions[key] !== null) {
        query += ` AND ${key} = $${counter}`;
        values.push(conditions[key]);
        counter++;
      }
    });

    const result = await db.query(query, values);
    return parseInt(result.rows[0].count, 10);
  }
}

export default BaseModel;
