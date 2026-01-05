import { Router } from "express";
import { RequestOtpSchema, VerifyOtpSchema } from "./auth.schemas";
import { requestOtp, verifyOtpAndIssueToken, getMe } from "./auth.service";
import { requireAuth, AuthedRequest } from "./auth.middleware";

export const authRouter = Router();

authRouter.post("/request-otp", async (req, res) => {
  console.log("Received OTP request:", req.body);
  const parsed = RequestOtpSchema.safeParse(req.body);
  if (!parsed.success) {
    console.log("OTP validation failed:", parsed.error);
    return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });
  }
  console.log("OTP validation passed for phone:", parsed.data.phone);
  await requestOtp(parsed.data.phone);
  res.json({ ok: true });
});

authRouter.post("/verify-otp", async (req, res) => {
  const parsed = VerifyOtpSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "BAD_REQUEST", details: parsed.error.flatten() });
  try {
    const out = await verifyOtpAndIssueToken(parsed.data.phone, parsed.data.code, parsed.data.name);
    res.json(out);
  } catch (e: any) {
    res.status(400).json({ error: e.message || "VERIFY_FAILED" });
  }
});

authRouter.get("/me", requireAuth, async (req: AuthedRequest, res) => {
  const me = await getMe(req.user!.id);
  res.json({ me });
});
