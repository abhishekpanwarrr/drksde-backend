// controllers/categoryController.js
import { validationResult } from "express-validator";

import Category from "../models/Category.js";

const getAllCategories = async (req, res, next) => {
  try {
    const { withHierarchy = "true" } = req.query;

    let categories;
    if (withHierarchy === "true") {
      categories = await Category.findWithHierarchy();
    } else {
      categories = await Category.findAll({ is_active: true });
    }

    res.status(200).json({
      status: "success",
      count: categories.length,
      data: categories,
    });
  } catch (error) {
    next(error);
  }
};

const getCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { withChildren = "false" } = req.query;

    let category;
    if (withChildren === "true") {
      category = await Category.findByIdWithChildren(id);
    } else {
      category = await Category.findById(id);
    }

    if (!category) {
      return res.status(404).json({
        status: "error",
        message: "Category not found",
      });
    }

    res.status(200).json({
      status: "success",
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

const createCategory = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        status: "error",
        errors: errors.array(),
      });
    }

    const categoryData = req.body;
    const category = await Category.create(categoryData);

    res.status(201).json({
      status: "success",
      message: "Category created successfully",
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

const updateCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const category = await Category.update(id, updateData);

    if (!category) {
      return res.status(404).json({
        status: "error",
        message: "Category not found",
      });
    }

    res.status(200).json({
      status: "success",
      message: "Category updated successfully",
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

const deleteCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { hardDelete = "false" } = req.query;

    let category;
    if (hardDelete === "true") {
      category = await Category.hardDelete(id);
    } else {
      category = await Category.delete(id);
    }

    if (!category) {
      return res.status(404).json({
        status: "error",
        message: "Category not found",
      });
    }

    res.status(200).json({
      status: "success",
      message: hardDelete === "true" ? "Category permanently deleted" : "Category deactivated",
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

const getCategoryProducts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, minPrice, maxPrice, inStock = "true", brandIds } = req.query;

    const offset = (page - 1) * limit;

    const options = {
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      inStock: inStock === "true",
      brandIds: brandIds ? brandIds.split(",").map((id) => parseInt(id, 10)) : undefined,
    };

    const products = await Category.getCategoryProducts(id, options);
    const total = await Category.count({ category_id: id });

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

const reorderCategories = async (req, res, next) => {
  try {
    const { categories } = req.body;

    if (!Array.isArray(categories) || categories.length === 0) {
      return res.status(400).json({
        status: "error",
        message: "Categories array is required",
      });
    }

    await Category.updateDisplayOrder(categories);

    res.status(200).json({
      status: "success",
      message: "Categories order updated successfully",
    });
  } catch (error) {
    next(error);
  }
};

export default {
  getAllCategories,
  getCategory,
  createCategory,
  updateCategory,
  deleteCategory,
  getCategoryProducts,
  reorderCategories,
};
