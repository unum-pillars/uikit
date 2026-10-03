// A tiny static server for the demo page, so nothing but Node (and so, Docker) is needed.
// Serves the repo root, so the page can reach ../dist.
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'
import { extname, join, normalize } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))
const port = Number(process.env.PORT ?? 8080)
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.map': 'application/json' }

createServer(async (request, response) => {
  const requested = normalize(new URL(request.url, 'http://localhost').pathname).replace(/^(\.\.[/\\])+/, '')
  const path = requested === '/' ? '/demo/index.html' : requested

  if (!/^\/(demo|dist)\//.test(path)) {
    response.writeHead(404)
    response.end('not found')
    return
  }

  try {
    const body = await readFile(join(root, path))
    response.writeHead(200, { 'content-type': types[extname(path)] ?? 'application/octet-stream' })
    response.end(body)
  } catch {
    response.writeHead(404)
    response.end('not found')
  }
}).listen(port, '0.0.0.0', () => console.log(`unum uikit demo on http://localhost:${process.env.PUBLIC_PORT ?? port}`))

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => process.exit(0))
}
