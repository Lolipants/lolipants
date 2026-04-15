import { AwsClient } from "aws4fetch";

type ResetPasswordEmailArgs = {
  to: string;
  resetUrl: string;
  awsAccessKeyId?: string;
  awsSecretAccessKey?: string;
  awsSessionToken?: string;
  awsRegion: string;
  fromEmail: string;
  appName?: string;
};

/** Sends a branded LOLIPANTS password-reset email through AWS SES. */
export async function sendResetPasswordEmail({
  to,
  resetUrl,
  awsAccessKeyId,
  awsSecretAccessKey,
  awsSessionToken,
  awsRegion,
  fromEmail,
  appName = "LOLIPANTS",
}: ResetPasswordEmailArgs): Promise<void> {
  if (
    !awsAccessKeyId ||
    !awsSecretAccessKey ||
    awsAccessKeyId.trim().length === 0 ||
    awsSecretAccessKey.trim().length === 0
  ) {
    console.warn(
      JSON.stringify({
        event: "password_reset_email_skipped",
        reason: "missing_aws_ses_credentials",
        to,
      }),
    );
    return;
  }

  const subject = `${appName} | Reset your password`;
  const html = buildResetPasswordHtml({ appName, resetUrl });
  const text =
    `Reset your password for ${appName}: ${resetUrl}\n\n` +
    "If you did not request this, you can ignore this email.";

  const ses = new AwsClient({
    accessKeyId: awsAccessKeyId,
    secretAccessKey: awsSecretAccessKey,
    sessionToken: awsSessionToken,
    service: "ses",
    region: awsRegion,
  });
  const endpoint = `https://email.${awsRegion}.amazonaws.com/v2/email/outbound-emails`;

  const response = await ses.fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      FromEmailAddress: fromEmail,
      Destination: {
        ToAddresses: [to],
      },
      Content: {
        Simple: {
          Subject: { Data: subject, Charset: "UTF-8" },
          Body: {
            Html: { Data: html, Charset: "UTF-8" },
            Text: { Data: text, Charset: "UTF-8" },
          },
        },
      },
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(
      JSON.stringify({
        event: "password_reset_email_failed",
        to,
        status: response.status,
        provider: "aws_ses",
        body: errorBody,
      }),
    );
  }
}

function buildResetPasswordHtml({
  appName,
  resetUrl,
}: {
  appName: string;
  resetUrl: string;
}): string {
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${appName} password reset</title>
  </head>
  <body style="margin:0;padding:0;background:#0A0A0A;font-family:Arial,sans-serif;color:#F5E6C8;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#0A0A0A;padding:24px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:620px;background:#141414;border:1px solid #3A2F1C;border-radius:16px;overflow:hidden;">
            <tr>
              <td style="padding:28px 28px 12px 28px;">
                <div style="font-size:12px;letter-spacing:1.8px;color:#D8B86A;">${appName}</div>
                <h1 style="margin:12px 0 0 0;font-size:24px;line-height:1.3;color:#F5E6C8;">Reset your password</h1>
                <p style="margin:12px 0 0 0;font-size:13px;color:#B9A782;">????? ????? ???? ??????</p>
              </td>
            </tr>
            <tr>
              <td style="padding:8px 28px 0 28px;">
                <p style="margin:0;font-size:15px;line-height:1.6;color:#EDE0C5;">
                  We received a request to reset your password. Use the secure button below to continue.
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:24px 28px;">
                <a href="${resetUrl}" style="display:inline-block;padding:14px 22px;background:#D8B86A;color:#1B1B1B;text-decoration:none;border-radius:10px;font-weight:700;font-size:14px;">
                  Reset Password
                </a>
              </td>
            </tr>
            <tr>
              <td style="padding:0 28px 12px 28px;">
                <p style="margin:0;font-size:12px;line-height:1.7;color:#A69774;">
                  If the button does not work, copy and paste this link into your browser:
                </p>
                <p style="word-break:break-all;margin:10px 0 0 0;font-size:12px;line-height:1.6;color:#D8B86A;">
                  ${resetUrl}
                </p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 28px 26px 28px;border-top:1px solid #2A2418;">
                <p style="margin:0;font-size:12px;line-height:1.6;color:#8E8164;">
                  If you did not request this reset, you can safely ignore this message.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}