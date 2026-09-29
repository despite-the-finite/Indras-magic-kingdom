#!/usr/bin/env node
// Minimal static server for the web build (correct MIME for .wasm/.pck, optional COOP/COEP for threaded exports).
//   node tools/dev/serve.mjs [dir=build/web] [port=8080]
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { join, extname, resolve } from 'node:path';

const dir = resolve(process.argv[2] ?? 'build/web');
const port = Number(process.argv[3] ?? 8080);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };

createServer(async (req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (p.endsWith('/')) p += 'index.html';
  const file = join(dir, p);
  if (!file.startsWith(dir)) { res.writeHead(403).end(); return; }
  try {
    await stat(file);
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': types[extname(file)] ?? 'application/octet-stream', 'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp', 'Cache-Control': 'no-store' });
    res.end(data);
  } catch { res.writeHead(404).end('not found'); }
}).listen(port, () => console.log(`serving ${dir} on http://localhost:${port}`));
