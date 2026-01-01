import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || "dev_secret";

export type AuthedRequest = Request & { user?: { id: string; role: string; jti: string } };

export async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : "";
    if (!token) return res.status(401).json({ error: "UNAUTHORIZED" });

    const payload = jwt.verify(token, JWT_SECRET) as any;
    const userId = payload.sub as string;
    const jti = payload.jti as string;

    const session = await prisma.session.findUnique({ where: { tokenJti: jti } });
    if (!session || session.revokedAt) return res.status(401).json({ error: "SESSION_REVOKED" });

    req.user = { id: userId, role: payload.role, jti };
    next();
  } catch {
    return res.status(401).json({ error: "UNAUTHORIZED" });
  }
}
