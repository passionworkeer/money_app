import { z } from 'zod';

/**
 * Expense validation schemas
 */
export const createExpenseSchema = z.object({
  body: z.object({
    amount: z.number().positive('Amount must be positive'),
    description: z
      .string()
      .min(1, 'Description is required')
      .max(500, 'Description must be less than 500 characters'),
    category: z
      .string()
      .min(1, 'Category is required')
      .max(100, 'Category must be less than 100 characters'),
    date: z.string().transform((val) => new Date(val)),
  }),
});

export type CreateExpenseInput = z.infer<typeof createExpenseSchema>['body'];

export const updateExpenseSchema = z.object({
  body: z.object({
    amount: z.number().positive().optional(),
    description: z.string().min(1).max(500).optional(),
    category: z.string().min(1).max(100).optional(),
    date: z.string().transform((val) => new Date(val)).optional(),
  }),
  params: z.object({
    id: z.string().uuid('Invalid expense ID'),
  }),
});

export type UpdateExpenseInput = z.infer<typeof updateExpenseSchema>;
export type UpdateExpenseParams = UpdateExpenseInput['params'];

export const expenseIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid expense ID'),
  }),
});

export type ExpenseIdParams = z.infer<typeof expenseIdSchema>['params'];

export const expenseListQuerySchema = z.object({
  query: z.object({
    page: z.string().transform((val) => parseInt(val, 10)).pipe(z.number().min(1)).optional(),
    limit: z.string().transform((val) => parseInt(val, 10)).pipe(z.number().min(1).max(100)).optional(),
    category: z.string().optional(),
    startDate: z.string().transform((val) => new Date(val)).optional(),
    endDate: z.string().transform((val) => new Date(val)).optional(),
    sortBy: z.enum(['date', 'amount', 'createdAt']).optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
  }),
});

export type ExpenseListQuery = z.infer<typeof expenseListQuerySchema>['query'];

export const expenseSummaryQuerySchema = z.object({
  query: z.object({
    startDate: z.string().transform((val) => new Date(val)).optional(),
    endDate: z.string().transform((val) => new Date(val)).optional(),
    groupBy: z.enum(['category', 'month', 'day']).optional(),
  }),
});

export type ExpenseSummaryQuery = z.infer<typeof expenseSummaryQuerySchema>['query'];
