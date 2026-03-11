import { Response } from 'express';

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> extends ApiResponse<T> {
  pagination?: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

/**
 * Send success response
 */
export function successResponse<T>(
  res: Response,
  data: T,
  message?: string,
  statusCode = 200
): Response<ApiResponse<T>> {
  return res.status(statusCode).json({
    success: true,
    data,
    message,
  });
}

/**
 * Send error response
 */
export function errorResponse(
  res: Response,
  message: string,
  statusCode = 400,
  error?: string
): Response<ApiResponse> {
  return res.status(statusCode).json({
    success: false,
    error: message,
    message: error,
  });
}

/**
 * Send paginated response
 */
export function paginatedResponse<T>(
  res: Response,
  data: T,
  total: number,
  page: number,
  limit: number
): Response<PaginatedResponse<T>> {
  const totalPages = Math.ceil(total / limit);

  return res.status(200).json({
    success: true,
    data,
    pagination: {
      total,
      page,
      limit,
      totalPages,
    },
  });
}

/**
 * Send created response (201)
 */
export function createdResponse<T>(
  res: Response,
  data: T,
  message = 'Created successfully'
): Response<ApiResponse<T>> {
  return res.status(201).json({
    success: true,
    data,
    message,
  });
}

/**
 * Send no content response (204)
 */
export function noContentResponse(res: Response): Response<void> {
  return res.status(204).send();
}
