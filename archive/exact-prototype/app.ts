// The data module: the game on disk, every position the view draws, the computer's
// replies and the day strip. The view never computes chess; it asks here.
import { Chess, type Move as ChessMove } from 'chess.js';
import type { Answer, Result, Sources, Storage, NativeModule } from './app.contract.d.ts';
import { fallbackMove } from './engine.ts';

const GAME = 'app:/data/game.json';
const HISTORY = 'app:/data/history.json';

export const grants = [
  'fs.read app:/data/game.json',
  'fs.write app:/data/game.json',
  'fs.read app:/data/history.json',
  'fs.write app:/data/history.json',
].join('\n');

type Side = 'w' | 'b';
type Position = Result<'loadGame'>;
type Reply = Result<'newGame'>;

type Saved = {
  moves: string[];
  you: Side;
  level: string;
  timeControl: string;
  startedAt: number;
  lastMoveAt: number;
  whiteMs: number;
  blackMs: number;
  ended: '' | 'resign' | 'flag';
  loser: '' | Side;
  recorded: boolean;
};

type History = { days: Record<string, { game: boolean; puzzle: boolean }> };

const VALUE: Record<string, number> = { p: 1, n: 3, b: 3, r: 5, q: 9, k: 0 };
const FILES = 'abcdefgh';

const decode = (bytes: ArrayBuffer) => JSON.parse(new TextDecoder().decode(bytes));
const encode = (value: unknown) => new TextEncoder().encode(JSON.stringify(value));

const readJson = <T>(storage: Storage, path: string, fallback: T): Promise<T> =>
  storage.fs.readFile(path).then(decode, (e) => {
    if (e.code === 'ENOENT') return fallback;
    throw e;
  });

const loadSaved = (storage: Storage) => readJson<Saved | null>(storage, GAME, null);
const saveGame = (storage: Storage, saved: Saved) => storage.fs.atomicWriteFile(GAME, encode(saved));
const loadHistory = (storage: Storage) => readJson<History>(storage, HISTORY, { days: {} });

const ok = (engineTurn: boolean): Reply => ({ ok: true, engineTurn, error: '' });
const refuse = (error: string): Reply => ({ ok: false, engineTurn: false, error });

const clockOf = (timeControl: string) => {
  const [minutes, increment] = timeControl.split('+').map(Number);
  return timeControl === 'none' ? null : { baseMs: minutes * 60000, incrementMs: increment * 1000 };
};

const replay = (saved: Saved | null) => {
  const chess = new Chess();
  const history = (saved?.moves ?? []).map((uci) =>
    chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci.slice(4) || undefined }));
  return { chess, history };
};

const ending = (chess: Chess, saved: Saved | null) => {
  if (saved?.ended === 'resign') return { over: true, loser: saved.loser, reason: 'Resigned' };
  if (saved?.ended === 'flag') return { over: true, loser: saved.loser, reason: 'Out of time' };
  if (chess.isCheckmate()) return { over: true, loser: chess.turn(), reason: 'Checkmate' };
  if (chess.isStalemate()) return { over: true, loser: '', reason: 'Stalemate' };
  if (chess.isThreefoldRepetition()) return { over: true, loser: '', reason: 'Threefold repetition' };
  if (chess.isInsufficientMaterial()) return { over: true, loser: '', reason: 'Insufficient material' };
  if (chess.isDraw()) return { over: true, loser: '', reason: 'Fifty-move rule' };
  return { over: false, loser: '', reason: '' };
};

/** Each piece keeps the key of the square it started on, so the view can slide it. */
const pieceKeys = (history: ChessMove[]) => {
  const start = new Chess();
  const keys = new Map<string, string>(
    start.board().flat().flatMap((square) => (square ? [[square.square, `${square.color}${square.type}-${square.square}`] as const] : [])));
  history.forEach((move) => {
    const key = keys.get(move.from) ?? move.from;
    const taken = move.flags.includes('e') ? `${move.to[0]}${move.from[1]}` : move.to;
    keys.delete(taken);
    keys.delete(move.from);
    keys.set(move.to, key);
    if (move.flags.includes('k') || move.flags.includes('q')) {
      const rank = move.from[1];
      const [rookFrom, rookTo] = move.flags.includes('k') ? [`h${rank}`, `f${rank}`] : [`a${rank}`, `d${rank}`];
      keys.set(rookTo, keys.get(rookFrom) ?? rookFrom);
      keys.delete(rookFrom);
    }
  });
  return keys;
};

