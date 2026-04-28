import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { betterAuth } from "better-auth";
import { bearer, emailOTP } from "better-auth/plugins";
import type { DrizzleD1Database } from "drizzle-orm/d1";
import * as schema from "./db/schema";
import { sendResetPasswordEmail } from "./email/reset_password_email";
import { sendOtpEmail } from "./email/otp_email";

type SocialProviderConfig = {
  clientId?: string;
  clientSecret?: string;
};

type AppleProviderConfig = {
  clientId?: string;
  teamId?: string;
  keyId?: string;
  privateKey?: string;
};

type CreateAuthArgs = {
  db: DrizzleD1Database<typeof schema>;
  secret: string;
  baseURL: string;
  trustedOrigins: string[];
  awsAccessKeyId?: string;
  awsSecretAccessKey?: string;
  awsSessionToken?: string;
  awsSesRegion: string;
  resetFromEmail: string;
  appName?: string;
  google?: SocialProviderConfig;
  apple?: AppleProviderConfig;
};

/** Creates a Better Auth instance for a single request. */
export function createAuth({
  db,
  secret,
  baseURL,
  trustedOrigins,
  awsAccessKeyId,
  awsSecretAccessKey,
  awsSessionToken,
  awsSesRegion,
  resetFromEmail,
  appName,
  google,
  apple,
}: CreateAuthArgs) {
  const socialProviders: Record<string, unknown> = {};
  if (google?.clientId && google.clientSecret) {
    socialProviders.google = {
      clientId: google.clientId,
      clientSecret: google.clientSecret,
    };
  }
  if (apple?.clientId && apple.teamId && apple.keyId && apple.privateKey) {
    socialProviders.apple = {
      clientId: apple.clientId,
      teamId: apple.teamId,
      keyId: apple.keyId,
      // Apple expects the PKCS#8 private key. Accept literal PEM or
      // base64-single-line form so it round-trips through wrangler secrets.
      privateKey: apple.privateKey.includes("BEGIN PRIVATE KEY")
        ? apple.privateKey
        : `-----BEGIN PRIVATE KEY-----\n${apple.privateKey}\n-----END PRIVATE KEY-----`,
    };
  }

  return betterAuth({
    secret,
    baseURL,
    basePath: "/auth",
    trustedOrigins,
    database: drizzleAdapter(db, {
      provider: "sqlite",
      schema,
      usePlural: false,
    }),
    user: {
      additionalFields: {
        role: {
          type: "string",
          defaultValue: "user",
          input: false,
        },
        adminScopes: {
          type: "string",
          defaultValue: "[]",
          input: false,
        },
      },
    },
    emailAndPassword: {
      enabled: true,
      requireEmailVerification: false,
      sendResetPassword: async ({ user, url }) => {
        await sendResetPasswordEmail({
          to: user.email,
          resetUrl: url,
          awsAccessKeyId,
          awsSecretAccessKey,
          awsSessionToken,
          awsRegion: awsSesRegion,
          fromEmail: resetFromEmail,
          appName,
        });
      },
    },
    socialProviders:
      Object.keys(socialProviders).length > 0
        ? (socialProviders as never)
        : undefined,
    plugins: [
      bearer(),
      emailOTP({
        otpLength: 6,
        expiresIn: 600,
        sendVerificationOTP: async ({ email, otp }) => {
          await sendOtpEmail({
            to: email,
            code: otp,
            awsAccessKeyId,
            awsSecretAccessKey,
            awsSessionToken,
            awsRegion: awsSesRegion,
            fromEmail: resetFromEmail,
            appName,
          });
        },
      }),
    ],
  });
}
