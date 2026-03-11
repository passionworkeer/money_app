import { z } from 'zod';

/**
 * User settings validation schemas
 */
export const updateSettingsSchema = z.object({
  body: z.object({
    preferredModel: z.string().optional(),
    defaultCurrency: z.string().length(3).optional(),
    themeMode: z.number().int().min(0).max(2).optional(),
    locale: z.string().length(2).optional(),
  }),
});

export type UpdateSettingsInput = z.infer<typeof updateSettingsSchema>['body'];

export const updateAiKeysSchema = z.object({
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

export type UpdateAiKeysInput = z.infer<typeof updateAiKeysSchema>['body'];
