import { z } from 'zod';

/**
 * Budget validation schemas
 */
export const createBudgetSchema = z.object({
  body: z.object({
    amount: z.number().positive('Amount must be positive'),
    month: z.number().int().min(1).max(12, 'Month must be between 1 and 12'),
    year: z.number().int().min(2000).max(2100, 'Year must be valid'),
  }),
});

export type CreateBudgetInput = z.infer<typeof createBudgetSchema>['body'];

export const updateBudgetSchema = z.object({
  body: z.object({
    amount: z.number().positive().optional(),
  }),
  params: z.object({
    id: z.string().uuid('Invalid budget ID'),
  }),
});

export type UpdateBudgetInput = z.infer<typeof updateBudgetSchema>;
export type UpdateBudgetParams = UpdateBudgetInput['params'];

export const budgetIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid budget ID'),
  }),
});

export type BudgetIdParams = z.infer<typeof budgetIdSchema>['params'];

export const budgetByMonthSchema = z.object({
  params: z.object({
    month: z.string().transform((val) => parseInt(val, 10)).pipe(z.number().int().min(1).max(12)),
    year: z.string().transform((val) => parseInt(val, 10)).pipe(z.number().int().min(2000)),
  }),
});

export type BudgetByMonthParams = z.infer<typeof budgetByMonthSchema>['params'];
