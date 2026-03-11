import { prisma } from '../config/database';
import { createError } from '../middleware/errorHandler';

const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 20;

/**
 * Expense Service - handles expense CRUD operations
 */
export const expenseService = {
  /**
   * Create a new expense
   */
  async create(userId: string, input: {
    amount: number;
    description: string;
    category: string;
    date: Date;
  }) {
    const expense = await prisma.expense.create({
      data: {
        userId,
        amount: input.amount,
        description: input.description,
        category: input.category,
        date: input.date,
      },
    });

    return expense;
  },

  /**
   * Get expenses with pagination and filters
   */
  async findAll(userId: string, query: {
    page?: number;
    limit?: number;
    category?: string;
    startDate?: Date;
    endDate?: Date;
    sortBy?: 'date' | 'amount' | 'createdAt';
    sortOrder?: 'asc' | 'desc';
  }) {
    const page = query.page || DEFAULT_PAGE;
    const limit = query.limit || DEFAULT_LIMIT;
    const skip = (page - 1) * limit;

    // Build where clause
    const where: Record<string, unknown> = { userId };

    if (query.category) {
      where.category = query.category;
    }

    if (query.startDate || query.endDate) {
      where.date = {};
      if (query.startDate) {
        (where.date as Record<string, Date>).gte = query.startDate;
      }
      if (query.endDate) {
        (where.date as Record<string, Date>).lte = query.endDate;
      }
    }

    // Build order by
    const sortBy = query.sortBy || 'date';
    const sortOrder = query.sortOrder || 'desc';
    const orderBy: Record<string, string> = {};
    orderBy[sortBy] = sortOrder;

    // Execute queries in parallel
    const [expenses, total] = await Promise.all([
      prisma.expense.findMany({
        where,
        orderBy,
        skip,
        take: limit,
      }),
      prisma.expense.count({ where }),
    ]);

    return {
      expenses,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  },

  /**
   * Get expense by ID
   */
  async findById(userId: string, expenseId: string) {
    const expense = await prisma.expense.findFirst({
      where: {
        id: expenseId,
        userId,
      },
    });

    if (!expense) {
      throw createError('Expense not found', 404);
    }

    return expense;
  },

  /**
   * Update expense
   */
  async update(userId: string, expenseId: string, input: {
    amount?: number;
    description?: string;
    category?: string;
    date?: Date;
  }) {
    // Check if expense exists
    await this.findById(userId, expenseId);

    const expense = await prisma.expense.update({
      where: { id: expenseId },
      data: {
        ...(input.amount !== undefined && { amount: input.amount }),
        ...(input.description !== undefined && { description: input.description }),
        ...(input.category !== undefined && { category: input.category }),
        ...(input.date !== undefined && { date: input.date }),
      },
    });

    return expense;
  },

  /**
   * Delete expense
   */
  async delete(userId: string, expenseId: string) {
    // Check if expense exists
    await this.findById(userId, expenseId);

    await prisma.expense.delete({
      where: { id: expenseId },
    });

    return { message: 'Expense deleted successfully' };
  },

  /**
   * Get expense summary by category or time period
   */
  async getSummary(userId: string, query: {
    startDate?: Date;
    endDate?: Date;
    groupBy?: 'category' | 'month' | 'day';
  }) {
    const where: Record<string, unknown> = { userId };

    if (query.startDate || query.endDate) {
      where.date = {};
      if (query.startDate) {
        (where.date as Record<string, Date>).gte = query.startDate;
      }
      if (query.endDate) {
        (where.date as Record<string, Date>).lte = query.endDate;
      }
    }

    const groupBy = query.groupBy || 'category';

    if (groupBy === 'category') {
      // Group by category
      const result = await prisma.expense.groupBy({
        by: ['category'],
        where,
        _sum: {
          amount: true,
        },
        _count: true,
        orderBy: {
          _sum: {
            amount: 'desc',
          },
        },
      });

      return result.map((item) => ({
        category: item.category,
        totalAmount: item._sum.amount || 0,
        count: item._count,
      }));
    } else if (groupBy === 'month') {
      // Group by month
      const expenses = await prisma.expense.findMany({
        where,
        select: {
          amount: true,
          date: true,
        },
        orderBy: { date: 'asc' },
      });

      // Group by month manually
      const monthlyData: Record<string, { totalAmount: number; count: number }> = {};

      for (const expense of expenses) {
        const monthKey = `${expense.date.getFullYear()}-${String(expense.date.getMonth() + 1).padStart(2, '0')}`;
        if (!monthlyData[monthKey]) {
          monthlyData[monthKey] = { totalAmount: 0, count: 0 };
        }
        monthlyData[monthKey].totalAmount += expense.amount;
        monthlyData[monthKey].count += 1;
      }

      return Object.entries(monthlyData)
        .map(([month, data]) => ({
          month,
          totalAmount: data.totalAmount,
          count: data.count,
        }))
        .sort((a, b) => a.month.localeCompare(b.month));
    }

    return [];
  },

  /**
   * Get all expenses for sync (no pagination)
   */
  async findAllForSync(userId: string, since?: Date) {
    const where: Record<string, unknown> = { userId };

    if (since) {
      where.updatedAt = { gte: since };
    }

    const expenses = await prisma.expense.findMany({
      where,
      orderBy: { updatedAt: 'asc' },
    });

    return expenses;
  },

  /**
   * Bulk upsert expenses (for sync)
   */
  async bulkUpsert(userId: string, expenses: Array<{
    id: string;
    amount: number;
    description: string;
    category: string;
    date: Date;
    createdAt?: Date;
    updatedAt?: Date;
    isSynced?: boolean;
  }>) {
    const results = [];

    for (const expense of expenses) {
      const result = await prisma.expense.upsert({
        where: { id: expense.id },
        create: {
          id: expense.id,
          userId,
          amount: expense.amount,
          description: expense.description,
          category: expense.category,
          date: expense.date,
          createdAt: expense.createdAt || new Date(),
          updatedAt: expense.updatedAt || new Date(),
          isSynced: true,
        },
        update: {
          amount: expense.amount,
          description: expense.description,
          category: expense.category,
          date: expense.date,
          updatedAt: expense.updatedAt || new Date(),
          isSynced: true,
        },
      });
      results.push(result);
    }

    return results;
  },

  /**
   * Mark expenses as synced
   */
  async markAsSynced(userId: string, expenseIds: string[]) {
    await prisma.expense.updateMany({
      where: {
        id: { in: expenseIds },
        userId,
      },
      data: { isSynced: true },
    });

    return { message: 'Expenses marked as synced' };
  },
};
