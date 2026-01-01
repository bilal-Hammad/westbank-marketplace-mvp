import { Router } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
export const storesRouter = Router();

storesRouter.get("/", async (_req, res) => {
  const stores = await prisma.store.findMany({
    where: { isActive: true },
    include: { branches: { where: { isOpen: true } } },
    orderBy: { createdAt: "desc" },
  });
  res.json({ stores });
});

storesRouter.get("/:id", async (req, res) => {
  const store = await prisma.store.findUnique({
    where: { id: req.params.id },
    include: { branches: { where: { isOpen: true } }, menus: true },
  });
  if (!store) return res.status(404).json({ error: "NOT_FOUND" });
  res.json({ store });
});
