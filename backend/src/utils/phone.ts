export function normalizePhone(input: string): string {
  let p = input.trim().replace(/\s+/g, "");
  if (p.startsWith("+")) p = p.substring(1);
  return p;
}
