import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { betterAuth } from "better-auth";
import { bearer, emailOTP } from "better-auth/plugins";
import type { DrizzleD1Database } from "drizzle-orm/d1";
import * as schema from "./db/schema";
import { sendResetPasswordEmail } from "./email/reset_password_email";
import { sendOtpEmail } from "./email/otp_email";
import {
  hashPassword as hashWorkerPassword,
  verifyPassword as verifyWorkerPassword,
} from "./crypto/worker_password";

type SocialProviderConfig = {
  clientId?: string;
  clientSecret?: string;
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
}: CreateAuthArgs) {
  const socialProviders: Record<string, unknown> = {};
  if (google?.clientId && google.clientSecret) {
    socialProviders.google = {
      clientId: google.clientId,
      clientSecret: google.clientSecret,
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
    // OAuth is started from the Flutter app via HTTP (Dio), but Google finishes in
    // the system browser / Custom Tab. The default "database" state strategy also
    // sets a signed `state` cookie on the start request — that cookie never reaches
    // the browser, so the callback would fail with state_mismatch. Skipping the
    // cookie check still validates `state` against the verification row in D1.
    account: {
      skipStateCookieCheck: true,
    },
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
      password: {
        hash: hashWorkerPassword,
        verify: async ({ hash, password }) =>
          verifyWorkerPassword(hash, password),
      },
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
