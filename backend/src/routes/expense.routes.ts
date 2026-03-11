import { Router } from 'express';
import { expenseController } from '../controllers/expense.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

router.post('/', expenseController.create);
router.get('/', expenseController.findAll);
router.get('/summary', expenseController.summary);
router.get('/:id', expenseController.findById);
router.put('/:id', expenseController.update);
router.delete('/:id', expenseController.delete);

export default router;
