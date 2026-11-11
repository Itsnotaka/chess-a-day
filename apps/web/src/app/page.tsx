import { Board } from "@/components/Board";
import { BetaPill } from "@/components/Chrome";
import { LevelSymbol, type LevelName } from "@/components/LevelSymbol";

const italian = "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3";

const levels: { name: LevelName; detail: string; tint: string }[] = [
  { name: "Easy", detail: "Learning the moves. The computer misses a lot.", tint: "text-teal" },
  { name: "Medium", detail: "You know the rules and a few tricks.", tint: "text-purple" },
  { name: "Hard", detail: "You play regularly and see tactics coming.", tint: "text-red" },
  { name: "Expert", detail: "Club strength. Few free pieces here.", tint: "text-brown" },
  { name: "Master", detail: "No mercy.", tint: "text-ink" },
];

const ways = [
  {
    title: "The computer",
    detail: "Stockfish 17 at five levels, with or without a clock.",
    icon: "M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18zm0 4.5a4.5 4.5 0 1 0 0 9 4.5 4.5 0 0 0 0-9z",
  },
  {
    title: "Free play",
    detail: "Two people, one phone. Turn the board or keep it still.",
    icon: "M8 2.5h8A2.5 2.5 0 0 1 18.5 5v14a2.5 2.5 0 0 1-2.5 2.5H8A2.5 2.5 0 0 1 5.5 19V5A2.5 2.5 0 0 1 8 2.5zm2 15.5a.75.75 0 0 0 0 1.5h4a.75.75 0 0 0 0-1.5z",
  },
  {
    title: "Online",
    detail: "Invite a friend through Game Center and take turns at your own pace.",
    icon: "M8.5 4a3.5 3.5 0 1 1 0 7 3.5 3.5 0 0 1 0-7zm8 1.5a3 3 0 1 1 0 6 3 3 0 0 1 0-6zM2 19c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6v1H2zm14.5-6c3 0 5.5 2 5.5 5v2h-5v-1c0-2.4-.9-4.4-2.4-5.7.6-.2 1.2-.3 1.9-.3z",
  },
  {
    title: "Learn",
    detail: "Opening courses you play through, move by move, with stars to earn.",
    icon: "M12 3 1.5 8.5 12 14l8.5-4.45V16h2V8.5zM5.5 12.6v3.9C5.5 18.4 8.4 20 12 20s6.5-1.6 6.5-3.5v-3.9L12 16z",
  },
];

const courses = [
  { title: "London System", side: "As White", summary: "One calm setup for White against almost anything." },
  { title: "Italian Game", side: "As White", summary: "Quick development and a bishop aimed at f7." },
  { title: "Sicilian Dragon", side: "As Black", summary: "Black's sharpest answer to 1.e4, with a fianchetto bishop." },
  { title: "Caro-Kann Defence", side: "As Black", summary: "A rock-solid answer to 1.e4." },
];

const quiet = [
  { title: "No account, no ads, no tracking", detail: "Your games and settings stay on your iPhone." },
  { title: "A streak that stays gentle", detail: "A day strip and stats for wins, draws and losses at every level." },
  { title: "One reminder, if you want it", detail: "A single daily nudge at the time you choose." },
  { title: "Made for everyone", detail: "VoiceOver labels every square. Reduce Motion turns slides into fades. Text follows your size." },
];

function Glyph({ d }: { d: string }) {
  return (
    <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-ink text-on-ink">
      <svg viewBox="0 0 24 24" aria-hidden="true" className="h-[22px] w-[22px]" fill="currentColor">
        <path d={d} fillRule="evenodd" />
      </svg>
    </span>
  );
}

function SectionTitle({ id, kicker, title }: { id: string; kicker: string; title: string }) {
  return (
    <div className="mb-6 sm:mb-8">
      <p className="text-[15px] font-bold text-ink-muted">{kicker}</p>
      <h2 id={id} className="mt-1 text-[clamp(1.9rem,4.5vw,2.75rem)] font-black leading-[1.05] tracking-[-0.02em] text-balance">
        {title}
      </h2>
    </div>
  );
}

