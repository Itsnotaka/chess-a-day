const files = ["a", "b", "c", "d", "e", "f", "g", "h"] as const;

const names: Record<string, string> = {
  k: "king", q: "queen", r: "rook", b: "bishop", n: "knight", p: "pawn",
};

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

function label(piece: string): string {
  const white = piece === piece.toUpperCase();
  return `${white ? "white" : "black"} ${names[piece.toLowerCase()]}`;
}

function asset(piece: string): string {
  const white = piece === piece.toUpperCase();
  return `/pieces/${white ? "w" : "b"}${piece.toUpperCase()}.svg`;
}

export function Board({ fen, last = [], caption }: { fen: string; last?: string[]; caption: string }) {
  const cells = squares(fen);
  const position = cells
    .filter((s) => s.piece)
    .map((s) => `${label(s.piece!)} on ${s.name}`)
    .join(", ");
  return (
    <figure className="m-0">
      <div
        role="img"
        aria-label={`${caption}: ${position}.`}
        className="grid aspect-square w-full grid-cols-8 overflow-hidden rounded-board border-2 border-board-edge"
      >
        {cells.map((square, i) => {
          const dark = (Math.floor(i / 8) + (i % 8)) % 2 === 1;
          return (
            <div
              key={square.name}
              className={`relative ${dark ? "bg-board-dark" : "bg-board-light"}`}
            >
              {last.includes(square.name) && <div className="absolute inset-0 bg-board-last" />}
              {square.piece && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={asset(square.piece)} alt="" className="relative h-full w-full" draggable={false} />
              )}
            </div>
          );
        })}
      </div>
      <figcaption className="sr-only">{caption}</figcaption>
    </figure>
  );
}
