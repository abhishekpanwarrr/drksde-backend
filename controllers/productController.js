// controllers/productController.js
import { validationResult } from "express-validator";

import Product from "../models/Product.js";

const getAllProducts = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      categoryId,
      brandId,
      minPrice,
      maxPrice,
      inStock = "true",
      isFeatured,
      search,
      sortBy = "created_at",
      sortOrder = "DESC",
    } = req.query;

    const offset = (page - 1) * limit;

    const options = {
      categoryId: categoryId ? parseInt(categoryId, 10) : undefined,
      brandId: brandId ? parseInt(brandId, 10) : undefined,
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      inStock: inStock === "true",
      isFeatured: isFeatured !== undefined ? isFeatured === "true" : undefined,
      search,
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
      sortBy,
      sortOrder,
    };

    const products = await Product.findAllWithDetails(options);
    const total = await Product.count({ is_active: true });

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

const getProduct = async (req, res, next) => {
  try {
    const { id } = req.params;

    let product;
    if (!isNaN(id)) {
      product = await Product.findByIdWithDetails(parseInt(id, 10));
    } else {
      product = await Product.findBySlug(id);
    }

    if (!product) {
      return res.status(404).json({
        status: "error",
        message: "Product not found",
      });
    }

    res.status(200).json({
      status: "success",
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

const createProduct = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        status: "error",
        errors: errors.array(),
      });
    }

    const productData = req.body;
    const product = await Product.create(productData);

    res.status(201).json({
      status: "success",
      message: "Product created successfully",
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

const updateProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const product = await Product.update(id, updateData);

    if (!product) {
      return res.status(404).json({
        status: "error",
        message: "Product not found",
      });
    }

    res.status(200).json({
      status: "success",
      message: "Product updated successfully",
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

const deleteProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { hardDelete = "false" } = req.query;

    let product;
    if (hardDelete === "true") {
      product = await Product.hardDelete(id);
    } else {
      product = await Product.delete(id);
    }

    if (!product) {
      return res.status(404).json({
        status: "error",
        message: "Product not found",
      });
    }

    res.status(200).json({
      status: "success",
      message: hardDelete === "true" ? "Product permanently deleted" : "Product deactivated",
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

const getRelatedProducts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { limit = 8 } = req.query;

    const relatedProducts = await Product.getRelatedProducts(id, parseInt(limit, 10));

    res.status(200).json({
      status: "success",
      count: relatedProducts.length,
      data: relatedProducts,
    });
  } catch (error) {
    next(error);
  }
};

const searchProducts = async (req, res, next) => {
  try {
    const { q } = req.query;
    const { page = 1, limit = 20 } = req.query;

    if (!q || q.trim() === "") {
      return res.status(400).json({
        status: "error",
        message: "Search query is required",
      });
    }

    const offset = (page - 1) * limit;

    const options = {
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
    };

    const products = await Product.searchProducts(q, options);
    const total = products.length; // approximate

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

const updateStock = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quantity, variantId } = req.body;

    if (typeof quantity !== "number") {
      return res.status(400).json({
        status: "error",
        message: "Quantity is required and must be a number",
      });
    }

    await Product.updateStock(id, quantity, variantId);

    res.status(200).json({
      status: "success",
      message: "Stock updated successfully",
    });
  } catch (error) {
    next(error);
  }
};

const getFeaturedProducts = async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;

    const products = await Product.findAllWithDetails({
      isFeatured: true,
      limit: parseInt(limit, 10),
      inStock: true,
    });

    res.status(200).json({
      status: "success",
      count: products.length,
      data: products,
    });
  } catch (error) {
    next(error);
  }
};

export default {
  getAllProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  getRelatedProducts,
  searchProducts,
  updateStock,
  getFeaturedProducts,
};
