import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { betterAuth } from "better-auth";
import { bearer } from "better-auth/plugins";
import type { DrizzleD1Database } from "drizzle-orm/d1";
import * as schema from "./db/schema";
import { sendResetPasswordEmail } from "./email/reset_password_email";

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
}: CreateAuthArgs) {
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
    plugins: [bearer()],
  });
}
