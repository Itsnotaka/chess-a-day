import { levelPaths, type LevelName } from "@/components/LevelSymbol";

/**
 * The cast: each level's symbol from the app, given a face, plus a pawn who waves.
 * Purely decorative; every figure is hidden from assistive tech.
 */

type Face = { x: number; y: number; eyes: "face" | "on-ink"; brows?: boolean };

const levels: Record<LevelName, { fill: string; face: Face; legs?: [number, number, number] }> = {
  Easy: { fill: "fill-teal", face: { x: 12, y: 11.6, eyes: "face" }, legs: [9.5, 14.5, 19] },
  Medium: { fill: "fill-purple", face: { x: 12, y: 11.5, eyes: "face" }, legs: [10, 14, 19.6] },
  Hard: { fill: "fill-red", face: { x: 12, y: 12, eyes: "face", brows: true }, legs: [10, 14, 20.6] },
  Expert: { fill: "fill-brown", face: { x: 12, y: 12.8, eyes: "face" } },
  Master: { fill: "fill-ink", face: { x: 12, y: 13.4, eyes: "on-ink" }, legs: [9, 15, 18] },
};

function FaceMarks({ face, scale = 1 }: { face: Face; scale?: number }) {
  const { x, y } = face;
  const ink = face.eyes === "face" ? "fill-face stroke-face" : "fill-on-ink stroke-on-ink";
  const s = scale;
  return (
    <g className={ink}>
      <circle cx={x - 3.3 * s} cy={y + 1.6 * s} r={1 * s} className="fill-blush stroke-none" opacity={0.55} />
      <circle cx={x + 3.3 * s} cy={y + 1.6 * s} r={1 * s} className="fill-blush stroke-none" opacity={0.55} />
      <g className="buddy-eyes stroke-none">
        <ellipse cx={x - 2.1 * s} cy={y} rx={0.85 * s} ry={1.25 * s} />
        <ellipse cx={x + 2.1 * s} cy={y} rx={0.85 * s} ry={1.25 * s} />
      </g>
      <path
        d={`M${x - 1.2 * s} ${y + 2 * s}q${1.2 * s} ${1 * s} ${2.4 * s} 0`}
        fill="none"
        strokeWidth={0.7 * s}
        strokeLinecap="round"
      />
      {face.brows && (
        <path
          d={`M${x - 3.2 * s} ${y - 2.5 * s}l${1.7 * s} ${0.7 * s}M${x + 3.2 * s} ${y - 2.5 * s}l${-1.7 * s} ${0.7 * s}`}
          fill="none"
          strokeWidth={0.7 * s}
          strokeLinecap="round"
        />
      )}
    </g>
  );
}

export function Buddy({
  level,
  className = "",
  style,
}: {
  level: LevelName;
  className?: string;
  style?: React.CSSProperties;
}) {
  const { fill, face, legs } = levels[level];
  return (
    <svg viewBox="1 1 22 23" aria-hidden="true" className={`overflow-visible ${className}`} style={style}>
      {legs && (
        <path
          d={`M${legs[0]} ${legs[2] - 0.5}l-0.6 3.2M${legs[1]} ${legs[2] - 0.5}l0.6 3.2`}
          className="stroke-ink"
          fill="none"
          strokeWidth={1.2}
          strokeLinecap="round"
        />
      )}
      <path d={levelPaths[level]} className={fill} />
      <FaceMarks face={face} />
    </svg>
  );
}

/** A pawn, black (ink) or white, that waves when it arrives. */
export function Pawn({
  tone = "ink",
  wave = false,
  className = "",
  style,
}: {
  tone?: "ink" | "light";
  wave?: boolean;
  className?: string;
  style?: React.CSSProperties;
}) {
  const body = tone === "ink" ? "fill-ink" : "fill-card stroke-ink";
  const face: Face = { x: 60, y: 40, eyes: tone === "ink" ? "on-ink" : "face" };
  return (
    <svg viewBox="0 0 120 146" aria-hidden="true" className={`overflow-visible ${className}`} style={style}>
      <path d="M40 94q-12 5-18 17" className="stroke-ink" fill="none" strokeWidth={5} strokeLinecap="round" />
      <path
        d="M80 92q12-6 17-22"
        className={`stroke-ink ${wave ? "buddy-wave" : ""}`}
        style={{ transformBox: "view-box", transformOrigin: "80px 92px" }}
        fill="none"
        strokeWidth={5}
        strokeLinecap="round"
      />
      <g className={body} strokeWidth={4} strokeLinejoin="round">
        <path d="M42 74c2 22-6 38-14 48h64c-8-10-16-26-14-48z" />
        <rect x="18" y="120" width="84" height="20" rx="10" />
        <rect x="34" y="62" width="52" height="13" rx="6.5" />
        <circle cx="60" cy="38" r="25" />
      </g>
      <FaceMarks face={face} scale={4.6} />
    </svg>
  );
}

