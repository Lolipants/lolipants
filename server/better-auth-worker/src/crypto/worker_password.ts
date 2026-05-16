/**
 * Password hashing for Cloudflare Workers.
 *
 * The default `@better-auth/utils/password` bundle uses pure JS scrypt and
 * exceeds CPU limits (Cloudflare error 1102). This uses `node:crypto` scrypt
 * with the same parameters and `salt:hex` format as Better Auth.
 */
import { randomBytes, scrypt } from "node:crypto";

const config = {
  N: 16384,
  r: 16,
  p: 1,
  dkLen: 64,
} as const;

function generateKey(password: string, salt: string): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scrypt(
      password.normalize("NFKC"),
      salt,
      config.dkLen,
      {
        N: config.N,
        r: config.r,
        p: config.p,
        maxmem: 128 * config.N * config.r * 2,
      },
      (err: Error | null, key: Buffer) => {
        if (err) reject(err);
        else resolve(key);
      },
    );
  });
}

/** Hashes a plaintext password for storage. */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString("hex");
  const key = await generateKey(password, salt);
  return `${salt}:${key.toString("hex")}`;
}

/** Verifies a plaintext password against a stored hash. */
export async function verifyPassword(
  hash: string,
  password: string,
): Promise<boolean> {
  const [salt, key] = hash.split(":");
  if (!salt || !key) {
    return false;
  }
  const targetKey = await generateKey(password, salt);
  return targetKey.toString("hex") === key;
}
