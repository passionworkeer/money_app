import { z } from 'zod';

/**
 * User registration validation schema
 */
export const registerSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email format'),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .max(100, 'Password must be less than 100 characters'),
    nickname: z
      .string()
      .min(2, 'Nickname must be at least 2 characters')
      .max(50, 'Nickname must be less than 50 characters')
      .optional(),
  }),
});

export type RegisterInput = z.infer<typeof registerSchema>['body'];

/**
 * User login validation schema
 */
export const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email format'),
    password: z.string().min(1, 'Password is required'),
  }),
});

export type LoginInput = z.infer<typeof loginSchema>['body'];

/**
 * Refresh token validation schema
 */
export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }),
});

export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>['body'];

/**
 * Change password validation schema
 */
export const changePasswordSchema = z.object({
  body: z.object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: z
      .string()
      .min(8, 'New password must be at least 8 characters')
      .max(100, 'New password must be less than 100 characters'),
  }),
});

export type ChangePasswordInput = z.infer<typeof changePasswordSchema>['body'];
