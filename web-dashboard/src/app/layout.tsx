import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/components/AuthProvider";
import { I18nProvider } from "@/components/I18nProvider";

export const metadata: Metadata = {
  title: "Lolipants Dashboard | لوحة تحكم Lolipants",
  description: "Admin and tailor operations console | لوحة عمليات الإدارة والخياطين",
  icons: {
    icon: [
      { url: "/web-app-manifest-192x192.png?v=2", sizes: "192x192", type: "image/png" },
      { url: "/web-app-manifest-512x512.png?v=2", sizes: "512x512", type: "image/png" },
    ],
    shortcut: [{ url: "/web-app-manifest-192x192.png?v=2", type: "image/png" }],
    apple: [{ url: "/web-app-manifest-192x192.png", sizes: "192x192", type: "image/png" }],
  },
  manifest: "/manifest.json",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="antialiased">
        <I18nProvider>
          <AuthProvider>{children}</AuthProvider>
        </I18nProvider>
      </body>
    </html>
  );
}
