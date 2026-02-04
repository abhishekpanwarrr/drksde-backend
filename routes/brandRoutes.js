// routes/brandRoutes.js
import express from "express";
import { body } from "express-validator";

import brandController from "../controllers/brandController.js";
import { authenticate, authorize } from "../middleware/auth.js";

const router = express.Router();

// Public routes
router.get("/", brandController.getAllBrands);
router.get("/:id", brandController.getBrand);
router.get("/:id/products", brandController.getBrandProducts);

// Admin routes (protected)
router.post(
  "/",
  authenticate,
  authorize("admin"),
  [
    body("name").trim().notEmpty().withMessage("Name is required"),
    body("slug").trim().notEmpty().withMessage("Slug is required"),
  ],
  brandController.createBrand,
);

router.put("/:id", authenticate, authorize("admin"), brandController.updateBrand);

router.delete("/:id", authenticate, authorize("admin"), brandController.deleteBrand);

export default router;
