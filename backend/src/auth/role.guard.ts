import { Response, NextFunction } from "express";
import { AuthedRequest } from "./auth.middleware";

export function requireRoles(roles: Array<"CUSTOMER"|"DRIVER"|"STORE_OWNER"|"ADMIN">) {
  return (req: AuthedRequest, res: Response, next: NextFunction) => {
    const role = (req.user?.role || "") as any;
    if (!role) return res.status(401).json({ error: "UNAUTHORIZED" });
    if (!roles.includes(role) && role !== "ADMIN") return res.status(403).json({ error: "FORBIDDEN" });
    next();
  };
}
