// controllers/brandController.js
import { validationResult } from "express-validator";

import Brand from "../models/Brand.js";

const getAllBrands = async (req, res, next) => {
  try {
    const { withProducts = "false" } = req.query;

    let brands;
    if (withProducts === "true") {
      brands = await Brand.findAllWithProductCount();
    } else {
      brands = await Brand.findAll({ is_active: true });
    }

    res.status(200).json({
      status: "success",
      count: brands.length,
      data: brands,
    });
  } catch (error) {
    next(error);
  }
};

const getBrand = async (req, res, next) => {
  try {
    const { id } = req.params;
    const brand = await Brand.findById(id);

    if (!brand) {
      return res.status(404).json({
        status: "error",
        message: "Brand not found",
      });
    }

    res.status(200).json({
      status: "success",
      data: brand,
    });
  } catch (error) {
    next(error);
  }
};

const createBrand = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        status: "error",
        errors: errors.array(),
      });
    }

    const brandData = req.body;
    const brand = await Brand.create(brandData);

    res.status(201).json({
      status: "success",
      message: "Brand created successfully",
      data: brand,
    });
  } catch (error) {
    next(error);
  }
};

const updateBrand = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const brand = await Brand.update(id, updateData);

    if (!brand) {
      return res.status(404).json({
        status: "error",
        message: "Brand not found",
      });
    }

    res.status(200).json({
      status: "success",
      message: "Brand updated successfully",
      data: brand,
    });
  } catch (error) {
    next(error);
  }
};

const deleteBrand = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { hardDelete = "false" } = req.query;

    let brand;
    if (hardDelete === "true") {
      brand = await Brand.hardDelete(id);
    } else {
      brand = await Brand.delete(id);
    }

    if (!brand) {
      return res.status(404).json({
        status: "error",
        message: "Brand not found",
      });
    }

    res.status(200).json({
      status: "success",
      message: hardDelete === "true" ? "Brand permanently deleted" : "Brand deactivated",
      data: brand,
    });
  } catch (error) {
    next(error);
  }
};

const getBrandProducts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, categoryId } = req.query;

    const offset = (page - 1) * limit;

    const options = {
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
      categoryId: categoryId ? parseInt(categoryId, 10) : undefined,
    };

    const products = await Brand.getBrandProducts(id, options);
    const total = await Brand.count({ brand_id: id });

    res.status(200).json({
      status: "success",
      pagination: {
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
        total,
        pages: Math.ceil(total / limit),
      },
      data: products,
    });
  } catch (error) {
    next(error);
  }
};

export default {
  getAllBrands,
  getBrand,
  createBrand,
  updateBrand,
  deleteBrand,
  getBrandProducts,
};
