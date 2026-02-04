// models/User.js
import bcrypt from "bcryptjs";

import BaseModel from "./BaseModel.js";
import db from "../config/database.js";

class User extends BaseModel {
  constructor() {
    super("users");
  }

  async create(userData) {
    // Hash password before storing
    const hashedPassword = await bcrypt.hash(userData.password, 10);

    const data = {
      ...userData,
      password: hashedPassword,
      created_at: new Date(),
    };

    return await super.create(data);
  }

  async findByEmail(email) {
    const query = "SELECT * FROM users WHERE email = $1";
    const result = await db.query(query, [email]);
    return result.rows[0];
  }

  async comparePassword(candidatePassword, hashedPassword) {
    return await bcrypt.compare(candidatePassword, hashedPassword);
  }

  async updatePassword(userId, newPassword) {
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    const query = `
      UPDATE users
      SET password = $1, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2
      RETURNING user_id, email, role
    `;

    const result = await db.query(query, [hashedPassword, userId]);
    return result.rows[0];
  }
}

export default new User();
