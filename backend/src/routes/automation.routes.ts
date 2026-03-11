import { Router } from 'express';
import { automationController } from '../controllers/automation.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

router.post('/', automationController.create);
router.get('/', automationController.findAll);
router.get('/:id', automationController.findById);
router.put('/:id', automationController.update);
router.delete('/:id', automationController.delete);
router.post('/:id/toggle', automationController.toggle);

export default router;
