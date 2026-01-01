import { Router } from "express";
import { PrismaClient, OrderStatus } from "@prisma/client";
import { requireAuth, AuthedRequest } from "../auth/auth.middleware";
import { z } from "zod";

const prisma = new PrismaClient();
export const ordersRouter = Router();

const CreateOrderSchema = z.object({
  storeId: z.string(),
  branchId: z.string(),
  notesToStore: z.string().optional(),
  notesToDriver: z.string().optional(),
  items: z.array(z.object({
    itemId: z.string(),
    qty: z.number().min(1).max(99),
    optionIds: z.array(z.string()).optional(),
    notes: z.string().optional(),
  })).min(1),
});

ordersRouter.post("/", requireAuth, async (req: AuthedRequest, res) => {
  const parsed = CreateOrderSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });

  const userId = req.user!.id;

  const addr = await prisma.address.findFirst({ where: { userId, isDefault: true } });
  if (!addr) return res.status(400).json({ error: "NO_DEFAULT_ADDRESS" });

  let subtotal = 0;

  const menuItems = await prisma.menuItem.findMany({
    where: { id: { in: parsed.data.items.map(i => i.itemId) }, isActive: true },
    include: { optionGroups: { include: { options: true } } },
  });
  const byId = new Map(menuItems.map(m => [m.id, m]));

  const order = await prisma.$transaction(async (tx) => {
    const o = await tx.order.create({
      data: {
        userId,
        storeId: parsed.data.storeId,
        branchId: parsed.data.branchId,
        addressId: addr.id,
        status: OrderStatus.PENDING_STORE,
        notesToStore: parsed.data.notesToStore,
        notesToDriver: parsed.data.notesToDriver,
      }
    });

    for (const it of parsed.data.items) {
      const mi = byId.get(it.itemId);
      if (!mi) throw new Error("ITEM_NOT_FOUND");

      const unitPrice = mi.basePrice;
      let optionsTotal = 0;

      const chosenOptions: any[] = [];
      const optionIds = it.optionIds ?? [];
      if (optionIds.length) {
        const allOptions = mi.optionGroups.flatMap(g => g.options);
        const optById = new Map(allOptions.map(o => [o.id, o]));
        for (const oid of optionIds) {
          const opt = optById.get(oid);
          if (!opt || !opt.isActive) throw new Error("OPTION_INVALID");
          optionsTotal += opt.priceAdd;
          chosenOptions.push(opt);
        }
      }

      const lineTotal = (unitPrice + optionsTotal) * it.qty;
      subtotal += lineTotal;

      const orderItem = await tx.orderItem.create({
        data: {
          orderId: o.id,
          itemId: mi.id,
          nameSnap: mi.name,
          unitPrice,
          qty: it.qty,
          notes: it.notes,
        },
      });

      for (const opt of chosenOptions) {
        await tx.orderItemOption.create({
          data: { orderItemId: orderItem.id, nameSnap: opt.name, priceAdd: opt.priceAdd },
        });
      }
    }

    const deliveryFee = 800; // 8 شيكل (إذا تستخدم *100)
    const total = subtotal + deliveryFee;

    return tx.order.update({
      where: { id: o.id },
      data: { subtotal, deliveryFee, total },
      include: { items: { include: { options: true } }, store: true, branch: true, delivery: true },
    });
  });

  res.json({ order });
});

ordersRouter.get("/:id", requireAuth, async (req: AuthedRequest, res) => {
  const order = await prisma.order.findFirst({
    where: { id: req.params.id, userId: req.user!.id },
    include: { items: { include: { options: true } }, delivery: true, store: true, branch: true, address: true },
  });
  if (!order) return res.status(404).json({ error: "NOT_FOUND" });
  res.json({ order });
});
