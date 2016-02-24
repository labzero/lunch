import { Router } from 'express';
import Restaurant from '../models/Restaurant';

const router = new Router();

router.get('/', async (req, res, next) => {
  res.status(200).send('hi');
});

export default router;
