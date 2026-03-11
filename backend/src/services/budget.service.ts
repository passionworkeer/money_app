import { prisma } from '../config/database';
import { createError } from '../middleware/errorHandler';

/**
 * Budget Service - handles budget CRUD operations
 */
export const budgetService = {
  /**
   * Create a new budget
   */
  async create(userId: string, input: {
    amount: number;
    month: number;
    year: number;
  }) {
    // Check if budget for this month/year already exists
    const existing = await prisma.budget.findUnique({
      where: {
        userId_month_year: {
          userId,
          month: input.month,
          year: input.year,
        },
      },
    });

    if (existing) {
      throw createError('Budget for this month already exists', 409);
    }

    const budget = await prisma.budget.create({
      data: {
        userId,
        amount: input.amount,
        month: input.month,
        year: input.year,
      },
    });

    return budget;
  },

  /**
   * Get all budgets for user
   */
  async findAll(userId: string) {
    const budgets = await prisma.budget.findMany({
      where: { userId },
      orderBy: [
        { year: 'desc' },
        { month: 'desc' },
      ],
    });

    return budgets;
  },

  /**
   * Get budget by ID
   */
  async findById(userId: string, budgetId: string) {
    const budget = await prisma.budget.findFirst({
      where: {
        id: budgetId,
        userId,
      },
    });

    if (!budget) {
      throw createError('Budget not found', 404);
    }

    return budget;
  },

  /**
   * Get budget by month and year
   */
  async findByMonth(userId: string, month: number, year: number) {
    const budget = await prisma.budget.findUnique({
      where: {
        userId_month_year: {
          userId,
          month,
          year,
        },
      },
    });

    return budget;
  },

  /**
   * Update budget
   */
  async update(userId: string, budgetId: string, input: {
    amount?: number;
  }) {
    // Check if budget exists
    await this.findById(userId, budgetId);

    const budget = await prisma.budget.update({
      where: { id: budgetId },
      data: {
        ...(input.amount !== undefined && { amount: input.amount }),
      },
    });

    return budget;
  },

  /**
   * Delete budget
   */
  async delete(userId: string, budgetId: string) {
    // Check if budget exists
    await this.findById(userId, budgetId);

    await prisma.budget.delete({
      where: { id: budgetId },
    });

    return { message: 'Budget deleted successfully' };
  },

  /**
   * Get current month budget
   */
  async getCurrentMonthBudget(userId: string) {
    const now = new Date();
    return this.findByMonth(userId, now.getMonth() + 1, now.getFullYear());
  },

  /**
   * Get all budgets for sync
   */
  async findAllForSync(userId: string, since?: Date) {
    const where: Record<string, unknown> = { userId };

    if (since) {
      where.updatedAt = { gte: since };
    }

    const budgets = await prisma.budget.findMany({
      where,
      orderBy: { updatedAt: 'asc' },
    });

    return budgets;
  },

  /**
   * Bulk upsert budgets (for sync)
   */
  async bulkUpsert(userId: string, budgets: Array<{
    id: string;
    amount: number;
    month: number;
    year: number;
    createdAt?: Date;
    updatedAt?: Date;
  }>) {
    const results = [];

    for (const budget of budgets) {
      const result = await prisma.budget.upsert({
        where: { id: budget.id },
        create: {
          id: budget.id,
          userId,
          amount: budget.amount,
          month: budget.month,
          year: budget.year,
          createdAt: budget.createdAt || new Date(),
          updatedAt: budget.updatedAt || new Date(),
        },
        update: {
          amount: budget.amount,
          month: budget.month,
          year: budget.year,
          updatedAt: budget.updatedAt || new Date(),
        },
      });
      results.push(result);
    }

    return results;
  },
};
