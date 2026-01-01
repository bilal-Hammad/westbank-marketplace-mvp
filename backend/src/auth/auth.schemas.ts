import { z } from "zod";

export const RequestOtpSchema = z.object({
  phone: z.string().min(6).max(20),
});

export const VerifyOtpSchema = z.object({
  phone: z.string().min(6).max(20),
  code: z.string().length(6),
  name: z.string().min(2).max(60).optional(),
});
