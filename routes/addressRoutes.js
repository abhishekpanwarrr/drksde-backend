import express from "express";
import { authenticate } from "../middleware/auth.js";
import { getMyAddresses, addAddress, updateAddress, deleteAddress, setDefaultAddress } from "../controllers/addressController.js";

const router = express.Router();

router.get("/my", authenticate, getMyAddresses);
router.post("/", authenticate, addAddress);
router.put("/:id", authenticate, updateAddress);
router.patch("/:id/default", authenticate, setDefaultAddress);
router.delete("/:id", authenticate, deleteAddress);

export default router;
