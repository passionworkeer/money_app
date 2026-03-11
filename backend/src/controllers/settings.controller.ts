import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { settingsService } from '../services/settings.service';
import { successResponse, errorResponse } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const updateSettingsSchema = z.object({
  body: z.object({
    preferredModel: z.string().optional(),
    defaultCurrency: z.string().length(3).optional(),
    themeMode: z.number().int().min(0).max(2).optional(),
    locale: z.string().length(2).optional(),
  }),
});

const updateAiKeysSchema = z.object({
  body: z.object({
    openaiApiKey: z.string().optional(),
    claudeApiKey: z.string().optional(),
    ernieApiKey: z.string().optional(),
    qwenApiKey: z.string().optional(),
    sparkApiKey: z.string().optional(),
    hunyuanApiKey: z.string().optional(),
    zhipuApiKey: z.string().optional(),
  }),
});

/**
 * Settings Controller
 */
export const settingsController = {
  /**
   * GET /api/settings - Get user settings
   */
  async getSettings(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const settings = await settingsService.getSettings(req.user!.userId);
      return successResponse(res, settings);
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/settings - Update user settings
   */
  async updateSettings(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = updateSettingsSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const settings = await settingsService.updateSettings(
        req.user!.userId,
        validation.data.body
      );
      return successResponse(res, settings, 'Settings updated');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/settings/ai-keys - Get AI API keys (decrypted)
   */
  async getAiKeys(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const keys = await settingsService.getAiKeys(req.user!.userId);
      return successResponse(res, keys);
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/settings/ai-keys - Update AI API keys
   */
  async updateAiKeys(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = updateAiKeysSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const result = await settingsService.updateAiKeys(
        req.user!.userId,
        validation.data.body
      );
      return successResponse(res, result, 'AI keys updated');
    } catch (error) {
      next(error);
    }
  },
};