export default function Home() {
  return (
    <div className="mx-auto max-w-5xl px-5 sm:px-8">
      <section aria-labelledby="hero" className="grid items-center gap-10 pt-12 sm:pt-16 lg:grid-cols-[1.05fr_1fr] lg:gap-14">
        <div>
          <h1 id="hero" className="text-[clamp(2.75rem,7.5vw,4.75rem)] font-black leading-[0.98] tracking-[-0.035em] text-balance">
            One calm game of chess a day.
          </h1>
          <p className="mt-6 max-w-[34ch] text-[clamp(1.15rem,2.2vw,1.35rem)] font-medium leading-snug text-ink-muted text-pretty">
            Play the computer at your level, keep a gentle streak, then put the phone down.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-x-5 gap-y-3">
            <BetaPill />
            <p className="text-[15px] font-semibold text-ink-muted">Free on iPhone · iOS 18 or later</p>
          </div>
        </div>

        <div className="rounded-card bg-card p-6 pb-8 shadow-card sm:p-8">
          <div className="text-center leading-none">
            <p aria-hidden="true" className="faded text-[clamp(2.6rem,9vw,3.6rem)] font-black tracking-[-0.04em]">
              Today
            </p>
            <p className="mt-1 text-[clamp(2.6rem,9vw,3.6rem)] font-black tracking-[-0.04em]">Your move</p>
            <p className="mt-4 inline-flex items-center gap-2 text-[15px] font-semibold text-ink-muted">
              <span aria-hidden="true" className="h-2.5 w-2.5 rounded-full bg-purple" />
              Medium · No clock
            </p>
          </div>
          <div className="relative mx-auto mt-6 max-w-[340px] [perspective:900px]">
            <div className="[transform:rotateX(14deg)_rotateZ(-2deg)]">
              <Board fen={italian} last={["f1", "c4"]} caption="A game in progress: the Italian Game after 3.Bc4" />
            </div>
          </div>
          <div aria-hidden="true" className="mx-auto mt-6 grid max-w-[340px] grid-cols-3 rounded-full bg-raised p-1 text-center text-[15px] font-bold">
            <span className="rounded-full bg-card py-2 shadow-card">White</span>
            <span className="py-2 text-ink-muted">Random</span>
            <span className="py-2 text-ink-muted">Black</span>
          </div>
        </div>
      </section>

      <section aria-labelledby="ways" className="pt-24 sm:pt-32">
        <SectionTitle id="ways" kicker="Four ways in" title="Play who you like, when you like." />
        <ul className="grid gap-3 sm:grid-cols-2">
          {ways.map((way) => (
            <li key={way.title} className="flex items-start gap-4 rounded-card bg-card p-6 shadow-card">
              <Glyph d={way.icon} />
              <div>
                <h3 className="text-[20px] font-extrabold tracking-tight">{way.title}</h3>
                <p className="mt-1 text-[16px] font-medium leading-snug text-ink-muted text-pretty">{way.detail}</p>
              </div>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="levels" className="grid gap-10 pt-24 sm:pt-32 lg:grid-cols-[1fr_1.1fr] lg:items-start">
        <div className="lg:sticky lg:top-10">
          <SectionTitle id="levels" kicker="Five levels" title="Pick how hard the computer plays." />
          <p className="max-w-[38ch] text-[17px] font-medium leading-relaxed text-ink-muted text-pretty">
            Each level has its own colour, and the computer takes a moment to think, so even the hard games feel
            like a person across the table. Change it whenever you like; it applies from your next game.
          </p>
        </div>
        <ul className="flex flex-col gap-2.5 rounded-card bg-card p-4 shadow-card sm:p-5">
          {levels.map((level) => {
            const selected = level.name === "Medium";
            return (
              <li
                key={level.name}
                className={`rounded-row px-5 py-4 ${selected ? "bg-ink text-on-ink" : "bg-raised"}`}
              >
                <div className="flex items-center gap-3.5">
                  <LevelSymbol level={level.name} className={`h-[18px] w-[18px] ${selected ? "text-on-ink" : level.tint}`} />
                  <span className="text-[20px] font-bold">{level.name}</span>
                </div>
                <p className={`mt-1.5 pl-8 text-[15px] font-medium leading-snug ${selected ? "opacity-80" : "text-ink-muted"}`}>
                  {level.detail}
                </p>
              </li>
            );
          })}
        </ul>
      </section>

      <section aria-labelledby="learn" className="pt-24 sm:pt-32">
        <SectionTitle id="learn" kicker="Learn" title="Four openings, taught one move at a time." />
        <ul className="grid gap-3 sm:grid-cols-2">
          {courses.map((course) => (
            <li key={course.title} className="rounded-card bg-card p-6 shadow-card">
              <p className="text-[14px] font-bold text-ink-muted">{course.side}</p>
              <h3 className="mt-1 text-[22px] font-extrabold tracking-tight">{course.title}</h3>
              <p className="mt-1.5 text-[16px] font-medium leading-snug text-ink-muted text-pretty">{course.summary}</p>
            </li>
          ))}
        </ul>
        <p className="mt-5 text-[15px] font-medium text-ink-muted">
          Courses are lichess studies, shared by their authors. Find each move, get a hint when you need one, then
          practise for three stars.
        </p>
      </section>

      <section aria-labelledby="quiet" className="pt-24 sm:pt-32">
        <SectionTitle id="quiet" kicker="Quiet by design" title="Nothing asks for your attention." />
        <ul className="overflow-hidden rounded-card bg-card shadow-card">
          {quiet.map((item, i) => (
            <li key={item.title} className={`px-6 py-5 sm:px-8 ${i > 0 ? "border-t border-hairline" : ""}`}>
              <h3 className="text-[18px] font-bold">{item.title}</h3>
              <p className="mt-1 text-[16px] font-medium leading-snug text-ink-muted text-pretty">{item.detail}</p>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="cta" className="pt-24 sm:pt-32">
        <div className="rounded-card bg-card px-6 py-14 text-center shadow-card sm:py-16">
          <h2 id="cta" className="text-[clamp(2.2rem,6vw,3.5rem)] font-black leading-none tracking-[-0.035em]">
            Your move.
          </h2>
          <p className="mx-auto mt-4 max-w-[36ch] text-[17px] font-medium leading-snug text-ink-muted text-pretty">
            Install TestFlight from the App Store, then open the beta link on your iPhone.
          </p>
          <BetaPill className="mt-8" />
        </div>
      </section>
    </div>
  );
}
