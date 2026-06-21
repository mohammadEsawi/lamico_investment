import { Response } from "express";
import { AuthenticatedRequest } from "../middleware/authMiddleware";
import {
    createInventoryTransaction,
    getInventoryTransactions,
    getMyInventoryTransactions,
    getRawMaterialsStock,
    createRawMaterial,
    updateRawMaterial,
    deleteRawMaterial,
    getMaterialTransactions,
} from "../services/inventoryServices";

export const createInventoryTransactionHandler = async (
    req: AuthenticatedRequest,
    res: Response
) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            res.status(401).json({ message: "Not authorized" });
            return;
        }

        const result = await createInventoryTransaction(userId, req.body ?? {});

        if (result.message) {
            res.status(result.status).json({ message: result.message });
            return;
        }

        res.status(result.status).json(result.data);
    } catch (error) {
        console.error("Create inventory transaction error:", error);
        res.status(500).json({ message: "Failed to create inventory transaction" });
    }
};

export const getInventoryTransactionsHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        const result = await getInventoryTransactions();
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error("Get inventory transactions error:", error);
        res.status(500).json({ message: "Failed to fetch inventory transactions" });
    }
};

export const getMyInventoryTransactionsHandler = async (
    req: AuthenticatedRequest,
    res: Response
) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            res.status(401).json({ message: "Not authorized" });
            return;
        }

        const result = await getMyInventoryTransactions(userId);
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error("Get my inventory transactions error:", error);
        res.status(500).json({ message: "Failed to fetch my inventory transactions" });
    }
};

export const getRawMaterialsStockHandler = async (_req: AuthenticatedRequest, res: Response) => {
    try {
        const result = await getRawMaterialsStock();
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error("Get raw materials stock error:", error);
        res.status(500).json({ message: "Failed to fetch stock" });
    }
};

export const createRawMaterialHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const result = await createRawMaterial(req.body ?? {});
        if (result.message) { res.status(result.status).json({ message: result.message }); return; }
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error('Create material error:', error);
        res.status(500).json({ message: 'Failed to create material' });
    }
};

export const updateRawMaterialHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const id = Number(req.params.id);
        const result = await updateRawMaterial(id, req.body ?? {});
        if (result.message) { res.status(result.status).json({ message: result.message }); return; }
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error('Update material error:', error);
        res.status(500).json({ message: 'Failed to update material' });
    }
};

export const deleteRawMaterialHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const id = Number(req.params.id);
        const result = await deleteRawMaterial(id);
        if (result.message && result.status !== 200) { res.status(result.status).json({ message: result.message }); return; }
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error('Delete material error:', error);
        res.status(500).json({ message: 'Failed to delete material' });
    }
};

export const getMaterialTransactionsHandler = async (req: AuthenticatedRequest, res: Response) => {
    try {
        const id = Number(req.params.id);
        const result = await getMaterialTransactions(id);
        res.status(result.status).json(result.data);
    } catch (error) {
        console.error('Get material transactions error:', error);
        res.status(500).json({ message: 'Failed to fetch transactions' });
    }
};
