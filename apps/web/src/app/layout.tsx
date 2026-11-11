import type { Metadata, Viewport } from "next";
import { Footer, Header } from "@/components/Chrome";
import { site, siteUrl } from "@/site";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: siteUrl(),
  title: { default: `${site.name}: calm chess for iPhone`, template: `%s · ${site.name}` },
  description: site.description,
  applicationName: site.name,
  openGraph: {
    type: "website",
    siteName: site.name,
    title: `${site.name}: calm chess for iPhone`,
    description: site.description,
    images: [{ url: "/app-icon.png", width: 256, height: 256, alt: `${site.name} app icon` }],
  },
  twitter: { card: "summary", title: site.name, description: site.description },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#e6e6e6" },
    { media: "(prefers-color-scheme: dark)", color: "#1a1a1a" },
  ],
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="flex min-h-dvh flex-col">
        <a
          href="#main"
          className="sr-only rounded-full bg-ink px-4 py-2 font-semibold text-on-ink focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-10"
        >
          Skip to content
        </a>
        <Header />
        <main id="main" className="flex-1">
          {children}
        </main>
        <Footer />
      </body>
    </html>
  );
}
