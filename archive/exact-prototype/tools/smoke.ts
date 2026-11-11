import { answer } from '../app.ts';
const files = new Map<string, Uint8Array>();
const storage: any = { fs: {
  readFile: async (p: string) => { const b = files.get(p); if (!b) throw Object.assign(new Error('nf'), { code: 'ENOENT' }); return b.buffer; },
  atomicWriteFile: async (p: string, d: Uint8Array) => { files.set(p, d); },
} };
const ask = (s: any, a: any[]) => (answer as any)(s, a, {}, storage, null);
const day = '2026-11-11';
let t = Date.UTC(2026, 10, 11, 9);
console.log('new', await ask('newGame', ['white', 'easy', '5+3', t]));
// Scholar's mate attempt against the fallback engine
for (const [f, to] of [['e2','e4'],['f1','c4'],['d1','h5'],['h5','f7']]) {
  const pos = await ask('loadGame', []);
  if (pos.over) break;
  const legal = pos.moves.some((m: any) => m.from === f && m.to === to);
  const r = await ask('playMove', [f, to, '', t += 4000, day]);
  console.log('you', f + to, legal, JSON.stringify(r));
  if (r.engineTurn) console.log('cpu', JSON.stringify(await ask('engineMove', [t += 1000, day])), (await ask('loadGame', [])).lastFrom + (await ask('loadGame', [])).lastTo);
}
const p = await ask('loadGame', []);
console.log({ over: p.over, result: p.result, reason: p.reason, plies: p.plies, check: p.check, whiteMs: p.whiteMs, blackMs: p.blackMs, pieces: p.pieces.length, taken: p.takenByYou, keysUnique: new Set(p.pieces.map((x: any) => x.key)).size });
console.log('summary', JSON.stringify(await ask('loadSummary', [day])));
console.log('strip', JSON.stringify(await ask('dayStrip', [day])));
const b = await ask('newGame', ['black', 'master', 'none', t]);
console.log('black', JSON.stringify(b), (await ask('loadGame', [])).squares.slice(0, 3).map((s: any) => s.id + ':' + s.piece));
const t0 = performance.now(); await ask('engineMove', [t, day]); console.log('engine ms', Math.round(performance.now() - t0));
