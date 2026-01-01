import { Router } from "express";
import { PrismaClient, DeliveryStatus, UserRole, DriverContractStatus } from "@prisma/client";
import { requireAuth, AuthedRequest } from "../auth/auth.middleware";
import { requireRoles } from "../auth/role.guard";
import { z } from "zod";

const prisma = new PrismaClient();
export const driverRouter = Router();

driverRouter.use(requireAuth);
driverRouter.use(requireRoles([UserRole.DRIVER]));

async function requireActiveDriverContract(req: AuthedRequest, res: any, next: any) {
  const now = new Date();
  const contract = await prisma.driverContract.findFirst({
    where: {
      driverUserId: req.user!.id,
      status: DriverContractStatus.ACTIVE,
      startDate: { lte: now },
      endDate: { gt: now },
    },
    orderBy: { endDate: "desc" },
  });

  if (!contract) {
    return res.status(403).json({ error: "CONTRACT_INACTIVE" });
  }

  // attach for downstream handlers if needed
  (req as any).driverContract = contract;
  next();
}

// Get current driver contract (if any)
driverRouter.get("/contract", async (req: AuthedRequest, res) => {
  const items = await prisma.driverContract.findMany({
    where: { driverUserId: req.user!.id },
    orderBy: { createdAt: "desc" },
    take: 10,
  });

  const now = new Date();
  const active = items.find((c) => c.status === "ACTIVE" && c.startDate <= now && c.endDate > now) || null;
  const daysLeft = active ? Math.ceil((active.endDate.getTime() - now.getTime()) / 86_400_000) : null;
  res.json({ active, daysLeft, items });
});

// Get driver status
driverRouter.get("/status", async (req: AuthedRequest, res) => {
  const status = await prisma.driverStatus.findUnique({
    where: { userId: req.user!.id },
  });
  if (!status) {
    return res.json({ status: { isOnline: false } });
  }
  res.json({ status });
});

// Go online
const GoOnlineSchema = z.object({
  lat: z.number().optional(),
  lng: z.number().optional(),
});

driverRouter.post("/online", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const parsed = GoOnlineSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST" });

  const status = await prisma.driverStatus.upsert({
    where: { userId: req.user!.id },
    update: {
      isOnline: true,
      lastSeenAt: new Date(),
      lastLat: parsed.data.lat,
      lastLng: parsed.data.lng,
    },
    create: {
      userId: req.user!.id,
      isOnline: true,
      lastSeenAt: new Date(),
      lastLat: parsed.data.lat,
      lastLng: parsed.data.lng,
    },
  });

  res.json({ status });
});

// Go offline
driverRouter.post("/offline", async (req: AuthedRequest, res) => {
  const status = await prisma.driverStatus.upsert({
    where: { userId: req.user!.id },
    update: {
      isOnline: false,
      lastSeenAt: new Date(),
    },
    create: {
      userId: req.user!.id,
      isOnline: false,
      lastSeenAt: new Date(),
    },
  });

  res.json({ status });
});

// Get available deliveries
driverRouter.get("/deliveries/available", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const deliveries = await prisma.delivery.findMany({
    where: {
      status: DeliveryStatus.CONFIRMED,
      driverUserId: null,
      providerType: "INTERNAL_DRIVER",
    },
    include: {
      order: {
        include: {
          items: { include: { options: true } },
          store: true,
          branch: true,
          address: true,
        },
      },
    },
    orderBy: [{ scheduledMoveAt: "asc" }, { confirmedAt: "asc" }],
    take: 20,
  });

  res.json({ items: deliveries });
});

// Get active deliveries
driverRouter.get("/deliveries/active", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const deliveries = await prisma.delivery.findMany({
    where: {
      driverUserId: req.user!.id,
      status: { in: [DeliveryStatus.SCHEDULED, DeliveryStatus.PICKING_UP, DeliveryStatus.ON_THE_WAY] },
    },
    include: {
      order: {
        include: {
          items: { include: { options: true } },
          store: true,
          branch: true,
          address: true,
        },
      },
    },
    orderBy: { scheduledMoveAt: "asc" },
  });

  res.json({ items: deliveries });
});

// Accept delivery
driverRouter.post("/deliveries/:deliveryId/accept", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const { deliveryId } = req.params;

  const delivery = await prisma.delivery.findUnique({
    where: { id: deliveryId },
    include: { order: true },
  });

  if (!delivery || delivery.status !== DeliveryStatus.CONFIRMED || delivery.driverUserId) {
    return res.status(400).json({ error: "DELIVERY_NOT_AVAILABLE" });
  }

  await prisma.delivery.update({
    where: { id: deliveryId },
    data: {
      driverUserId: req.user!.id,
      status: DeliveryStatus.SCHEDULED,
    },
  });

  const updated = await prisma.delivery.findUnique({
    where: { id: deliveryId },
    include: {
      order: {
        include: {
          items: { include: { options: true } },
          store: true,
          branch: true,
          address: true,
        },
      },
    },
  });

  res.json({ delivery: updated });
});

// Reject delivery
driverRouter.post("/deliveries/:deliveryId/reject", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const { deliveryId } = req.params;

  const delivery = await prisma.delivery.findUnique({
    where: { id: deliveryId },
  });

  if (!delivery || delivery.driverUserId !== req.user!.id) {
    return res.status(400).json({ error: "NOT_YOUR_DELIVERY" });
  }

  await prisma.delivery.update({
    where: { id: deliveryId },
    data: {
      driverUserId: null,
      status: DeliveryStatus.CONFIRMED,
    },
  });

  res.json({ ok: true });
});

// Mark as picking up
driverRouter.post("/deliveries/:deliveryId/pickup", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const { deliveryId } = req.params;

  const delivery = await prisma.delivery.findUnique({
    where: { id: deliveryId },
  });

  if (!delivery || delivery.driverUserId !== req.user!.id || delivery.status !== DeliveryStatus.SCHEDULED) {
    return res.status(400).json({ error: "INVALID_STATUS" });
  }

  await prisma.delivery.update({
    where: { id: deliveryId },
    data: {
      status: DeliveryStatus.PICKING_UP,
      startedMovingAt: new Date(),
    },
  });

  res.json({ ok: true });
});

// Mark as delivered
driverRouter.post("/deliveries/:deliveryId/delivered", requireActiveDriverContract, async (req: AuthedRequest, res) => {
  const { deliveryId } = req.params;

  const delivery = await prisma.delivery.findUnique({
    where: { id: deliveryId },
  });

  if (!delivery || delivery.driverUserId !== req.user!.id || delivery.status !== DeliveryStatus.ON_THE_WAY) {
    return res.status(400).json({ error: "INVALID_STATUS" });
  }

  await prisma.delivery.update({
    where: { id: deliveryId },
    data: {
      status: DeliveryStatus.DELIVERED,
      deliveredAt: new Date(),
    },
  });

  // Update order status
  await prisma.order.update({
    where: { id: delivery.orderId },
    data: { status: "COMPLETED" },
  });

  res.json({ ok: true });
});