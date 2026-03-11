import { prisma } from '../config/database';
import { expenseService } from './expense.service';
import { budgetService } from './budget.service';
import { settingsService } from './settings.service';
import { automationService } from './automation.service';
import type { Prisma } from '@prisma/client';

/**
 * Sync Service - handles data synchronization
 */
export const syncService = {
  /**
   * Pull data from server (since timestamp)
   */
  async pull(userId: string, options: { since?: Date }) {
    const since = options.since;

    // Fetch all data since timestamp
    const [expenses, budgets, settings, automationRules] = await Promise.all([
      expenseService.findAllForSync(userId, since),
      budgetService.findAllForSync(userId, since),
      settingsService.getForSync(userId),
      automationService.findAllForSync(userId, since),
    ]);

    // Log sync action
    await prisma.syncLog.create({
      data: {
        userId,
        action: 'pull',
        status: 'success',
        recordCount: expenses.length + budgets.length + automationRules.length,
      },
    });

    return {
      expenses,
      budgets,
      settings,
      automationRules,
      timestamp: new Date().toISOString(),
    };
  },

  /**
   * Push data to server
   */
  async push(userId: string, data: {
    expenses?: Array<{
      id: string;
      amount: number;
      description: string;
      category: string;
      date: Date;
      createdAt?: Date;
      updatedAt?: Date;
      isSynced?: boolean;
    }>;
    budgets?: Array<{
      id: string;
      amount: number;
      month: number;
      year: number;
      createdAt?: Date;
      updatedAt?: Date;
    }>;
    settings?: Record<string, unknown>;
    automationRules?: Array<{
      id: string;
      name: string;
      triggerType: string;
      actionType: string;
      config: Record<string, unknown>;
      isEnabled: boolean;
      createdAt?: Date;
      updatedAt?: Date;
    }>;
  }) {
    const results: {
      expenses: number;
      budgets: number;
      automationRules: number;
    } = {
      expenses: 0,
      budgets: 0,
      automationRules: 0,
    };

    // Process expenses
    if (data.expenses && data.expenses.length > 0) {
      const expenseResults = await expenseService.bulkUpsert(
        userId,
        data.expenses.map((e) => ({
          id: e.id,
          amount: e.amount,
          description: e.description,
          category: e.category,
          date: e.date,
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
          isSynced: true,
        }))
      );
      results.expenses = expenseResults.length;
    }

    // Process budgets
    if (data.budgets && data.budgets.length > 0) {
      const budgetResults = await budgetService.bulkUpsert(
        userId,
        data.budgets.map((b) => ({
          id: b.id,
          amount: b.amount,
          month: b.month,
          year: b.year,
          createdAt: b.createdAt,
          updatedAt: b.updatedAt,
        }))
      );
      results.budgets = budgetResults.length;
    }

    // Process settings
    if (data.settings) {
      await settingsService.upsertFromSync(userId, data.settings as {
        preferredModel?: string | null;
        defaultCurrency?: string;
        themeMode?: number;
        locale?: string;
      });
    }

    // Process automation rules
    if (data.automationRules && data.automationRules.length > 0) {
      const ruleResults = await automationService.bulkUpsert(
        userId,
        data.automationRules.map((r) => ({
          id: r.id,
          name: r.name,
          triggerType: r.triggerType,
          actionType: r.actionType,
          config: r.config,
          isEnabled: r.isEnabled,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        }))
      );
      results.automationRules = ruleResults.length;
    }

    // Log sync action
    await prisma.syncLog.create({
      data: {
        userId,
        action: 'push',
        status: 'success',
        recordCount: results.expenses + results.budgets + results.automationRules,
        details: results as unknown as Prisma.InputJsonValue,
      },
    });

    return {
      ...results,
      timestamp: new Date().toISOString(),
    };
  },

  /**
   * Full sync - pull all data, then optionally push data
   */
  async fullSync(userId: string, localData?: {
    expenses?: Array<{
      id: string;
      amount: number;
      description: string;
      category: string;
      date: Date;
      createdAt?: Date;
      updatedAt?: Date;
      isSynced?: boolean;
    }>;
    budgets?: Array<{
      id: string;
      amount: number;
      month: number;
      year: number;
      createdAt?: Date;
      updatedAt?: Date;
    }>;
    settings?: Record<string, unknown>;
    automationRules?: Array<{
      id: string;
      name: string;
      triggerType: string;
      actionType: string;
      config: Record<string, unknown>;
      isEnabled: boolean;
      createdAt?: Date;
      updatedAt?: Date;
    }>;
  }) {
    // First, pull all remote data
    const remoteData = await this.pull(userId, {});

    // Then, push local data if provided
    if (localData) {
      await this.push(userId, localData);
    }

    // Log sync action
    await prisma.syncLog.create({
      data: {
        userId,
        action: 'full',
        status: 'success',
        recordCount: (remoteData.expenses?.length || 0) + (remoteData.budgets?.length || 0),
      },
    });

    return {
      ...remoteData,
      syncedAt: new Date().toISOString(),
    };
  },

  /**
   * Get sync status
   */
  async getSyncStatus(userId: string) {
    const [expenseCount, budgetCount, ruleCount, lastSync] = await Promise.all([
      prisma.expense.count({ where: { userId, isSynced: false } }),
      prisma.budget.count({ where: { userId } }),
      prisma.automationRule.count({ where: { userId } }),
      prisma.syncLog.findFirst({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      pendingExpenses: expenseCount,
      totalBudgets: budgetCount,
      totalRules: ruleCount,
      lastSync: lastSync?.createdAt || null,
      lastSyncAction: lastSync?.action || null,
    };
  },
};