const displayIndex = (square: string, you: Side) => {
  const file = FILES.indexOf(square[0]);
  const rank = Number(square[1]);
  return you === 'w' ? (8 - rank) * 8 + file : (rank - 1) * 8 + (7 - file);
};

const squareAt = (index: number, you: Side) => {
  const row = Math.floor(index / 8);
  const col = index % 8;
  return you === 'w' ? `${FILES[col]}${8 - row}` : `${FILES[7 - col]}${row + 1}`;
};

const taken = (history: ChessMove[], by: Side) =>
  history
    .filter((move) => move.color === by && move.captured)
    .map((move) => `${by === 'w' ? 'b' : 'w'}${(move.captured ?? 'p').toUpperCase()}`)
    .sort((a, b) => VALUE[b[1].toLowerCase()] - VALUE[a[1].toLowerCase()])
    .map((code, i, all) => ({ key: `${code}${all.slice(0, i).filter((c) => c === code).length}`, code }));

const toPosition = (saved: Saved | null): Position => {
  const { chess, history } = replay(saved);
  const you: Side = saved?.you ?? 'w';
  const end = ending(chess, saved);
  const keys = pieceKeys(history);
  const yourTurn = Boolean(saved) && !end.over && chess.turn() === you;
  const last = history.at(-1);
  const king = chess.board().flat().find((square) => square?.type === 'k' && square.color === chess.turn());
  const squares = Array.from({ length: 64 }, (_, index) => {
    const id = squareAt(index, you);
    const piece = chess.get(id as Parameters<Chess['get']>[0]);
    const file = FILES.indexOf(id[0]);
    const rank = Number(id[1]);
    return {
      id,
      index,
      light: (file + rank) % 2 === 0,
      piece: piece ? `${piece.color}${piece.type.toUpperCase()}` : '',
      file: Math.floor(index / 8) === 7 ? id[0] : '',
      rank: index % 8 === 0 ? id[1] : '',
    };
  });
  const pieces = chess.board().flat().flatMap((square) => square
    ? [{ key: keys.get(square.square) ?? square.square, code: `${square.color}${square.type.toUpperCase()}`, index: displayIndex(square.square, you) }]
    : []);
  return {
    active: Boolean(saved),
    over: end.over,
    you,
    turn: chess.turn(),
    level: saved?.level ?? 'medium',
    squares,
    pieces,
    moves: yourTurn ? chess.moves({ verbose: true }).map((move) => ({ from: move.from, to: move.to, promotion: move.promotion ?? '' })) : [],
    check: chess.inCheck() && king ? king.square : '',
    lastFrom: last?.from ?? '',
    lastTo: last?.to ?? '',
    result: !end.over ? '' : end.loser === '' ? 'draw' : end.loser === you ? 'loss' : 'win',
    reason: end.reason,
    plies: history.length,
    timed: Boolean(saved && clockOf(saved.timeControl)),
    whiteMs: saved?.whiteMs ?? 0,
    blackMs: saved?.blackMs ?? 0,
    lastMoveAt: saved?.lastMoveAt ?? 0,
    startedAt: saved?.startedAt ?? 0,
    takenByYou: taken(history, you),
    takenByThem: taken(history, you === 'w' ? 'b' : 'w'),
  };
};

/** Applies one move with its clock, saves it, and records a finished game once. */
const commit = async (storage: Storage, saved: Saved, chess: Chess, uci: string, at: number, day: string): Promise<Reply> => {
  const mover = chess.turn();
  const played = (() => {
    try {
      return chess.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci.slice(4) || undefined });
    } catch {
      return null;
    }
  })();
  if (!played) return refuse('That move is not legal here.');
  const clock = clockOf(saved.timeControl);
  const spent = clock && saved.moves.length > 0 ? at - saved.lastMoveAt : 0;
  const bonus = clock && saved.moves.length > 0 ? clock.incrementMs : 0;
  const next: Saved = {
    ...saved,
    moves: [...saved.moves, uci],
    lastMoveAt: at,
    whiteMs: mover === 'w' ? saved.whiteMs - spent + bonus : saved.whiteMs,
    blackMs: mover === 'b' ? saved.blackMs - spent + bonus : saved.blackMs,
  };
  const over = ending(chess, next).over;
  await saveGame(storage, over ? await record(storage, next, day) : next);
  return ok(!over && chess.turn() !== next.you);
};

const record = async (storage: Storage, saved: Saved, day: string): Promise<Saved> => {
  if (saved.recorded) return saved;
  const history = await loadHistory(storage);
  const today = history.days[day] ?? { game: false, puzzle: false };
  await storage.fs.atomicWriteFile(HISTORY, encode({ days: { ...history.days, [day]: { ...today, game: true } } }));
  return { ...saved, recorded: true };
};

