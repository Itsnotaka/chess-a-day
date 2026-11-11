import Link from "next/link";
import { Cast, Pawn } from "@/components/Cast";
import { BetaPill } from "@/components/Chrome";
import { Levels } from "@/components/Levels";
import { Modes } from "@/components/Modes";

function SectionTitle({ id, children }: { id: string; children: React.ReactNode }) {
  return (
    <h2 id={id} className="mx-auto mb-8 max-w-[18ch] text-center text-title font-bold text-balance sm:mb-10">
      {children}
    </h2>
  );
}

export default function Home() {
  return (
    <>
      <section aria-labelledby="hero" className="relative isolate overflow-x-clip">
        <div
          aria-hidden="true"
          className="chess-grid-fade pointer-events-none absolute inset-x-0 -top-28 bottom-0 -z-10"
        >
          <div className="chess-grid absolute inset-0" />
        </div>

        <div className="mx-auto grid max-w-7xl items-center px-5 pt-6 pb-20 sm:px-8 sm:pt-10 sm:pb-28 lg:grid-cols-[1fr_minmax(0,34rem)_1fr] lg:gap-6 lg:pt-16">
          <div className="hidden lg:block">
            <Cast side="left" />
          </div>

          <div className="flex flex-col items-center text-center">
            <div className="mb-8 w-full max-w-sm lg:hidden">
              <Cast side="row" />
            </div>
            <h1 id="hero" className="text-display font-bold text-balance">
              One calm game of chess a day.
            </h1>
            <p className="mt-6 max-w-[28ch] text-lead font-medium text-pretty text-ink-muted">
              Play the computer at your level, then put your phone down.
            </p>
            <BetaPill className="mt-8" />
            <p className="mt-4 text-label font-semibold text-ink-muted">Free on iPhone with iOS 18 or later.</p>
          </div>

          <div className="hidden lg:block">
            <Cast side="right" />
          </div>
        </div>
      </section>

      <div className="mx-auto max-w-5xl px-5 sm:px-8">
        <section aria-labelledby="levels" className="mx-auto max-w-2xl">
          <SectionTitle id="levels">Five levels, from Easy to Master.</SectionTitle>
          <Levels />
        </section>

        <section aria-labelledby="modes" className="pt-24 sm:pt-32">
          <SectionTitle id="modes">Four ways to play.</SectionTitle>
          <Modes />
        </section>

        <section aria-labelledby="cta" className="pt-24 sm:pt-32">
          <div className="flex flex-col items-center rounded-card bg-card px-6 pt-12 pb-12 text-center shadow-card sm:pb-16">
            <Pawn className="w-20" />
            <h2 id="cta" className="mt-6 text-title font-bold">
              Your move.
            </h2>
            <p className="mt-3 max-w-[34ch] text-body font-medium text-pretty text-ink-muted">
              Install TestFlight, then open the beta link on your iPhone.
            </p>
            <BetaPill className="mt-8" />
            <p className="mt-8 text-label font-semibold text-ink-muted">
              No account, no ads, no tracking.{" "}
              <Link
                href="/privacy"
                className="text-ink underline decoration-ink-faint underline-offset-4 hover:decoration-ink"
              >
                Privacy policy
              </Link>
            </p>
          </div>
        </section>
      </div>
    </>
  );
}
