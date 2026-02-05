import express from "express";
import { authenticate } from "../middleware/auth.js";
import { createOrder, getMyOrders } from "../controllers/orderController.js";

const router = express.Router();

router.get("/my", authenticate, getMyOrders);
// Create order (Checkout)
router.post("/", authenticate, createOrder);

export default router;
