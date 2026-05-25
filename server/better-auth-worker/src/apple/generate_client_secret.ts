import { SignJWT, importPKCS8 } from "jose";

/** Builds the ES256 client secret JWT Apple expects for Sign in with Apple. */
export async function generateAppleClientSecret(args: {
  teamId: string;
  keyId: string;
  clientId: string;
  privateKeyPem: string;
}): Promise<string> {
  const pem = args.privateKeyPem.replace(/\\n/g, "\n").trim();
  const key = await importPKCS8(pem, "ES256");
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: args.keyId })
    .setIssuer(args.teamId)
    .setIssuedAt(now)
    .setExpirationTime(now + 86400 * 180)
    .setAudience("https://appleid.apple.com")
    .setSubject(args.clientId)
    .sign(key);
}
