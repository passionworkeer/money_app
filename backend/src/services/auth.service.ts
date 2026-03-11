import bcrypt from 'bcryptjs';
import { prisma } from '../config/database';
import { createError } from '../middleware/errorHandler';
import { generateTokenPair } from '../utils/jwt';
import { RegisterInput, LoginInput } from '../models/auth.dto';

const SALT_ROUNDS = 12;

/**
 * Auth Service - handles user authentication
 */
export const authService = {
  /**
   * Register a new user
   */
  async register(input: RegisterInput) {
    const { email, password, nickname } = input;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw createError('Email already registered', 409);
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    // Create user with default settings
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        nickname: nickname || email.split('@')[0],
        settings: {
          create: {
            defaultCurrency: 'CNY',
            themeMode: 0,
            locale: 'zh',
          },
        },
      },
      include: {
        settings: true,
      },
    });

    // Generate tokens
    const tokens = generateTokenPair(user.id, user.email);

    // Create session
    await prisma.userSession.create({
      data: {
        userId: user.id,
        token: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        createdAt: user.createdAt,
      },
      ...tokens,
    };
  },

  /**
   * Login user
   */
  async login(input: LoginInput, ipAddress?: string, userAgent?: string) {
    const { email, password } = input;

    // Find user
    const user = await prisma.user.findUnique({
      where: { email },
      include: { settings: true },
    });

    if (!user) {
      throw createError('Invalid email or password', 401);
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.passwordHash);

    if (!isValidPassword) {
      throw createError('Invalid email or password', 401);
    }

    // Generate tokens
    const tokens = generateTokenPair(user.id, user.email);

    // Create session
    await prisma.userSession.create({
      data: {
        userId: user.id,
        token: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ipAddress,
        userAgent,
      },
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        createdAt: user.createdAt,
      },
      ...tokens,
    };
  },

  /**
   * Refresh access token
   */
  async refreshToken(refreshToken: string) {
    const { verifyRefreshToken } = await import('../utils/jwt');

    try {
      const payload = verifyRefreshToken(refreshToken);

      // Find session with refresh token
      const session = await prisma.userSession.findFirst({
        where: {
          refreshToken,
          userId: payload.userId,
        },
        include: { user: true },
      });

      if (!session || session.expiresAt < new Date()) {
        throw createError('Invalid or expired refresh token', 401);
      }

      // Generate new tokens
      const tokens = generateTokenPair(session.user.id, session.user.email);

      // Update session
      await prisma.userSession.update({
        where: { id: session.id },
        data: {
          token: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });

      return tokens;
    } catch (error) {
      throw createError('Invalid refresh token', 401);
    }
  },

  /**
   * Logout user
   */
  async logout(userId: string, token?: string) {
    // Delete all sessions for user (logout from all devices)
    // Or delete specific session if token provided
    if (token) {
      await prisma.userSession.deleteMany({
        where: {
          userId,
          token,
        },
      });
    } else {
      await prisma.userSession.deleteMany({
        where: { userId },
      });
    }

    return { message: 'Logged out successfully' };
  },

  /**
   * Get current user
   */
  async getCurrentUser(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        nickname: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw createError('User not found', 404);
    }

    return user;
  },
};
