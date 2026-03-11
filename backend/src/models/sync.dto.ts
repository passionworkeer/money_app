import { z } from 'zod';

/**
 * Sync data validation schemas
 */
export const syncDataSchema = z.object({
  expenses: z.array(z.object({
    id: z.string().uuid(),
    amount: z.number(),
    description: z.string(),
    category: z.string(),
    date: z.string().transform((val) => new Date(val)),
    createdAt: z.string().transform((val) => new Date(val)).optional(),
    updatedAt: z.string().transform((val) => new Date(val)).optional(),
    isSynced: z.boolean().optional(),
  })).optional(),
  budgets: z.array(z.object({
    id: z.string().uuid(),
    amount: z.number(),
    month: z.number().int().min(1).max(12),
    year: z.number().int().min(2000),
    createdAt: z.string().transform((val) => new Date(val)).optional(),
    updatedAt: z.string().transform((val) => new Date(val)).optional(),
  })).optional(),
  settings: z.record(z.unknown()).optional(),
});

export type SyncDataInput = z.infer<typeof syncDataSchema>;

export const pushSyncSchema = z.object({
  body: syncDataSchema,
});

export type PushSyncInput = z.infer<typeof pushSyncSchema>['body'];

export const pullSyncQuerySchema = z.object({
  query: z.object({
    since: z.string().transform((val) => new Date(val)).optional(),
  }),
});

export type PullSyncQuery = z.infer<typeof pullSyncQuerySchema>['query'];

export const fullSyncSchema = z.object({
  body: syncDataSchema.optional(),
});

export type FullSyncInput = z.infer<typeof fullSyncSchema>['body'];
