export const site = {
  name: "Chess a Day",
  description:
    "A calm chess app for iPhone. One game against the computer a day, free play on one phone, games with friends through Game Center, and opening courses.",
  betaUrl: "https://testflight.apple.com/join/HEGSJfUE",
  email: "itsnotaka@gmail.com",
  developer: "Min Chun Fu",
  updated: "November 11, 2026",
} as const;

export function siteUrl(): URL {
  const host = process.env.VERCEL_PROJECT_PRODUCTION_URL;
  return new URL(host ? `https://${host}` : "http://localhost:3000");
}
