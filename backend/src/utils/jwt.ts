import jwt, { SignOptions } from 'jsonwebtoken';
import { config } from '../config';

export interface TokenPayload {
  userId: string;
  email: string;
  type: 'access' | 'refresh';
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

/**
 * Generate access token
 */
export function generateAccessToken(userId: string, email: string): string {
  const payload: TokenPayload = { userId, email, type: 'access' };
  const options: SignOptions = { expiresIn: config.jwt.expiresIn as string } as SignOptions;
  return jwt.sign(payload, config.jwt.secret, options);
}

/**
 * Generate refresh token
 */
export function generateRefreshToken(userId: string, email: string): string {
  const payload: TokenPayload = { userId, email, type: 'refresh' };
  const options: SignOptions = { expiresIn: config.jwt.refreshExpiresIn as string } as SignOptions;
  return jwt.sign(payload, config.jwt.refreshSecret, options);
}

/**
 * Generate token pair
 */
export function generateTokenPair(userId: string, email: string): TokenPair {
  return {
    accessToken: generateAccessToken(userId, email),
    refreshToken: generateRefreshToken(userId, email),
  };
}

/**
 * Verify access token
 */
export function verifyAccessToken(token: string): TokenPayload {
  return jwt.verify(token, config.jwt.secret) as TokenPayload;
}

/**
 * Verify refresh token
 */
export function verifyRefreshToken(token: string): TokenPayload {
  return jwt.verify(token, config.jwt.refreshSecret) as TokenPayload;
}

/**
 * Decode token without verification (for debugging)
 */
export function decodeToken(token: string): TokenPayload | null {
  const decoded = jwt.decode(token);
  return decoded as TokenPayload | null;
}
