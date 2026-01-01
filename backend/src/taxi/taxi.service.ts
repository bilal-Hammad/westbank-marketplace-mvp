import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const RESPONSE_TIMEOUT_MS = 60_000;

async function sendWhatsAppYesNoMock(whatsapp: string, text: string) {
  // لاحقًا: دمج WhatsApp Business API
  console.log(`[WHATSAPP][MOCK] to=${whatsapp} msg="${text}"`);
}

async function waitForTaxiResponseDb(attemptId: string): Promise<"ACCEPTED"|"REJECTED"|"TIMEOUT"> {
  const started = Date.now();
  while (Date.now() - started < RESPONSE_TIMEOUT_MS) {
    const attempt = await prisma.taxiDispatchAttempt.findUnique({ where: { id: attemptId } });
    if (!attempt) return "TIMEOUT";
    if (attempt.status === "ACCEPTED") return "ACCEPTED";
    if (attempt.status === "REJECTED") return "REJECTED";
    await new Promise(r => setTimeout(r, 1000));
  }
  return "TIMEOUT";
}

export async function taxiSequentialDispatch(deliveryId: string): Promise<string | null> {
  const offices = await prisma.taxiOffice.findMany({
    where: { isActive: true },
    orderBy: { priority: "asc" },
  });

  for (const office of offices) {
    const attempt = await prisma.taxiDispatchAttempt.create({
      data: { deliveryId, taxiOfficeId: office.id, status: "SENT" },
    });

    await sendWhatsAppYesNoMock(
      office.whatsapp,
      `🚕 طلب توصيل جديد\nللرد خلال 60 ثانية:\n1) قبول\n2) رفض\n(Attempt:${attempt.id})`
    );

    const resp = await waitForTaxiResponseDb(attempt.id);

    if (resp === "ACCEPTED") {
      await prisma.taxiDispatchAttempt.update({ where: { id: attempt.id }, data: { status: "ACCEPTED", respondedAt: new Date() } });
      return office.id;
    }
    if (resp === "REJECTED") {
      await prisma.taxiDispatchAttempt.update({ where: { id: attempt.id }, data: { status: "REJECTED", respondedAt: new Date() } });
      continue;
    }
    await prisma.taxiDispatchAttempt.update({ where: { id: attempt.id }, data: { status: "TIMEOUT", respondedAt: new Date() } });
  }

  return null;
}
