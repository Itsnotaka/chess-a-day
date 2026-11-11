export type LevelName = "Easy" | "Medium" | "Hard" | "Expert" | "Master";

const paths: Record<LevelName, string> = {
  Easy: "M5 5h14v14H5z",
  Medium: "M12 4a8 8 0 1 1 0 16 8 8 0 0 1 0-16z",
  Hard: "M12 2.5l2.2 2.3 3.1-.6.9 3 3 .9-.6 3.1 2.3 2.2-2.3 2.2.6 3.1-3 .9-.9 3-3.1-.6L12 21.5l-2.2-2.3-3.1.6-.9-3-3-.9.6-3.1L1.1 12l2.3-2.2-.6-3.1 3-.9.9-3 3.1.6z",
  Expert: "M12 2.8l2.8 5.9 6.4.8-4.7 4.4 1.2 6.4L12 17.2l-5.7 3.1 1.2-6.4-4.7-4.4 6.4-.8z",
  Master: "M3 8l4.5 3.5L12 5l4.5 6.5L21 8l-2 10H5z",
};

export function LevelSymbol({ level, className }: { level: LevelName; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={className} fill="currentColor">
      <path d={paths[level]} />
    </svg>
  );
}
