import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { syncService } from '../services/sync.service';
import { successResponse, errorResponse } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const pushSyncSchema = z.object({
  body: z.object({
    expenses: z.array(z.object({
      id: z.string().uuid(),
      amount: z.number(),
      description: z.string(),
      category: z.string(),
      date: z.string(),
      createdAt: z.string().optional(),
      updatedAt: z.string().optional(),
      isSynced: z.boolean().optional(),
    })).optional(),
    budgets: z.array(z.object({
      id: z.string().uuid(),
      amount: z.number(),
      month: z.number(),
      year: z.number(),
      createdAt: z.string().optional(),
      updatedAt: z.string().optional(),
    })).optional(),
    settings: z.record(z.unknown()).optional(),
    automationRules: z.array(z.object({
      id: z.string().uuid(),
      name: z.string(),
      triggerType: z.string(),
      actionType: z.string(),
      config: z.record(z.unknown()),
      isEnabled: z.boolean(),
      createdAt: z.string().optional(),
      updatedAt: z.string().optional(),
    })).optional(),
  }).optional(),
});

const pullSyncQuerySchema = z.object({
  query: z.object({
    since: z.string().optional(),
  }),
});

/**
 * Sync Controller
 */
export const syncController = {
  /**
   * GET /api/sync/pull - Pull data from server
   */
  async pull(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = pullSyncQuerySchema.safeParse({ query: req.query });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const query = validation.data.query;
      const data = await syncService.pull(req.user!.userId, {
        since: query.since ? new Date(query.since) : undefined,
      });
      return successResponse(res, data);
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/sync/push - Push data to server
   */
  async push(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = pushSyncSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const data = validation.data.body || {};
      const processedData = {
        expenses: data.expenses?.map((e) => ({
          ...e,
          date: new Date(e.date),
          createdAt: e.createdAt ? new Date(e.createdAt) : undefined,
          updatedAt: e.updatedAt ? new Date(e.updatedAt) : undefined,
        })),
        budgets: data.budgets?.map((b) => ({
          ...b,
          createdAt: b.createdAt ? new Date(b.createdAt) : undefined,
          updatedAt: b.updatedAt ? new Date(b.updatedAt) : undefined,
        })),
        settings: data.settings,
        automationRules: data.automationRules?.map((r) => ({
          ...r,
          createdAt: r.createdAt ? new Date(r.createdAt) : undefined,
          updatedAt: r.updatedAt ? new Date(r.updatedAt) : undefined,
        })),
      };

      const result = await syncService.push(req.user!.userId, processedData);
      return successResponse(res, result, 'Data pushed successfully');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/sync/full - Full sync
   */
  async fullSync(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = pushSyncSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const localData = validation.data.body;
      const processedData = localData ? {
        expenses: localData.expenses?.map((e) => ({
          ...e,
          date: new Date(e.date),
          createdAt: e.createdAt ? new Date(e.createdAt) : undefined,
          updatedAt: e.updatedAt ? new Date(e.updatedAt) : undefined,
        })),
        budgets: localData.budgets?.map((b) => ({
          ...b,
          createdAt: b.createdAt ? new Date(b.createdAt) : undefined,
          updatedAt: b.updatedAt ? new Date(b.updatedAt) : undefined,
        })),
        settings: localData.settings,
        automationRules: localData.automationRules?.map((r) => ({
          ...r,
          createdAt: r.createdAt ? new Date(r.createdAt) : undefined,
          updatedAt: r.updatedAt ? new Date(r.updatedAt) : undefined,
        })),
      } : undefined;

      const result = await syncService.fullSync(req.user!.userId, processedData);
      return successResponse(res, result, 'Full sync completed');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/sync/status - Get sync status
   */
  async status(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const status = await syncService.getSyncStatus(req.user!.userId);
      return successResponse(res, status);
    } catch (error) {
      next(error);
    }
  },
};
