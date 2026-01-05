import jwt from "jsonwebtoken";
import { PrismaClient, UserRole } from "@prisma/client";
import { generateOtp, hashOtp, verifyOtp } from "../utils/crypto";
import { normalizePhone } from "../utils/phone";
import { randomUUID } from "crypto";

const prisma = new PrismaClient();

const JWT_SECRET = process.env.JWT_SECRET || "dev_secret";
const OTP_TTL = Number(process.env.OTP_TTL_SECONDS || 300);

export async function requestOtp(rawPhone: string) {
  console.log("requestOtp called with:", rawPhone);
  const phone = normalizePhone(rawPhone);
  console.log("Normalized phone:", phone);

  const user = await prisma.user.upsert({
    where: { phone },
    update: {},
    create: { phone, role: UserRole.CUSTOMER },
  });
  console.log("User upserted:", user.id);

  const code = generateOtp();
  const codeHash = await hashOtp(code);
  const expiresAt = new Date(Date.now() + OTP_TTL * 1000);

  await prisma.otpCode.create({
    data: { userId: user.id, codeHash, expiresAt },
  });

  console.log(`[OTP][MOCK] phone=${phone} code=${code} expiresIn=${OTP_TTL}s`);
  return { ok: true };
}

export async function verifyOtpAndIssueToken(rawPhone: string, code: string, name?: string) {
  const phone = normalizePhone(rawPhone);

  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user || !user.isActive) throw new Error("USER_NOT_FOUND_OR_INACTIVE");

  const otp = await prisma.otpCode.findFirst({
    where: { userId: user.id, usedAt: null, expiresAt: { gt: new Date() } },
    orderBy: { createdAt: "desc" },
  });
  if (!otp) throw new Error("OTP_NOT_FOUND_OR_EXPIRED");

  const ok = await verifyOtp(code, otp.codeHash);
  if (!ok) throw new Error("OTP_INVALID");

  await prisma.otpCode.update({ where: { id: otp.id }, data: { usedAt: new Date() } });

  // If user is registering for the first time and provided a name, persist it.
  // Also allow quick MVP driver registration by naming convention.
  let roleForToken = user.role;
  if (name && !user.name) {
    const role = name.toLowerCase().includes("driver") ? UserRole.DRIVER : UserRole.CUSTOMER;
    await prisma.user.update({ where: { id: user.id }, data: { name, role } });
    roleForToken = role;
  }

  const jti = randomUUID();
  await prisma.session.create({ data: { userId: user.id, tokenJti: jti } });

  const token = jwt.sign({ sub: user.id, role: roleForToken, jti }, JWT_SECRET, { expiresIn: "30d" });
  return { token };
}

export async function getMe(userId: string) {
  return prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, phone: true, name: true, role: true, trustScore: true, isActive: true },
  });
}
