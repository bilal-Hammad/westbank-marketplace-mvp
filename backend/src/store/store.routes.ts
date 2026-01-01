import { Router } from "express";
import { PrismaClient, OrderStatus } from "@prisma/client";
import { requireAuth, AuthedRequest } from "../auth/auth.middleware";
import { requireRoles } from "../auth/role.guard";
import { z } from "zod";
import { startDeliveryConfirmation } from "../delivery/delivery.service";

const prisma = new PrismaClient();
export const storeRouter = Router();

storeRouter.get("/orders/inbox", requireAuth, requireRoles(["STORE_OWNER"]), async (_req: AuthedRequest, res) => {
  const orders = await prisma.order.findMany({
    where: { status: OrderStatus.PENDING_STORE },
    orderBy: { createdAt: "desc" },
    include: { items: true, store: true, branch: true },
    take: 50,
  });
  res.json({ orders });
});

const AcceptSchema = z.object({
  orderId: z.string(),
  prepMinutes: z.number().min(5).max(240),
});

storeRouter.post("/orders/accept", requireAuth, requireRoles(["STORE_OWNER"]), async (req: AuthedRequest, res) => {
  const parsed = AcceptSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST" });

  const order = await prisma.order.update({
    where: { id: parsed.data.orderId },
    data: { status: OrderStatus.STORE_ACCEPTED_CONDITIONAL, prepMinutes: parsed.data.prepMinutes },
  });

  await startDeliveryConfirmation(order.id);
  res.json({ ok: true });
});

storeRouter.post("/orders/reject", requireAuth, requireRoles(["STORE_OWNER"]), async (req: AuthedRequest, res) => {
  const { orderId } = req.body as { orderId: string };
  await prisma.order.update({ where: { id: orderId }, data: { status: OrderStatus.CANCELLED } });
  res.json({ ok: true });
});

storeRouter.post("/orders/ready", requireAuth, requireRoles(["STORE_OWNER"]), async (req: AuthedRequest, res) => {
  const { orderId } = req.body as { orderId: string };
  await prisma.order.update({ where: { id: orderId }, data: { status: OrderStatus.READY } });
  res.json({ ok: true });
});
