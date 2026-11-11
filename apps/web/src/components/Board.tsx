const files = ["a", "b", "c", "d", "e", "f", "g", "h"] as const;

export type Move = { from: string; to: string };

type Square = { name: string; piece: string | null };

function squares(fen: string): Square[] {
  const ranks = fen.split(" ")[0]?.split("/") ?? [];
  return ranks.flatMap((row, r) => {
    const cells: (string | null)[] = [];
    for (const ch of row) {
      if (/\d/.test(ch)) cells.push(...Array<null>(Number(ch)).fill(null));
      else cells.push(ch);
    }
    return cells.map((piece, f) => ({ name: `${files[f]}${8 - r}`, piece }));
  });
}

function asset(piece: string): string {
  const white = piece === piece.toUpperCase();
  return `/pieces/${white ? "w" : "b"}${piece.toUpperCase()}.svg`;
}

function coordinates(square: string): [file: number, rank: number] {
  return [files.indexOf(square[0] as (typeof files)[number]), Number(square[1])];
}

/** A static board with the last move marked. */
export function Board({
  fen,
  move,
  flipped = false,
  label,
}: {
  fen: string;
  move?: Move;
  flipped?: boolean;
  label: string;
}) {
  const cells = squares(fen);
  const ordered = flipped ? cells.toReversed() : cells;
  return (
    <div
      role="img"
      aria-label={label}
      className="grid aspect-square w-full grid-cols-8 overflow-hidden rounded-board border-2 border-board-edge select-none"
    >
      {ordered.map((square) => {
        const [file, rank] = coordinates(square.name);
        const dark = (file + rank) % 2 === 1;
        return (
          <div key={square.name} className={`relative ${dark ? "bg-board-dark" : "bg-board-light"}`}>
            {(move?.from === square.name || move?.to === square.name) && (
              <div className="absolute inset-0 bg-board-last" />
            )}
            {square.piece && (
              // oxlint-disable-next-line nextjs/no-img-element -- tiny static SVGs; next/image adds nothing here
              <img src={asset(square.piece)} alt="" draggable={false} className="relative h-full w-full" />
            )}
          </div>
        );
      })}
    </div>
  );
}
