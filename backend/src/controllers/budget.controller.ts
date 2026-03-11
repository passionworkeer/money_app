import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { budgetService } from '../services/budget.service';
import { successResponse, errorResponse, createdResponse } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const createBudgetSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
    month: z.number().int().min(1).max(12),
    year: z.number().int().min(2000),
  }),
});

const updateBudgetSchema = z.object({
  body: z.object({
    amount: z.number().positive().optional(),
  }),
});

const budgetIdSchema = z.object({
  params: z.object({ id: z.string().uuid() }),
});

const budgetByMonthSchema = z.object({
  params: z.object({
    month: z.string(),
    year: z.string(),
  }),
});

/**
 * Budget Controller
 */
export const budgetController = {
  /**
   * POST /api/budgets - Create budget
   */
  async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = createBudgetSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const budget = await budgetService.create(req.user!.userId, validation.data.body);
      return createdResponse(res, budget, 'Budget created');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/budgets - List all budgets
   */
  async findAll(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budgets = await budgetService.findAll(req.user!.userId);
      return successResponse(res, budgets);
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/budgets/current - Get current month budget
   */
  async getCurrentMonth(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const budget = await budgetService.getCurrentMonthBudget(req.user!.userId);
      return successResponse(res, budget);
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/budgets/month/:month/:year - Get budget by month/year
   */
  async findByMonth(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = budgetByMonthSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const { month, year } = validation.data.params;
      const budget = await budgetService.findByMonth(
        req.user!.userId,
        parseInt(month, 10),
        parseInt(year, 10)
      );

      if (!budget) {
        return successResponse(res, null);
      }
      return successResponse(res, budget);
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/budgets/:id - Get budget by ID
   */
  async findById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = budgetIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const budget = await budgetService.findById(req.user!.userId, validation.data.params.id);
      return successResponse(res, budget);
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/budgets/:id - Update budget
   */
  async update(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = updateBudgetSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const idValidation = budgetIdSchema.safeParse({ params: req.params });
      if (!idValidation.success) {
        return errorResponse(res, 'Validation failed', 400, idValidation.error.errors[0]?.message);
      }

      const budget = await budgetService.update(req.user!.userId, idValidation.data.params.id, validation.data.body);
      return successResponse(res, budget, 'Budget updated');
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /api/budgets/:id - Delete budget
   */
  async delete(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = budgetIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      await budgetService.delete(req.user!.userId, validation.data.params.id);
      return successResponse(res, null, 'Budget deleted');
    } catch (error) {
      next(error);
    }
  },
};
