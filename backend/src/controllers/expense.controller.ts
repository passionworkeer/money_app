import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { expenseService } from '../services/expense.service';
import { successResponse, paginatedResponse, errorResponse, createdResponse } from '../utils/response';
import { AuthRequest } from '../middleware/auth';

const createExpenseSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
    description: z.string().min(1).max(500),
    category: z.string().min(1).max(100),
    date: z.string(),
  }),
});

const updateExpenseSchema = z.object({
  body: z.object({
    amount: z.number().positive().optional(),
    description: z.string().min(1).max(500).optional(),
    category: z.string().min(1).max(100).optional(),
    date: z.string().optional(),
  }),
});

const expenseIdSchema = z.object({
  params: z.object({ id: z.string().uuid() }),
});

const listQuerySchema = z.object({
  query: z.object({
    page: z.string().optional(),
    limit: z.string().optional(),
    category: z.string().optional(),
    startDate: z.string().optional(),
    endDate: z.string().optional(),
    sortBy: z.enum(['date', 'amount', 'createdAt']).optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
  }),
});

const summaryQuerySchema = z.object({
  query: z.object({
    startDate: z.string().optional(),
    endDate: z.string().optional(),
    groupBy: z.enum(['category', 'month', 'day']).optional(),
  }),
});

/**
 * Expense Controller
 */
export const expenseController = {
  /**
   * POST /api/expenses - Create expense
   */
  async create(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = createExpenseSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const data = {
        ...validation.data.body,
        date: new Date(validation.data.body.date),
      };

      const expense = await expenseService.create(req.user!.userId, data);
      return createdResponse(res, expense, 'Expense created');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/expenses - List expenses
   */
  async findAll(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = listQuerySchema.safeParse({ query: req.query });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const query = validation.data.query;
      const result = await expenseService.findAll(req.user!.userId, {
        ...query,
        page: query.page ? parseInt(query.page, 10) : undefined,
        limit: query.limit ? parseInt(query.limit, 10) : undefined,
        startDate: query.startDate ? new Date(query.startDate) : undefined,
        endDate: query.endDate ? new Date(query.endDate) : undefined,
      });

      return paginatedResponse(
        res,
        result.expenses,
        result.pagination.total,
        result.pagination.page,
        result.pagination.limit
      );
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/expenses/:id - Get expense by ID
   */
  async findById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = expenseIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const expense = await expenseService.findById(req.user!.userId, validation.data.params.id);
      return successResponse(res, expense);
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/expenses/:id - Update expense
   */
  async update(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = updateExpenseSchema.safeParse({ body: req.body });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const idValidation = expenseIdSchema.safeParse({ params: req.params });
      if (!idValidation.success) {
        return errorResponse(res, 'Validation failed', 400, idValidation.error.errors[0]?.message);
      }

      const body = validation.data.body;
      const data: {
        amount?: number;
        description?: string;
        category?: string;
        date?: Date;
      } = {};

      if (body.amount !== undefined) data.amount = body.amount;
      if (body.description !== undefined) data.description = body.description;
      if (body.category !== undefined) data.category = body.category;
      if (body.date !== undefined) data.date = new Date(body.date);

      const expense = await expenseService.update(req.user!.userId, idValidation.data.params.id, data);
      return successResponse(res, expense, 'Expense updated');
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /api/expenses/:id - Delete expense
   */
  async delete(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = expenseIdSchema.safeParse({ params: req.params });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      await expenseService.delete(req.user!.userId, validation.data.params.id);
      return successResponse(res, null, 'Expense deleted');
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/expenses/summary - Get expense summary
   */
  async summary(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const validation = summaryQuerySchema.safeParse({ query: req.query });
      if (!validation.success) {
        return errorResponse(res, 'Validation failed', 400, validation.error.errors[0]?.message);
      }

      const query = validation.data.query;
      const summary = await expenseService.getSummary(req.user!.userId, {
        ...query,
        startDate: query.startDate ? new Date(query.startDate) : undefined,
        endDate: query.endDate ? new Date(query.endDate) : undefined,
      });

      return successResponse(res, summary);
    } catch (error) {
      next(error);
    }
  },
};
