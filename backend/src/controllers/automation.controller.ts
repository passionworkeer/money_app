import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { automationService } from '../services/automation.service';
import { successResponse, errorResponse, createdResponse } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const createRuleSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(100),
    triggerType: z.enum(['scheduled', 'amountThreshold', 'category']),
    actionType: z.enum(['notification', 'categorize', 'autoRecord']),
    config: z.record(z.unknown()),
    isEnabled: z.boolean().optional(),
  }),
});

const updateRuleSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(100).optional(),
    triggerType: z.enum(['scheduled', 'amountThreshold', 'category']).optional(),
    actionType: z.enum(['notification', 'categorize', 'autoRecord']).optional(),
    config: z.record(z.unknown()).optional(),
    isEnabled: z.boolean().optional(),
  }),
});

const ruleIdSchema = z.object({
  params: z.object({ id: z.string().uuid() }),
});

/**
 * Automation Controller
 */
export const automationController = {
  /**
   * POST /api/automation - Create automation rule
   */
  async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = createRuleSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const rule = await automationService.create(req.user!.userId, validation.data.body);
      return createdResponse(res, rule, 'Automation rule created');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/automation - List all automation rules
   */
  async findAll(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const rules = await automationService.findAll(req.user!.userId);
      return successResponse(res, rules);
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/automation/:id - Get rule by ID
   */
  async findById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = ruleIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const rule = await automationService.findById(req.user!.userId, validation.data.params.id);
      return successResponse(res, rule);
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/automation/:id - Update rule
   */
  async update(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = updateRuleSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const idSchema = z.object({ id: z.string().uuid() });
      const idValidation = idSchema.safeParse(req.params);
      if (!idValidation.success) {
        return errorResponse(res, 'Validation failed', 400, idValidation.error.errors[0]?.message);
      }

      const rule = await automationService.update(req.user!.userId, idValidation.data.id, validation.data.body);
      return successResponse(res, rule, 'Automation rule updated');
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /api/automation/:id - Delete rule
   */
  async delete(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = ruleIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      await automationService.delete(req.user!.userId, validation.data.params.id);
      return successResponse(res, null, 'Automation rule deleted');
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/automation/:id/toggle - Toggle rule enabled/disabled
   */
  async toggle(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = ruleIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const rule = await automationService.toggle(req.user!.userId, validation.data.params.id);
      return successResponse(res, rule, 'Automation rule toggled');
    } catch (error) {
      next(error);
    }
  },
};
