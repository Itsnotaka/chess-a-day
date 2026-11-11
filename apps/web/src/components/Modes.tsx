import { Board } from "@/components/Board";
import { Buddy, Pawn } from "@/components/Cast";

/** Small scenes from the app, one per way to play. Decorative: each card's words carry the meaning. */

function Computer() {
  return (
    <div className="relative mx-auto w-44 pt-2 [perspective:700px]">
      <div className="[transform:rotateX(16deg)_rotateZ(-3deg)]">
        <Board
          fen="r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
          move={{ from: "f8", to: "c5" }}
          label="Italian Game"
        />
      </div>
      <span className="absolute -bottom-3 left-1/2 inline-flex -translate-x-1/2 items-center gap-1.5 rounded-full bg-ink px-4 py-2 text-small font-bold whitespace-nowrap text-on-ink shadow-card">
        <span className="size-2 rounded-full bg-purple" />
        Your move
      </span>
    </div>
  );
}

function FreePlay() {
  return (
    <div className="flex items-end justify-center gap-6 pt-4">
      <Pawn tone="light" className="w-20 -scale-x-100" />
      <span className="mb-8 rounded-full bg-raised px-3.5 py-1.5 text-small font-bold text-ink-muted">Your turn</span>
      <Pawn tone="ink" className="w-20" />
    </div>
  );
}

const games = [
  { who: "Alex", level: "Hard" as const, status: "Your move", time: "21 h left", mine: true },
  { who: "Sam", level: "Easy" as const, status: "Their move", time: "4 h left", mine: false },
];

function Online() {
  return (
    <ul className="mx-auto flex w-full max-w-72 flex-col gap-2">
      {games.map((game) => (
        <li key={game.who} className="flex items-center gap-3 rounded-row bg-raised px-3.5 py-2.5">
          <Buddy level={game.level} className="size-9 shrink-0" />
          <span className="min-w-0 flex-1">
            <span className="block text-label font-bold text-ink">{game.who}</span>
            <span className="block text-small font-medium text-ink-muted">{game.time}</span>
          </span>
          <span
            className={`rounded-full px-3 py-1 text-small font-bold whitespace-nowrap ${game.mine ? "bg-ink text-on-ink" : "text-ink-muted"}`}
          >
            {game.status}
          </span>
        </li>
      ))}
    </ul>
  );
}

const courses = [
  { title: "London System", side: "As White", stars: 3 },
  { title: "Sicilian Defence", side: "As Black", stars: 2 },
  { title: "Caro-Kann Defence", side: "As Black", stars: 0 },
];

function Learn() {
  return (
    <ul className="mx-auto flex w-full max-w-72 flex-col gap-2">
      {courses.map((course) => (
        <li key={course.title} className="flex items-center justify-between gap-3 rounded-row bg-raised px-4 py-2.5">
          <span className="min-w-0">
            <span className="block truncate text-label font-bold text-ink">{course.title}</span>
            <span className="block text-small font-medium text-ink-muted">{course.side}</span>
          </span>
          <span className="flex shrink-0 gap-0.5">
            {[0, 1, 2].map((i) => (
              <svg
                key={i}
                viewBox="0 0 24 24"
                className={`size-4 ${i < course.stars ? "text-brown" : "text-ink-faint"}`}
                fill="currentColor"
              >
                <path d="M12 2.8l2.8 5.9 6.4.8-4.7 4.4 1.2 6.4L12 17.2l-5.7 3.1 1.2-6.4-4.7-4.4 6.4-.8z" />
              </svg>
            ))}
          </span>
        </li>
      ))}
    </ul>
  );
}

const modes = [
  { title: "Computer", detail: "Stockfish 17 at five levels, with or without a clock.", scene: <Computer /> },
  { title: "Free play", detail: "Two players, one phone.", scene: <FreePlay /> },
  { title: "Online", detail: "Invite a friend through Game Center. Each move gets a day.", scene: <Online /> },
  { title: "Learn", detail: "Three openings, taught one move at a time.", scene: <Learn /> },
];

export function Modes() {
  return (
    <ul className="grid gap-3 sm:grid-cols-2">
      {modes.map((mode) => (
        <li key={mode.title} className="flex flex-col overflow-hidden rounded-card bg-card shadow-card">
          <div aria-hidden="true" className="flex h-64 items-center justify-center px-6 pt-8 pb-6">
            {mode.scene}
          </div>
          <div className="px-7 pt-2 pb-7">
            <h3 className="text-heading font-bold">{mode.title}</h3>
            <p className="mt-1 text-body font-medium text-pretty text-ink-muted">{mode.detail}</p>
          </div>
        </li>
      ))}
    </ul>
  );
}
