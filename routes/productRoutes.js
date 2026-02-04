// routes/productRoutes.js
import express from "express";
import { body } from "express-validator";

import productController from "../controllers/productController.js";
import { authenticate, authorize } from "../middleware/auth.js";

const router = express.Router();

// Public routes
router.get("/", productController.getAllProducts);
router.get("/search", productController.searchProducts);
router.get("/featured", productController.getFeaturedProducts);
router.get("/:id", productController.getProduct);
router.get("/:id/related", productController.getRelatedProducts);

// Admin routes (protected)
router.post(
  "/",
  authenticate,
  authorize("admin"),
  [
    body("name").trim().notEmpty().withMessage("Name is required"),
    body("sku").trim().notEmpty().withMessage("SKU is required"),
    body("base_price").isFloat({ gt: 0 }).withMessage("Valid base price is required"),
    body("stock_quantity").optional().isInt({ min: 0 }),
  ],
  productController.createProduct,
);

router.put("/:id", authenticate, authorize("admin"), productController.updateProduct);

router.delete("/:id", authenticate, authorize("admin"), productController.deleteProduct);

router.patch(
  "/:id/stock",
  authenticate,
  authorize("admin"),
  [
    body("quantity").isInt().withMessage("Quantity must be an integer"),
    body("variantId").optional().isInt(),
  ],
  productController.updateStock,
);

export default router;
