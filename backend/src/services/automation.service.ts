import { prisma } from '../config/database';
import { createError } from '../middleware/errorHandler';
import type { Prisma } from '@prisma/client';
import {
  AutomationConfigInput,
} from '../models/automation.dto';

/**
 * Automation Rule Service
 */
export const automationService = {
  /**
   * Create a new automation rule
   */
  async create(userId: string, input: {
    name: string;
    triggerType: string;
    actionType: string;
    config: Record<string, unknown>;
    isEnabled?: boolean;
  }) {
    const configJson = input.config as unknown as Prisma.InputJsonValue;

    const rule = await prisma.automationRule.create({
      data: {
        userId,
        name: input.name,
        triggerType: input.triggerType,
        actionType: input.actionType,
        config: configJson,
        isEnabled: input.isEnabled ?? true,
      },
    });

    return {
      ...rule,
      config: rule.config as unknown as AutomationConfigInput,
    };
  },

  /**
   * Get all automation rules for user
   */
  async findAll(userId: string) {
    const rules = await prisma.automationRule.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return rules.map((rule) => ({
      ...rule,
      config: rule.config as unknown as AutomationConfigInput,
    }));
  },

  /**
   * Get automation rule by ID
   */
  async findById(userId: string, ruleId: string) {
    const rule = await prisma.automationRule.findFirst({
      where: {
        id: ruleId,
        userId,
      },
    });

    if (!rule) {
      throw createError('Automation rule not found', 404);
    }

    return {
      ...rule,
      config: rule.config as unknown as AutomationConfigInput,
    };
  },

  /**
   * Update automation rule
   */
  async update(userId: string, ruleId: string, input: {
    name?: string;
    triggerType?: string;
    actionType?: string;
    config?: Record<string, unknown>;
    isEnabled?: boolean;
  }) {
    // Check if rule exists
    await this.findById(userId, ruleId);

    const configJson = input.config as unknown as Prisma.InputJsonValue | undefined;

    const updateData: Prisma.AutomationRuleUpdateInput = {};

    if (input.name !== undefined) updateData.name = input.name;
    if (input.triggerType !== undefined) updateData.triggerType = input.triggerType;
    if (input.actionType !== undefined) updateData.actionType = input.actionType;
    if (input.config !== undefined) updateData.config = configJson;
    if (input.isEnabled !== undefined) updateData.isEnabled = input.isEnabled;

    const rule = await prisma.automationRule.update({
      where: { id: ruleId },
      data: updateData,
    });

    return {
      ...rule,
      config: rule.config as unknown as AutomationConfigInput,
    };
  },

  /**
   * Delete automation rule
   */
  async delete(userId: string, ruleId: string) {
    // Check if rule exists
    await this.findById(userId, ruleId);

    await prisma.automationRule.delete({
      where: { id: ruleId },
    });

    return { message: 'Automation rule deleted successfully' };
  },

  /**
   * Toggle rule enabled/disabled
   */
  async toggle(userId: string, ruleId: string) {
    const rule = await this.findById(userId, ruleId);

    const updated = await prisma.automationRule.update({
      where: { id: ruleId },
      data: { isEnabled: !rule.isEnabled },
    });

    return {
      ...updated,
      config: updated.config as unknown as AutomationConfigInput,
    };
  },

  /**
   * Get all enabled rules (for execution)
   */
  async getEnabledRules(userId: string) {
    const rules = await prisma.automationRule.findMany({
      where: {
        userId,
        isEnabled: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return rules.map((rule) => ({
      ...rule,
      config: rule.config as unknown as AutomationConfigInput,
    }));
  },

  /**
   * Update last triggered timestamp
   */
  async markTriggered(userId: string, ruleId: string) {
    await prisma.automationRule.update({
      where: { id: ruleId },
      data: { lastTriggered: new Date() },
    });
  },

  /**
   * Get all rules for sync
   */
  async findAllForSync(userId: string, since?: Date) {
    const where: Record<string, unknown> = { userId };

    if (since) {
      where.updatedAt = { gte: since };
    }

    const rules = await prisma.automationRule.findMany({
      where,
      orderBy: { updatedAt: 'asc' },
    });

    return rules.map((rule) => ({
      ...rule,
      config: rule.config as unknown as AutomationConfigInput,
    }));
  },

  /**
   * Bulk upsert rules (for sync)
   */
  async bulkUpsert(userId: string, rules: Array<{
    id: string;
    name: string;
    triggerType: string;
    actionType: string;
    config: Record<string, unknown>;
    isEnabled: boolean;
    createdAt?: Date;
    updatedAt?: Date;
  }>) {
    const results = [];

    for (const rule of rules) {
      const configJson = rule.config as unknown as Prisma.InputJsonValue;
      const result = await prisma.automationRule.upsert({
        where: { id: rule.id },
        create: {
          id: rule.id,
          userId,
          name: rule.name,
          triggerType: rule.triggerType,
          actionType: rule.actionType,
          config: configJson,
          isEnabled: rule.isEnabled,
          createdAt: rule.createdAt || new Date(),
          updatedAt: rule.updatedAt || new Date(),
        },
        update: {
          name: rule.name,
          triggerType: rule.triggerType,
          actionType: rule.actionType,
          config: configJson,
          isEnabled: rule.isEnabled,
          updatedAt: rule.updatedAt || new Date(),
        },
      });
      results.push(result);
    }

    return results;
  },
};