const finish = async (storage: Storage, how: 'resign' | 'flag', at: number, day: string): Promise<Reply> => {
  const saved = await loadSaved(storage);
  if (!saved) return refuse('There is no game to end.');
  const { chess } = replay(saved);
  if (ending(chess, saved).over) return refuse('The game is already over.');
  const loser: Side = how === 'resign' ? saved.you : chess.turn();
  await saveGame(storage, await record(storage, { ...saved, ended: how, loser, lastMoveAt: at }, day));
  return ok(false);
};

const askEngine = async (fen: string, level: string, native?: NativeModule | null): Promise<string> => {
  if (!native?.available) return fallbackMove(fen, level);
  const reply = await native.later({ op: 'bestmove', fen, level }).catch(() => null);
  return typeof reply?.move === 'string' && reply.move.length >= 4 ? reply.move : fallbackMove(fen, level);
};

const dayKey = (ms: number) => new Date(ms).toISOString().slice(0, 10);
const utcMidnight = (key: string) => Date.UTC(Number(key.slice(0, 4)), Number(key.slice(5, 7)) - 1, Number(key.slice(8, 10)));
const weekday = (style: 'short' | 'long') => new Intl.DateTimeFormat('en-US', { weekday: style, timeZone: 'UTC' });
const monthDay = new Intl.DateTimeFormat('en-US', { month: 'long', day: 'numeric', timeZone: 'UTC' });

const streak = (history: History, today: string) => {
  const counted = (key: string) => history.days[key]?.game === true && history.days[key]?.puzzle === true;
  const end = counted(today) ? utcMidnight(today) : utcMidnight(today) - 86400000;
  const run = (ms: number, n: number): number => (counted(dayKey(ms)) ? run(ms - 86400000, n + 1) : n);
  return run(end, 0);
};

const sources: Sources = {
  loadGame: async (_args, _store, storage) => toPosition(await loadSaved(storage)),

  newGame: async ([side, level, timeControl, at], _store, storage) => {
    const you: Side = side === 'white' ? 'w' : side === 'black' ? 'b' : Math.floor(at / 1000) % 2 === 0 ? 'w' : 'b';
    const clock = clockOf(timeControl);
    await saveGame(storage, {
      moves: [], you, level, timeControl, startedAt: at, lastMoveAt: at,
      whiteMs: clock?.baseMs ?? 0, blackMs: clock?.baseMs ?? 0, ended: '', loser: '', recorded: false,
    });
    return ok(you === 'b');
  },

  playMove: async ([from, to, promotion, at, day], _store, storage) => {
    const saved = await loadSaved(storage);
    if (!saved) return refuse('There is no game in progress.');
    const { chess } = replay(saved);
    if (ending(chess, saved).over) return refuse('The game is over.');
    if (chess.turn() !== saved.you) return refuse('It is the computer\'s move.');
    return commit(storage, saved, chess, `${from}${to}${promotion}`, at, day);
  },

  engineMove: async ([at, day], _store, storage, native) => {
    const saved = await loadSaved(storage);
    if (!saved) return refuse('There is no game in progress.');
    const { chess } = replay(saved);
    if (ending(chess, saved).over || chess.turn() === saved.you) return refuse('It is not the computer\'s move.');
    const uci = await askEngine(chess.fen(), saved.level, native);
    return commit(storage, saved, chess, uci, at, day);
  },

  resignGame: ([at, day], _store, storage) => finish(storage, 'resign', at, day),
  flagGame: ([at, day], _store, storage) => finish(storage, 'flag', at, day),

  loadSummary: async ([today], _store, storage) => {
    const history = await loadHistory(storage);
    return {
      streak: streak(history, today),
      days: Object.entries(history.days).map(([day, marks]) => ({ day, game: marks.game, puzzle: marks.puzzle })),
    };
  },

  dayStrip: ([today]) => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(today)) return [];
    const base = utcMidnight(today);
    return [-3, -2, -1, 0, 1].map((offset) => {
      const ms = base + offset * 86400000;
      const date = new Date(ms);
      return {
        key: dayKey(ms),
        short: weekday('short').format(date),
        long: weekday('long').format(date),
        monthDay: monthDay.format(date),
        number: String(date.getUTCDate()),
        future: offset > 0,
      };
    });
  },
};

export const answer: Answer = (source, args, store, storage, native) => sources[source](args, store, storage, native);
