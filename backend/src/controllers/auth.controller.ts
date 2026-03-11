import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { authService } from '../services/auth.service';
import { successResponse, errorResponse } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const registerSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email format'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    nickname: z.string().min(2).max(50).optional(),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email format'),
    password: z.string().min(1, 'Password is required'),
  }),
});

const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }),
});

/**
 * Auth Controller
 */
export const authController = {
  /**
   * POST /api/auth/register - Register a new user
   */
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const validation = registerSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(
          res,
          'Validation failed',
          400,
          validation.error.errors[0]?.message
        );
      }

      const result = await authService.register(validation.data.body);
      return successResponse(res, result, 'Registration successful', 201);
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/auth/login - Login user
   */
  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const validation = loginSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(
          res,
          'Validation failed',
          400,
          validation.error.errors[0]?.message
        );
      }

      const ipAddress = req.ip || req.socket.remoteAddress;
      const userAgent = req.headers['user-agent'];

      const result = await authService.login(
        validation.data.body,
        ipAddress,
        userAgent
      );
      return successResponse(res, result, 'Login successful');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/auth/refresh - Refresh access token
   */
  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const validation = refreshTokenSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(
          res,
          'Validation failed',
          400,
          validation.error.errors[0]?.message
        );
      }

      const tokens = await authService.refreshToken(
        validation.data.body.refreshToken
      );
      return successResponse(res, tokens, 'Token refreshed');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/auth/logout - Logout user
   */
  async logout(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const token = req.headers.authorization?.split(' ')[1];
      const result = await authService.logout(req.user!.userId, token);
      return successResponse(res, result, 'Logged out successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/auth/me - Get current user
   */
  async me(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const user = await authService.getCurrentUser(req.user!.userId);
      return successResponse(res, user);
    } catch (error) {
      next(error);
    }
  },
};
