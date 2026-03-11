import { Router } from 'express';
import { syncController } from '../controllers/sync.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

router.get('/pull', syncController.pull);
router.post('/push', syncController.push);
router.post('/full', syncController.fullSync);
router.get('/status', syncController.status);

export default router;
