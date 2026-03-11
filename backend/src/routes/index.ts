import { Router } from 'express';
import authRoutes from './auth.routes';
import expenseRoutes from './expense.routes';
import budgetRoutes from './budget.routes';
import settingsRoutes from './settings.routes';
import automationRoutes from './automation.routes';
import syncRoutes from './sync.routes';

const router = Router();

// Mount routes
router.use('/auth', authRoutes);
router.use('/expenses', expenseRoutes);
router.use('/budgets', budgetRoutes);
router.use('/settings', settingsRoutes);
router.use('/automation', automationRoutes);
router.use('/sync', syncRoutes);

// Health check
router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;
