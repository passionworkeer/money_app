import { Router } from 'express';
import { settingsController } from '../controllers/settings.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

// All routes require authentication
router.use(authenticate);

router.get('/', settingsController.getSettings);
router.put('/', settingsController.updateSettings);
router.get('/ai-keys', settingsController.getAiKeys);
router.put('/ai-keys', settingsController.updateAiKeys);

export default router;
