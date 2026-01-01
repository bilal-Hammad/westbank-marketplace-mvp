import { Router } from "express";
import { PrismaClient } from "@prisma/client";
import { requireAuth, AuthedRequest } from "../auth/auth.middleware";
import { z } from "zod";

const prisma = new PrismaClient();
export const addressesRouter = Router();

const CreateAddressSchema = z.object({
  label: z.string().optional(),
  city: z.string().optional(),
  area: z.string().optional(),
  details: z.string().optional(),
  lat: z.number(),
  lng: z.number(),
  isDefault: z.boolean().optional(),
});

addressesRouter.get("/", requireAuth, async (req: AuthedRequest, res) => {
  const items = await prisma.address.findMany({
    where: { userId: req.user!.id },
    orderBy: { createdAt: "desc" },
  });
  res.json({ items });
});

addressesRouter.post("/", requireAuth, async (req: AuthedRequest, res) => {
  const parsed = CreateAddressSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });

  if (parsed.data.isDefault) {
    await prisma.address.updateMany({
      where: { userId: req.user!.id, isDefault: true },
      data: { isDefault: false },
    });
  }

  const address = await prisma.address.create({
    data: {
      ...parsed.data,
      userId: req.user!.id,
      isDefault: parsed.data.isDefault ?? false,
    },
  });

  res.json({ address });
});

addressesRouter.patch("/:id/default", requireAuth, async (req: AuthedRequest, res) => {
  const { id } = req.params;

  await prisma.address.updateMany({
    where: { userId: req.user!.id, isDefault: true },
    data: { isDefault: false },
  });

  const address = await prisma.address.update({
    where: { id },
    data: { isDefault: true },
  });

  res.json({ address });
});

addressesRouter.delete("/:id", requireAuth, async (req: AuthedRequest, res) => {
  const { id } = req.params;
  await prisma.address.delete({ where: { id } });
  res.json({ ok: true });
});
