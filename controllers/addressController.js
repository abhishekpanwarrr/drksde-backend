import db from "../config/database.js";

export const getMyAddresses = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      "SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC",
      [userId]
    );

    res.json({ status: "success", data: result.rows });
  } catch (err) {
    next(err);
  }
};

export const addAddress = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const {
      name,
      phone,
      address_line,
      city,
      state,
      pincode,
      type,
      is_default,
    } = req.body;

    const result = await db.query(
      `
      INSERT INTO addresses 
      (user_id, name, phone, address_line, city, state, pincode, type, is_default)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      RETURNING *
      `,
      [userId, name, phone, address_line, city, state, pincode, type, is_default]
    );

    res.status(201).json({ status: "success", data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

export const updateAddress = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const { name, phone, address_line, city, state, pincode, type, is_default } = req.body;

    if (is_default) {
      await db.query(
        "UPDATE addresses SET is_default = false WHERE user_id = $1",
        [userId]
      );
    }

    const result = await db.query(
      `
      UPDATE addresses
      SET name=$1, phone=$2, address_line=$3, city=$4,
          state=$5, pincode=$6, type=$7, is_default=$8
      WHERE address_id=$9 AND user_id=$10
      RETURNING *
      `,
      [name, phone, address_line, city, state, pincode, type, is_default, id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Address not found" });
    }

    res.json({ status: "success", data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};


export const deleteAddress = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    const result = await db.query(
      "DELETE FROM addresses WHERE address_id = $1 AND user_id = $2",
      [id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Address not found" });
    }

    res.json({ status: "success" });
  } catch (err) {
    next(err);
  }
};

export const setDefaultAddress = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    // unset old default
    await db.query(
      `UPDATE addresses SET is_default = false WHERE user_id = $1`,
      [userId],
    );

    // set new default
    await db.query(
      `UPDATE addresses SET is_default = true WHERE address_id = $1 AND user_id = $2`,
      [id, userId],
    );

    res.json({ status: "success" });
  } catch (err) {
    next(err);
  }
};
