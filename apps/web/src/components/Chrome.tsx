import Link from "next/link";
import Image from "next/image";
import { site } from "@/site";

const navLink = "press inline-flex min-h-11 items-center rounded-full px-2.5 hover:text-ink";

export function Header() {
  return (
    <header className="relative z-10 mx-auto flex w-full max-w-5xl items-center justify-between gap-2 px-5 pt-6 sm:px-8">
      <Link href="/" className="press flex min-h-11 shrink-0 items-center gap-3 rounded-full pr-2">
        <Image src="/app-icon.png" alt="" width={44} height={44} className="rounded-[11px]" priority />
        <span className="text-lg font-extrabold tracking-tight whitespace-nowrap max-[359px]:sr-only">{site.name}</span>
      </Link>
      <nav aria-label="Site">
        <ul className="-mr-2.5 flex items-center text-label font-semibold text-ink-muted sm:mr-0">
          <li>
            <Link href="/support" className={navLink}>
              Support
            </Link>
          </li>
          <li>
            <Link href="/privacy" className={navLink}>
              Privacy
            </Link>
          </li>
          <li className="ml-2 hidden sm:block">
            <a
              href={site.betaUrl}
              className="press inline-flex min-h-11 items-center rounded-full bg-ink px-5 font-bold text-on-ink"
            >
              Join the beta
            </a>
          </li>
        </ul>
      </nav>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="mx-auto w-full max-w-5xl px-5 pt-16 pb-10 text-small text-ink-muted sm:px-8">
      <div className="flex flex-col gap-6 border-t border-hairline pt-8">
        <p className="max-w-[60ch] text-pretty">
          Free software under the GPLv3, built on Stockfish 17, ChessKit and Vortex. Pieces by cburnett, Merida and
          Chessnut. Courses from lichess studies by LeninPerez and francesco_super.
        </p>
        <div className="flex flex-wrap items-center justify-between gap-x-4">
          <p>© 2026 {site.developer}</p>
          <ul className="-mr-2.5 flex font-semibold">
            <li>
              <Link href="/support" className={navLink}>
                Support
              </Link>
            </li>
            <li>
              <Link href="/privacy" className={navLink}>
                Privacy
              </Link>
            </li>
            <li>
              <a href={`mailto:${site.email}`} className={navLink}>
                Email
              </a>
            </li>
          </ul>
        </div>
      </div>
    </footer>
  );
}

const pill =
  "press inline-flex min-h-14 items-center gap-2.5 rounded-full bg-ink px-7 text-[1.1875rem] font-bold text-on-ink shadow-card";

export function BetaPill({ className = "" }: { className?: string }) {
  return (
    <a href={site.betaUrl} className={`${pill} ${className}`}>
      <svg viewBox="0 0 24 24" aria-hidden="true" className="-ml-0.5 size-4" fill="currentColor">
        <path d="M7.5 4.5v15a1 1 0 0 0 1.5.86l12.5-7.5a1 1 0 0 0 0-1.72L9 3.64A1 1 0 0 0 7.5 4.5z" />
      </svg>
      Join the beta
    </a>
  );
}

export function EmailPill({ subject, className = "" }: { subject: string; className?: string }) {
  return (
    <a href={`mailto:${site.email}?subject=${encodeURIComponent(subject)}`} className={`${pill} ${className}`}>
      Email support
    </a>
  );
}
