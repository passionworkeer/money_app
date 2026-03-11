import { prisma } from '../config/database';
import { createError } from '../middleware/errorHandler';
import { encrypt, decrypt } from '../utils/encryption';
import { UpdateSettingsInput, UpdateAiKeysInput } from '../models/settings.dto';

/**
 * Settings Service - handles user settings operations
 */
export const settingsService = {
  /**
   * Get user settings
   */
  async getSettings(userId: string) {
    let settings = await prisma.userSettings.findUnique({
      where: { userId },
    });

    // Create default settings if not exists
    if (!settings) {
      settings = await prisma.userSettings.create({
        data: { userId },
      });
    }

    // Decrypt API keys
    return {
      id: settings.id,
      preferredModel: settings.preferredModel,
      defaultCurrency: settings.defaultCurrency,
      themeMode: settings.themeMode,
      locale: settings.locale,
      // Don't return actual API keys, just presence indicators
      hasOpenAiKey: !!settings.openaiApiKey,
      hasClaudeKey: !!settings.claudeApiKey,
      hasErnieKey: !!settings.ernieApiKey,
      hasQwenKey: !!settings.qwenApiKey,
      hasSparkKey: !!settings.sparkApiKey,
      hasHunyuanKey: !!settings.hunyuanApiKey,
      hasZhipuKey: !!settings.zhipuApiKey,
    };
  },

  /**
   * Update user settings
   */
  async updateSettings(userId: string, input: UpdateSettingsInput) {
    const settings = await prisma.userSettings.upsert({
      where: { userId },
      create: { userId, ...input },
      update: input,
    });

    return {
      preferredModel: settings.preferredModel,
      defaultCurrency: settings.defaultCurrency,
      themeMode: settings.themeMode,
      locale: settings.locale,
    };
  },

  /**
   * Get AI API keys (decrypted)
   */
  async getAiKeys(userId: string) {
    const settings = await prisma.userSettings.findUnique({
      where: { userId },
    });

    if (!settings) {
      return {};
    }

    // Decrypt and return keys
    return {
      openaiApiKey: settings.openaiApiKey ? decrypt(settings.openaiApiKey) : null,
      claudeApiKey: settings.claudeApiKey ? decrypt(settings.claudeApiKey) : null,
      ernieApiKey: settings.ernieApiKey ? decrypt(settings.ernieApiKey) : null,
      qwenApiKey: settings.qwenApiKey ? decrypt(settings.qwenApiKey) : null,
      sparkApiKey: settings.sparkApiKey ? decrypt(settings.sparkApiKey) : null,
      hunyuanApiKey: settings.hunyuanApiKey ? decrypt(settings.hunyuanApiKey) : null,
      zhipuApiKey: settings.zhipuApiKey ? decrypt(settings.zhipuApiKey) : null,
    };
  },

  /**
   * Update AI API keys (encrypt before storing)
   */
  async updateAiKeys(userId: string, input: UpdateAiKeysInput) {
    const updateData: Record<string, string | undefined> = {};

    // Encrypt each key if provided
    if (input.openaiApiKey !== undefined) {
      updateData.openaiApiKey = input.openaiApiKey ? encrypt(input.openaiApiKey) : undefined;
    }
    if (input.claudeApiKey !== undefined) {
      updateData.claudeApiKey = input.claudeApiKey ? encrypt(input.claudeApiKey) : undefined;
    }
    if (input.ernieApiKey !== undefined) {
      updateData.ernieApiKey = input.ernieApiKey ? encrypt(input.ernieApiKey) : undefined;
    }
    if (input.qwenApiKey !== undefined) {
      updateData.qwenApiKey = input.qwenApiKey ? encrypt(input.qwenApiKey) : undefined;
    }
    if (input.sparkApiKey !== undefined) {
      updateData.sparkApiKey = input.sparkApiKey ? encrypt(input.sparkApiKey) : undefined;
    }
    if (input.hunyuanApiKey !== undefined) {
      updateData.hunyuanApiKey = input.hunyuanApiKey ? encrypt(input.hunyuanApiKey) : undefined;
    }
    if (input.zhipuApiKey !== undefined) {
      updateData.zhipuApiKey = input.zhipuApiKey ? encrypt(input.zhipuApiKey) : undefined;
    }

    const settings = await prisma.userSettings.upsert({
      where: { userId },
      create: { userId, ...updateData },
      update: updateData,
    });

    // Return presence indicators
    return {
      hasOpenAiKey: !!settings.openaiApiKey,
      hasClaudeKey: !!settings.claudeApiKey,
      hasErnieKey: !!settings.ernieApiKey,
      hasQwenKey: !!settings.qwenApiKey,
      hasSparkKey: !!settings.sparkApiKey,
      hasHunyuanKey: !!settings.hunyuanApiKey,
      hasZhipuKey: !!settings.zhipuApiKey,
    };
  },

  /**
   * Get settings for sync
   */
  async getForSync(userId: string) {
    const settings = await prisma.userSettings.findUnique({
      where: { userId },
    });

    if (!settings) {
      return null;
    }

    // Return non-sensitive data for sync
    return {
      id: settings.id,
      preferredModel: settings.preferredModel,
      defaultCurrency: settings.defaultCurrency,
      themeMode: settings.themeMode,
      locale: settings.locale,
      // Don't sync API keys
    };
  },

  /**
   * Upsert settings from sync
   */
  async upsertFromSync(userId: string, data: {
    preferredModel?: string | null;
    defaultCurrency?: string;
    themeMode?: number;
    locale?: string;
  }) {
    const settings = await prisma.userSettings.upsert({
      where: { userId },
      create: {
        userId,
        preferredModel: data.preferredModel || null,
        defaultCurrency: data.defaultCurrency || 'CNY',
        themeMode: data.themeMode ?? 0,
        locale: data.locale || 'zh',
      },
      update: {
        ...(data.preferredModel !== undefined && { preferredModel: data.preferredModel }),
        ...(data.defaultCurrency !== undefined && { defaultCurrency: data.defaultCurrency }),
        ...(data.themeMode !== undefined && { themeMode: data.themeMode }),
        ...(data.locale !== undefined && { locale: data.locale }),
      },
    });

    return settings;
  },
};
