import Link from "next/link";
import Image from "next/image";
import { site } from "@/site";

export function Header() {
  return (
    <header className="mx-auto flex w-full max-w-5xl items-center justify-between gap-4 px-5 pt-6 sm:px-8">
      <Link href="/" className="press flex min-h-11 items-center gap-3 rounded-full pr-2">
        <Image src="/app-icon.png" alt="" width={44} height={44} className="rounded-[11px]" priority />
        <span className="text-lg font-extrabold tracking-tight">{site.name}</span>
      </Link>
      <nav aria-label="Site">
        <ul className="flex items-center gap-1 text-[15px] font-semibold text-ink-muted">
          <li>
            <Link href="/support" className="press inline-flex min-h-11 items-center rounded-full px-3 hover:text-ink">
              Support
            </Link>
          </li>
          <li>
            <Link href="/privacy" className="press inline-flex min-h-11 items-center rounded-full px-3 hover:text-ink">
              Privacy
            </Link>
          </li>
        </ul>
      </nav>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="mx-auto w-full max-w-5xl px-5 pb-12 pt-16 text-[14px] leading-relaxed text-ink-muted sm:px-8">
      <div className="border-t border-hairline pt-8">
        <p className="max-w-[62ch]">
          {site.name} is free software under the GPLv3. Engine: Stockfish 17 (GPLv3) via ChessKitEngine (MIT).
          Rules: ChessKit (MIT). Pieces: cburnett, Merida (GPLv2+), Chessnut (Apache 2.0). Effects: Vortex (MIT).
          Learn courses are lichess studies by LeninPerez and Sidattack243.
        </p>
        <div className="mt-6 flex flex-wrap items-center justify-between gap-4">
          <p>© 2026 {site.developer}</p>
          <ul className="flex gap-1 font-semibold">
            <li><Link href="/support" className="inline-flex min-h-11 items-center px-2 hover:text-ink">Support</Link></li>
            <li><Link href="/privacy" className="inline-flex min-h-11 items-center px-2 hover:text-ink">Privacy</Link></li>
            <li><a href={`mailto:${site.email}`} className="inline-flex min-h-11 items-center px-2 hover:text-ink">Email</a></li>
          </ul>
        </div>
      </div>
    </footer>
  );
}

export function BetaPill({ className = "" }: { className?: string }) {
  return (
    <a
      href={site.betaUrl}
      className={`press inline-flex min-h-14 items-center gap-2.5 rounded-full bg-ink px-7 text-[19px] font-bold text-on-ink shadow-card ${className}`}
    >
      <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4 w-4" fill="currentColor">
        <path d="M7 4.5v15a1 1 0 0 0 1.5.86l12.5-7.5a1 1 0 0 0 0-1.72L8.5 3.64A1 1 0 0 0 7 4.5z" />
      </svg>
      Join the beta
    </a>
  );
}
