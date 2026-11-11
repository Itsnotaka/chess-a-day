// The fallback opponent, for the web dev loop and until Stockfish's module answers:
// one ply with the opponent's best capture taken into account. Deterministic, since
// the data module has no randomness; weaker levels pick worse moves by a hash of the position.
import { Chess } from 'chess.js';

const VALUE: Record<string, number> = { p: 100, n: 320, b: 330, r: 500, q: 900, k: 0 };
const CENTRE = [0, 1, 2, 3, 3, 2, 1, 0];

const material = (chess: Chess, side: 'w' | 'b'): number =>
  chess.board().flat().reduce((total, square, i) => {
    if (!square) return total;
    const placement = square.type === 'p' || square.type === 'n' || square.type === 'b' ? CENTRE[i % 8] * 4 + CENTRE[Math.floor(i / 8)] * 4 : 0;
    const worth = VALUE[square.type] + placement;
    return square.color === side ? total + worth : total - worth;
  }, 0);

const worstReply = (chess: Chess, side: 'w' | 'b'): number => {
  if (chess.isCheckmate()) return 100000;
  if (chess.isDraw() || chess.isStalemate()) return 0;
  const replies = chess.moves({ verbose: true });
  const threat = replies.reduce((most, reply) => {
    if (reply.san.endsWith('#')) return Math.max(most, 100000);
    return reply.captured ? Math.max(most, VALUE[reply.captured]) : most;
  }, 0);
  return material(chess, side) - threat;
};

const hash = (text: string): number =>
  [...text].reduce((h, c) => (Math.imul(h, 31) + c.charCodeAt(0)) >>> 0, 7);

const SLOPPINESS: Record<string, number> = { easy: 3, medium: 6, hard: 14, expert: 40, master: 1000 };

export const fallbackMove = (fen: string, level: string): string => {
  const chess = new Chess(fen);
  const side = chess.turn();
  const scored = chess.moves({ verbose: true }).map((move) => {
    chess.move(move);
    const score = worstReply(chess, side);
    chess.undo();
    return { uci: `${move.from}${move.to}${move.promotion ?? ''}`, score };
  });
  const ranked = [...scored].sort((a, b) => b.score - a.score);
  const roll = hash(fen) % 100;
  const sloppy = roll % (SLOPPINESS[level] ?? 1000) === 0;
  const pick = sloppy ? ranked[hash(`${fen}!`) % ranked.length] : ranked[0];
  return pick.uci;
};
