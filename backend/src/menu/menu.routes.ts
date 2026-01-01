import { Router } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
export const menuRouter = Router();

menuRouter.get("/store/:storeId", async (req, res) => {
  const { storeId } = req.params;
  const menu = await prisma.menu.findFirst({
    where: { storeId },
    include: {
      items: {
        where: { isActive: true },
        include: {
          optionGroups: { include: { options: { where: { isActive: true } } } },
        },
      },
    },
  });
  if (!menu) return res.status(404).json({ error: "MENU_NOT_FOUND" });
  res.json({ menu });
});
