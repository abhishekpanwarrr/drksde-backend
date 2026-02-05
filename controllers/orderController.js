// controllers/orderController.js
import db from "../config/database.js";

export const createOrder = async (req, res, next) => {
  try {
    const { items, addressId, paymentMethod } = req.body;
    const userId = req.user.userId;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: "Cart is empty" });
    }

    // Calculate total
    let total = 0;
    for (const item of items) {
      total += Number(item.price) * item.quantity;
    }

    const orderResult = await db.query(
      `INSERT INTO orders (user_id, total_amount, payment_method)
       VALUES ($1, $2, $3) RETURNING order_id`,
      [userId, total, paymentMethod],
    );

    const orderId = orderResult.rows[0].order_id;

    for (const item of items) {
      await db.query(
        `INSERT INTO order_items (order_id, product_id, quantity, price)
         VALUES ($1, $2, $3, $4)`,
        [orderId, item.product_id, item.quantity, item.price],
      );
    }

    res.status(201).json({
      status: "success",
      order_id: orderId,
    });
  } catch (err) {
    next(err);
  }
};

export const getMyOrders = async (req, res, next) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      `
      SELECT 
        o.order_id,
        o.total_amount,
        o.payment_method,
        o.payment_status,
        o.order_status,
        o.created_at,
        json_agg(
          json_build_object(
            'product_id', p.product_id,
            'name', p.name,
            'quantity', oi.quantity,
            'price', oi.price,
            'image', (
              SELECT image_url 
              FROM product_images 
              WHERE product_id = p.product_id 
              AND is_primary = true
              LIMIT 1
            )
          )
        ) AS items
      FROM orders o
      JOIN order_items oi ON o.order_id = oi.order_id
      JOIN products p ON oi.product_id = p.product_id
      WHERE o.user_id = $1
      GROUP BY o.order_id
      ORDER BY o.created_at DESC
      `,
      [userId],
    );

    res.json({
      status: "success",
      data: result.rows,
    });
  } catch (err) {
    next(err);
  }
};
