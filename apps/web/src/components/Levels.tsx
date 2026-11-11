import { Tabs } from "@base-ui/react/tabs";
import { Buddy } from "@/components/Cast";
import type { LevelName } from "@/components/LevelSymbol";

/** The app's own level names and descriptions (Level.swift), each in its own colour. */
const levels: { name: LevelName; detail: string; tint: string }[] = [
  { name: "Easy", detail: "Learning the moves. The computer misses a lot.", tint: "text-teal" },
  { name: "Medium", detail: "You know the rules and a few tricks.", tint: "text-purple" },
  { name: "Hard", detail: "You play regularly and see tactics coming.", tint: "text-red" },
  { name: "Expert", detail: "Club strength. Few free pieces here.", tint: "text-brown" },
  { name: "Master", detail: "No mercy.", tint: "text-ink" },
];

export function Levels() {
  return (
    <Tabs.Root defaultValue="Medium" className="rounded-card bg-card p-4 shadow-card sm:p-6">
      <Tabs.List activateOnFocus aria-label="Levels" className="grid grid-cols-5 gap-1">
        {levels.map((level) => (
          <Tabs.Tab
            key={level.name}
            value={level.name}
            className="group press flex min-w-0 flex-col items-center gap-2 rounded-row px-1 pt-3 pb-2.5 text-ink-muted outline-offset-0 hover:text-ink data-active:bg-raised data-active:text-ink"
          >
            <Buddy
              level={level.name}
              className="size-12 transition-[translate] duration-200 ease-out group-data-active:-translate-y-1 motion-reduce:transition-none sm:size-16"
            />
            <span className="text-small font-bold max-[339px]:sr-only sm:text-label">{level.name}</span>
          </Tabs.Tab>
        ))}
      </Tabs.List>
      {levels.map((level) => (
        <Tabs.Panel key={level.name} value={level.name} className="px-3 pt-6 pb-3 text-center outline-offset-0 sm:px-6">
          <p className={`text-title font-bold ${level.tint}`}>{level.name}</p>
          <p className="mx-auto mt-2 min-h-[2lh] max-w-[26ch] text-lead font-medium text-balance text-ink-muted">
            {level.detail}
          </p>
        </Tabs.Panel>
      ))}
    </Tabs.Root>
  );
}
