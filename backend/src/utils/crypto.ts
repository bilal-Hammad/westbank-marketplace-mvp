import bcrypt from "bcrypt";

export async function hashOtp(code: string): Promise<string> {
  return bcrypt.hash(code, 10);
}

export async function verifyOtp(code: string, hash: string): Promise<boolean> {
  return bcrypt.compare(code, hash);
}

export function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
