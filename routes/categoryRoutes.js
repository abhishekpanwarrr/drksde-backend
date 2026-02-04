// routes/categoryRoutes.js
import express from "express";
import { body } from "express-validator";

import categoryController from "../controllers/categoryController.js";
import { authenticate, authorize } from "../middleware/auth.js";

const router = express.Router();

// Public routes
router.get("/", categoryController.getAllCategories);
router.get("/:id", categoryController.getCategory);
router.get("/:id/products", categoryController.getCategoryProducts);

// Admin routes (protected)
router.post(
  "/",
  authenticate,
  authorize("admin"),
  [
    body("name").trim().notEmpty().withMessage("Name is required"),
    body("slug").trim().notEmpty().withMessage("Slug is required"),
    body("parent_id").optional().isInt(),
    body("display_order").optional().isInt(),
  ],
  categoryController.createCategory,
);

router.put("/:id", authenticate, authorize("admin"), categoryController.updateCategory);

router.delete("/:id", authenticate, authorize("admin"), categoryController.deleteCategory);

router.put("/reorder", authenticate, authorize("admin"), categoryController.reorderCategories);

export default router;
