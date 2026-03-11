import { Router } from 'express';
import { budgetController } from '../controllers/budget.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

router.post('/', budgetController.create);
router.get('/', budgetController.findAll);
router.get('/current', budgetController.getCurrentMonth);
router.get('/month/:month/:year', budgetController.findByMonth);
router.get('/:id', budgetController.findById);
router.put('/:id', budgetController.update);
router.delete('/:id', budgetController.delete);

export default router;
