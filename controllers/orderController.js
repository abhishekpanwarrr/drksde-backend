// controllers/orderController.js
import db from "../config/database.js";

// export const createOrder = async (req, res, next) => {
//   try {
//     const { items, addressId, paymentMethod } = req.body;
//     const userId = req.user.userId;
//     if (!addressId) {
//       return res.status(400).json({ message: "Address is required" });
//     }
//     if (!items || items.length === 0) {
//       return res.status(400).json({ message: "Cart is empty" });
//     }

//     // Calculate total
//     let total = 0;
//     for (const item of items) {
//       total += Number(item.price) * item.quantity;
//     }

//     const orderResult = await db.query(
//       `INSERT INTO orders (user_id, total_amount, payment_method,address_id)
//        VALUES ($1, $2, $3, $4) RETURNING order_id`,
//       [userId, total, paymentMethod],
//     );

//     const orderId = orderResult.rows[0].order_id;

//     for (const item of items) {
//       await db.query(
//         `INSERT INTO order_items (order_id, product_id, quantity, price)
//          VALUES ($1, $2, $3, $4)`,
//         [orderId, item.product_id, item.quantity, item.price],
//       );
//     }

//     res.status(201).json({
//       status: "success",
//       order_id: orderId,
//     });
//   } catch (err) {
//     next(err);
//   }
// };


export const createOrder = async (req, res, next) => {
  const client = await db.pool.connect();

  try {
    const { items, addressId, paymentMethod } = req.body;
    const userId = req.user.userId;

    if (!addressId) {
      return res.status(400).json({ message: "Address is required" });
    }

    if (!items || items.length === 0) {
      return res.status(400).json({ message: "Cart is empty" });
    }

    // 🔒 Verify address belongs to user
    const addressCheck = await client.query(
      "SELECT address_id FROM addresses WHERE address_id = $1 AND user_id = $2",
      [addressId, userId],
    );

    if (addressCheck.rowCount === 0) {
      return res.status(403).json({ message: "Invalid address" });
    }

    await client.query("BEGIN");

    let total = 0;
    const verifiedItems = [];

    // 🔒 Recalculate price from DB (IMPORTANT)
    for (const item of items) {
      const productRes = await client.query(
        `
        SELECT product_id, 
               COALESCE(sale_price, base_price) AS price
        FROM products
        WHERE product_id = $1 AND is_active = true
        `,
        [item.product_id],
      );

      if (productRes.rowCount === 0) {
        throw new Error("Invalid product in cart");
      }

      const price = Number(productRes.rows[0].price);
      const lineTotal = price * item.quantity;

      total += lineTotal;

      verifiedItems.push({
        product_id: item.product_id,
        quantity: item.quantity,
        price,
      });
    }

    // ✅ Create order
    const orderResult = await client.query(
      `
      INSERT INTO orders (user_id, total_amount, payment_method, address_id)
      VALUES ($1, $2, $3, $4)
      RETURNING order_id
      `,
      [userId, total, paymentMethod, addressId],
    );

    const orderId = orderResult.rows[0].order_id;

    // ✅ Insert order items
    for (const item of verifiedItems) {
      await client.query(
        `
        INSERT INTO order_items (order_id, product_id, quantity, price)
        VALUES ($1, $2, $3, $4)
        `,
        [orderId, item.product_id, item.quantity, item.price],
      );
    }

    await client.query("COMMIT");

    res.status(201).json({
      status: "success",
      order_id: orderId,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
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
