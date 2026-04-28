import { AwsClient } from "aws4fetch";

type OtpEmailArgs = {
  to: string;
  code: string;
  awsAccessKeyId?: string;
  awsSecretAccessKey?: string;
  awsSessionToken?: string;
  awsRegion: string;
  fromEmail: string;
  appName?: string;
};

/** Sends a 6-digit OTP email through AWS SES. */
export async function sendOtpEmail({
  to,
  code,
  awsAccessKeyId,
  awsSecretAccessKey,
  awsSessionToken,
  awsRegion,
  fromEmail,
  appName = "LOLIPANTS",
}: OtpEmailArgs): Promise<void> {
  if (
    !awsAccessKeyId ||
    !awsSecretAccessKey ||
    awsAccessKeyId.trim().length === 0 ||
    awsSecretAccessKey.trim().length === 0
  ) {
    console.warn(
      JSON.stringify({
        event: "otp_email_skipped",
        reason: "missing_aws_ses_credentials",
        to,
      }),
    );
    return;
  }

  const subject = `${appName} | Your sign-in code`;
  const html = buildOtpHtml({ appName, code });
  const text =
    `Your ${appName} sign-in code is ${code}. It expires in 10 minutes.\n\n` +
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
        event: "otp_email_failed",
        to,
        status: response.status,
        provider: "aws_ses",
        body: errorBody,
      }),
    );
  }
}

function buildOtpHtml({
  appName,
  code,
}: {
  appName: string;
  code: string;
}): string {
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${appName} sign-in code</title>
  </head>
  <body style="margin:0;padding:0;background:#0A0A0A;font-family:Arial,sans-serif;color:#F5E6C8;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#0A0A0A;padding:24px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:620px;background:#141414;border:1px solid #3A2F1C;border-radius:16px;overflow:hidden;">
            <tr>
              <td style="padding:28px;">
                <div style="font-size:12px;letter-spacing:1.8px;color:#D8B86A;">${appName}</div>
                <h1 style="margin:12px 0 0 0;font-size:24px;line-height:1.3;color:#F5E6C8;">Your sign-in code</h1>
                <p style="margin:12px 0 0 0;font-size:15px;line-height:1.6;color:#EDE0C5;">
                  Enter this code in the app to continue. It expires in 10 minutes.
                </p>
                <div style="margin:24px 0;padding:18px 22px;background:#1F1A0F;border:1px solid #3A2F1C;border-radius:12px;text-align:center;font-size:30px;letter-spacing:10px;color:#D8B86A;font-weight:700;">
                  ${code}
                </div>
                <p style="margin:0;font-size:12px;line-height:1.6;color:#8E8164;">
                  If you did not request this code, you can safely ignore this message.
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
