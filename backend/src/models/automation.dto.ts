import { z } from 'zod';

/**
 * Automation config validation schemas
 */
const automationConfigSchema = z.object({
  scheduleHour: z.number().int().min(0).max(23).optional(),
  scheduleMinute: z.number().int().min(0).max(59).optional(),
  scheduleType: z.enum(['daily', 'weekly']).optional(),
  weekDay: z.number().int().min(1).max(7).optional(),
  thresholdAmount: z.number().positive().optional(),
  isPercentage: z.boolean().optional(),
  targetCategory: z.string().optional(),
  keywords: z.array(z.string()).optional(),
  notificationTitle: z.string().optional(),
  notificationBody: z.string().optional(),
});

export type AutomationConfigInput = z.infer<typeof automationConfigSchema>;

/**
 * Automation rule validation schemas
 */
export const createAutomationRuleSchema = z.object({
  body: z.object({
    name: z
      .string()
      .min(1, 'Name is required')
      .max(100, 'Name must be less than 100 characters'),
    triggerType: z.enum(['scheduled', 'amountThreshold', 'category']),
    actionType: z.enum(['notification', 'categorize', 'autoRecord']),
    config: automationConfigSchema,
    isEnabled: z.boolean().optional().default(true),
  }),
});

export type CreateAutomationRuleInput = z.infer<typeof createAutomationRuleSchema>['body'];

export const updateAutomationRuleSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(100).optional(),
    triggerType: z.enum(['scheduled', 'amountThreshold', 'category']).optional(),
    actionType: z.enum(['notification', 'categorize', 'autoRecord']).optional(),
    config: automationConfigSchema.optional(),
    isEnabled: z.boolean().optional(),
  }),
  params: z.object({
    id: z.string().uuid('Invalid rule ID'),
  }),
});

export type UpdateAutomationRuleInput = z.infer<typeof updateAutomationRuleSchema>;
export type UpdateAutomationRuleParams = UpdateAutomationRuleInput['params'];

export const automationRuleIdSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid rule ID'),
  }),
});

export type AutomationRuleIdParams = z.infer<typeof automationRuleIdSchema>['params'];
