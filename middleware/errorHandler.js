// middleware/errorHandler.js
const errorHandler = (err, req, res, next) => {
  console.error("Error:", err);

  // Default error
  let statusCode = err.statusCode || 500;
  let message = err.message || "Internal Server Error";
  let errors = null;

  // PostgreSQL errors
  if (err.code) {
    switch (err.code) {
      case "23505": // Unique violation
        statusCode = 400;
        message = "Duplicate entry. This record already exists.";
        break;
      case "23503": // Foreign key violation
        statusCode = 400;
        message = "Cannot delete or update due to foreign key constraints.";
        break;
      case "23502": // Not null violation
        statusCode = 400;
        message = "Required field is missing.";
        break;
      case "22P02": // Invalid input syntax
        statusCode = 400;
        message = "Invalid input format.";
        break;
    }
  }

  // JWT errors
  if (err.name === "JsonWebTokenError") {
    statusCode = 401;
    message = "Invalid token";
  }

  if (err.name === "TokenExpiredError") {
    statusCode = 401;
    message = "Token expired";
  }

  // Validation errors (generic)
  if (err.name === "ValidationError") {
    statusCode = 400;
    message = "Validation failed";
    errors = Object.values(err.errors).map((e) => e.message);
  }

  // Response
  res.status(statusCode).json({
    status: "error",
    message,
    ...(errors && { errors }),
    ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
  });
};

export default errorHandler;