type Spot = { left: string; top: string; width: string; rotate?: number; delay: number };
type Bit = "square" | "sparkle" | "dot";
type Member = ({ kind: "pawn" } | { kind: "level"; level: LevelName } | { kind: "bit"; bit: Bit; tint: string }) & Spot;

const bits: Record<Bit, string> = {
  square: "M6 2h12a4 4 0 0 1 4 4v12a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V6a4 4 0 0 1 4-4z",
  sparkle: "M12 1c.9 6.2 4.8 10.1 11 11-6.2.9-10.1 4.8-11 11-.9-6.2-4.8-10.1-11-11 6.2-.9 10.1-4.8 11-11z",
  dot: "M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20z",
};

function Place({ member }: { member: Member }) {
  const style = {
    left: member.left,
    top: member.top,
    width: member.width,
    rotate: member.rotate ? `${member.rotate}deg` : undefined,
    "--delay": `${member.delay}ms`,
  } as React.CSSProperties;
  if (member.kind === "pawn") return <Pawn wave className="buddy absolute h-auto" style={style} />;
  if (member.kind === "level") return <Buddy level={member.level} className="buddy absolute h-auto" style={style} />;
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className={`buddy absolute h-auto ${member.tint}`} style={style}>
      <path d={bits[member.bit]} />
    </svg>
  );
}

// Positions are percentages of each cluster's box, so the cast scales with the column.
const left: Member[] = [
  { kind: "bit", bit: "sparkle", tint: "fill-brown", left: "58%", top: "2%", width: "8%", delay: 420 },
  { kind: "bit", bit: "square", tint: "fill-ink-faint", left: "84%", top: "20%", width: "7%", rotate: 14, delay: 480 },
  { kind: "level", level: "Easy", left: "2%", top: "4%", width: "34%", rotate: -10, delay: 120 },
  { kind: "pawn", left: "30%", top: "16%", width: "50%", delay: 0 },
  { kind: "bit", bit: "dot", tint: "fill-red", left: "8%", top: "58%", width: "6%", delay: 520 },
  { kind: "bit", bit: "sparkle", tint: "fill-teal", left: "16%", top: "76%", width: "9%", delay: 560 },
  { kind: "level", level: "Medium", left: "66%", top: "64%", width: "30%", rotate: 8, delay: 220 },
  { kind: "bit", bit: "square", tint: "fill-purple", left: "44%", top: "86%", width: "6%", rotate: -12, delay: 600 },
];

const right: Member[] = [
  { kind: "bit", bit: "square", tint: "fill-teal", left: "16%", top: "6%", width: "6%", rotate: 10, delay: 440 },
  { kind: "level", level: "Hard", left: "38%", top: "0%", width: "38%", rotate: 10, delay: 160 },
  { kind: "bit", bit: "sparkle", tint: "fill-purple", left: "86%", top: "30%", width: "8%", delay: 500 },
  { kind: "level", level: "Expert", left: "4%", top: "36%", width: "38%", rotate: -8, delay: 260 },
  { kind: "bit", bit: "dot", tint: "fill-brown", left: "56%", top: "46%", width: "5%", delay: 540 },
  { kind: "level", level: "Master", left: "50%", top: "58%", width: "40%", rotate: 4, delay: 340 },
  { kind: "bit", bit: "sparkle", tint: "fill-red", left: "20%", top: "82%", width: "8%", delay: 600 },
  { kind: "bit", bit: "square", tint: "fill-ink-faint", left: "90%", top: "88%", width: "6%", rotate: -8, delay: 640 },
];

const row: Member[] = [
  { kind: "level", level: "Easy", left: "0%", top: "34%", width: "17%", rotate: -10, delay: 120 },
  { kind: "bit", bit: "sparkle", tint: "fill-brown", left: "19%", top: "2%", width: "5%", delay: 420 },
  { kind: "level", level: "Medium", left: "19%", top: "20%", width: "15%", rotate: 8, delay: 200 },
  { kind: "pawn", left: "38%", top: "0%", width: "24%", delay: 0 },
  { kind: "level", level: "Hard", left: "65%", top: "4%", width: "17%", rotate: 10, delay: 260 },
  { kind: "level", level: "Master", left: "83%", top: "40%", width: "17%", rotate: -6, delay: 320 },
  { kind: "bit", bit: "square", tint: "fill-teal", left: "90%", top: "6%", width: "4%", rotate: 12, delay: 460 },
];

export function Cast({ side }: { side: "left" | "right" | "row" }) {
  const members = side === "left" ? left : side === "right" ? right : row;
  // Side clusters spill past their column, like a crowd at the edge of the page.
  const box =
    side === "row"
      ? "aspect-[5/2] w-full"
      : side === "left"
        ? "aspect-[4/5] w-[125%] -ml-[25%]"
        : "aspect-[4/5] w-[125%]";
  return (
    <div aria-hidden="true" className={`relative ${box}`}>
      {members.map((member, i) => (
        <Place key={i} member={member} />
      ))}
    </div>
  );
}
