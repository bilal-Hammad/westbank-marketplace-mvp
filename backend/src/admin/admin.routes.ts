import { Router } from "express";
import { PrismaClient, DriverContractStatus, UserRole } from "@prisma/client";
import { requireAuth } from "../auth/auth.middleware";
import { requireRoles } from "../auth/role.guard";
import { z } from "zod";

const prisma = new PrismaClient();
export const adminRouter = Router();

adminRouter.use(requireAuth, requireRoles(["ADMIN"]));

// ------------------------------
// Drivers & Contracts
// ------------------------------

adminRouter.get("/drivers", async (_req, res) => {
  const now = new Date();
  const items = await prisma.user.findMany({
    where: { role: UserRole.DRIVER },
    select: {
      id: true,
      phone: true,
      name: true,
      role: true,
      isActive: true,
      trustScore: true,
      createdAt: true,
      driverStatus: true,
      driverContracts: {
        orderBy: { createdAt: "desc" },
        take: 3,
      },
    },
    orderBy: { createdAt: "desc" },
    take: 200,
  });

  const mapped = items.map((u) => {
    const active = u.driverContracts.find(
      (c) => c.status === DriverContractStatus.ACTIVE && c.startDate <= now && c.endDate > now
    );
    return {
      ...u,
      activeContract: active || null,
      contractDaysLeft: active ? Math.ceil((active.endDate.getTime() - now.getTime()) / 86_400_000) : null,
    };
  });

  res.json({ items: mapped });
});

const SetUserRoleSchema = z.object({
  role: z.enum(["CUSTOMER", "DRIVER", "STORE_OWNER", "ADMIN"]),
});

adminRouter.post("/users/:userId/role", async (req, res) => {
  const parsed = SetUserRoleSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });

  const user = await prisma.user.update({
    where: { id: req.params.userId },
    data: { role: parsed.data.role as any },
    select: { id: true, phone: true, name: true, role: true, isActive: true },
  });

  res.json({ user });
});

const CreateDriverContractSchema = z.object({
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime(),
  autoRenew: z.boolean().optional(),
  commissionRate: z.number().min(0).max(100).optional(),
  notes: z.string().optional(),
});

adminRouter.post("/drivers/:userId/contracts", async (req, res) => {
  const parsed = CreateDriverContractSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });

  // Ensure user exists and is a DRIVER
  await prisma.user.update({
    where: { id: req.params.userId },
    data: { role: UserRole.DRIVER },
  });

  const contract = await prisma.driverContract.create({
    data: {
      driverUserId: req.params.userId,
      startDate: parsed.data.startDate ? new Date(parsed.data.startDate) : new Date(),
      endDate: new Date(parsed.data.endDate),
      autoRenew: parsed.data.autoRenew ?? false,
      commissionRate: parsed.data.commissionRate ?? 0,
      status: DriverContractStatus.ACTIVE,
      notes: parsed.data.notes,
    },
  });

  res.json({ contract });
});

const UpdateDriverContractSchema = z.object({
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  autoRenew: z.boolean().optional(),
  commissionRate: z.number().min(0).max(100).optional(),
  status: z.enum(["ACTIVE", "EXPIRED", "SUSPENDED", "TERMINATED"]).optional(),
  notes: z.string().optional(),
});

adminRouter.patch("/driver-contracts/:id", async (req, res) => {
  const parsed = UpdateDriverContractSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });

  const data: any = { ...parsed.data };
  if (data.startDate) data.startDate = new Date(data.startDate);
  if (data.endDate) data.endDate = new Date(data.endDate);
  const contract = await prisma.driverContract.update({ where: { id: req.params.id }, data });
  res.json({ contract });
});

const TaxiOfficeSchema = z.object({
  name: z.string().min(2),
  whatsapp: z.string().min(6),
  city: z.string().optional(),
  area: z.string().optional(),
  priority: z.number().min(1).max(10000).optional(),
  isActive: z.boolean().optional(),
});

adminRouter.get("/taxi-offices", async (_req, res) => {
  const items = await prisma.taxiOffice.findMany({ orderBy: { priority: "asc" } });
  res.json({ items });
});

adminRouter.post("/taxi-offices", async (req, res) => {
  const parsed = TaxiOfficeSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });

  const office = await prisma.taxiOffice.create({
    data: {
      name: parsed.data.name,
      whatsapp: parsed.data.whatsapp,
      city: parsed.data.city,
      area: parsed.data.area,
      priority: parsed.data.priority ?? 100,
      isActive: parsed.data.isActive ?? true,
    },
  });
  res.json({ office });
});

adminRouter.patch("/taxi-offices/:id", async (req, res) => {
  const parsed = TaxiOfficeSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST" });

  const office = await prisma.taxiOffice.update({ where: { id: req.params.id }, data: parsed.data });
  res.json({ office });
});

adminRouter.delete("/taxi-offices/:id", async (req, res) => {
  await prisma.taxiOffice.delete({ where: { id: req.params.id } });
  res.json({ ok: true });
});
