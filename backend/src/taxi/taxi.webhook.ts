import { Router } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
export const taxiWebhookRouter = Router();

/**
 * MVP WhatsApp reply webhook
 * POST /taxi/whatsapp-reply
 * Body example: { "from": "970599111111", "text": "1" }
 */
taxiWebhookRouter.post("/whatsapp-reply", async (req, res) => {
  const { from, text } = req.body as { from: string; text: string };
  if (!from || !text) return res.status(400).json({ error: "BAD_REQUEST" });

  const office = await prisma.taxiOffice.findFirst({ where: { whatsapp: from, isActive: true } });
  if (!office) return res.status(404).json({ error: "OFFICE_NOT_FOUND" });

  const attempt = await prisma.taxiDispatchAttempt.findFirst({
    where: { taxiOfficeId: office.id, status: "SENT" },
    orderBy: { sentAt: "desc" },
  });

  if (!attempt) return res.json({ ok: true, note: "NO_PENDING_ATTEMPT" });

  const normalized = text.trim();
  const status = normalized == "1" ? "ACCEPTED" : normalized == "2" ? "REJECTED" : "IGNORED";
  if (status === "IGNORED") return res.json({ ok: true, note: "IGNORED_TEXT" });

  await prisma.taxiDispatchAttempt.update({
    where: { id: attempt.id },
    data: { status, respondedAt: new Date() },
  });

  res.json({ ok: true });
});
