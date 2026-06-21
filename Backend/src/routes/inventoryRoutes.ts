import { Router } from 'express';
import {
  createInventoryTransactionHandler,
  getInventoryTransactionsHandler,
  getMyInventoryTransactionsHandler,
  getRawMaterialsStockHandler,
  createRawMaterialHandler,
  updateRawMaterialHandler,
  deleteRawMaterialHandler,
  getMaterialTransactionsHandler,
} from '../controllers/inventoryController';
import { authorizeRoles } from '../middleware/authMiddleware';
import { UserRole } from '../config/generated/prisma/client';

const router = Router();
const ALL_ROLES = [UserRole.ADMIN, UserRole.ENGINEER, UserRole.ACCOUNTANT, UserRole.WORKER, UserRole.SALES_REP];
const ADMIN_ONLY = [UserRole.ADMIN];
const MANAGERS = [UserRole.ADMIN, UserRole.ACCOUNTANT];

router.get('/materials', authorizeRoles(ALL_ROLES), getRawMaterialsStockHandler);
router.post('/transactions', authorizeRoles(ALL_ROLES), createInventoryTransactionHandler);
router.post('/materials', authorizeRoles(ADMIN_ONLY), createRawMaterialHandler);
router.put('/materials/:id', authorizeRoles(ADMIN_ONLY), updateRawMaterialHandler);
router.delete('/materials/:id', authorizeRoles(ADMIN_ONLY), deleteRawMaterialHandler);
router.get('/materials/:id/transactions', authorizeRoles(ALL_ROLES), getMaterialTransactionsHandler);
router.get('/transactions/all', authorizeRoles(MANAGERS), getInventoryTransactionsHandler);
router.get('/transactions/me', authorizeRoles(ALL_ROLES), getMyInventoryTransactionsHandler);

export default router;
