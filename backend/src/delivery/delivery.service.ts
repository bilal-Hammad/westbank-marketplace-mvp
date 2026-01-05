import { PrismaClient, DeliveryProviderType, DeliveryStatus, OrderStatus } from "@prisma/client";
import { taxiSequentialDispatch } from "../taxi/taxi.service";

const prisma = new PrismaClient();

async function estimateTravelMinutesToBranch(): Promise<number> {
  // MVP ثابت. لاحقًا Google Directions + ذكاء محلي.
  return 12;
}

export async function startDeliveryConfirmation(orderId: string) {
  const order = await prisma.order.update({
    where: { id: orderId },
    data: { status: OrderStatus.DELIVERY_CONFIRMING },
    include: { branch: true },
  });

  // First try to assign to an internal driver
  const now = new Date();
  const onlineDriver = await prisma.driverStatus.findFirst({
    where: {
      isOnline: true,
      user: {
        isActive: true,
        role: "DRIVER",
        driverContracts: {
          some: {
            status: "ACTIVE",
            startDate: { lte: now },
            endDate: { gt: now },
          },
        },
      },
    },
    include: { user: true },
    orderBy: { lastSeenAt: "asc" }, // Oldest first to balance load
  });

  if (onlineDriver) {
    const delivery = await prisma.delivery.create({
      data: {
        orderId,
        providerType: DeliveryProviderType.INTERNAL_DRIVER,
        status: DeliveryStatus.CONFIRMED,
        confirmedAt: new Date(),
      },
    });

    // ✅ Start preparing
    await prisma.order.update({ where: { id: orderId }, data: { status: OrderStatus.PREPARING } });

    await scheduleInternalDriverMove(orderId);
    return;
  }

  // Fallback to taxi
  const delivery = await prisma.delivery.create({
    data: { orderId, providerType: DeliveryProviderType.TAXI_OFFICE, status: DeliveryStatus.PENDING },
  });

  const taxiOfficeId = await taxiSequentialDispatch(delivery.id);

  if (!taxiOfficeId) {
    await prisma.order.update({ where: { id: orderId }, data: { status: OrderStatus.CANCELLED } });
    await prisma.delivery.update({ where: { id: delivery.id }, data: { status: DeliveryStatus.CANCELLED } });
    return;
  }

  await prisma.delivery.update({
    where: { id: delivery.id },
    data: { status: DeliveryStatus.CONFIRMED, taxiOfficeId, confirmedAt: new Date() },
  });

  // ✅ الآن فقط يبدأ التحضير
  await prisma.order.update({ where: { id: orderId }, data: { status: OrderStatus.PREPARING } });

  await scheduleTaxiMove(orderId);
}

export async function scheduleTaxiMove(orderId: string) {
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: { delivery: true, branch: true },
  });
  if (!order || !order.delivery) return;

  // For taxi deliveries, schedule pickup after preparation time
  const prep = order.prepMinutes ?? order.branch.prepTimeMinutes;
  const scheduledMoveAt = new Date(Date.now() + prep * 60_000);

  await prisma.delivery.update({
    where: { id: order.delivery.id },
    data: { scheduledMoveAt },
  });
}

export async function scheduleInternalDriverMove(orderId: string) {
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: { delivery: true, branch: true },
  });
  if (!order || !order.delivery) return;

  const prep = order.prepMinutes ?? order.branch.prepTimeMinutes;
  const travel = await estimateTravelMinutesToBranch();
  const waitMinutes = Math.max(0, prep - travel);
  const scheduledMoveAt = new Date(Date.now() + waitMinutes * 60_000);

  // Keep status as CONFIRMED until a driver accepts it.
  // (Driver app shows CONFIRMED deliveries in "available" list.)
  await prisma.delivery.update({
    where: { id: order.delivery.id },
    data: { scheduledMoveAt },
  });

  // For internal drivers, the delivery is already assigned and confirmed
  // They will see it in their available deliveries and can start when ready
}

async function sendTaxiGoNow(deliveryId: string) {
  const d = await prisma.delivery.findUnique({
    where: { id: deliveryId },
    include: { taxiOffice: true, order: { include: { branch: true } } },
  });
  if (!d || !d.taxiOffice) return;

  console.log(`[TAXI][MOCK] GO NOW -> ${d.taxiOffice.name} whatsapp=${d.taxiOffice.whatsapp} delivery=${deliveryId}`);
}
