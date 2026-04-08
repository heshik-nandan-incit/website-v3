import { createReadStream } from "node:fs";
import { access, stat } from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const siteRoot = path.resolve(__dirname, "..", "site");
const port = Number(process.env.PORT || 8000);

const contentTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "application/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".svg", "image/svg+xml"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".webp", "image/webp"],
  [".gif", "image/gif"],
  [".ico", "image/x-icon"],
  [".xml", "application/xml; charset=utf-8"],
  [".txt", "text/plain; charset=utf-8"],
  [".webm", "video/webm"],
  [".mp4", "video/mp4"],
  [".woff", "font/woff"],
  [".woff2", "font/woff2"],
]);

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
    const pathname = decodeURIComponent(url.pathname);
    const filePath = await resolvePath(pathname);

    if (!filePath) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("404 Not Found");
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = contentTypes.get(ext) || "application/octet-stream";
    res.writeHead(200, { "Content-Type": contentType });
    createReadStream(filePath).pipe(res);
  } catch {
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error");
  }
});

server.listen(port, () => {
  console.log(`Serving ${siteRoot} at http://localhost:${port}`);
});

async function resolvePath(requestPath) {
  const normalized = requestPath === "/" ? "/" : requestPath.replace(/\/+$/, "/");
  const candidates = normalized === "/"
    ? [path.join(siteRoot, "index.html")]
    : [
        path.join(siteRoot, normalized, "index.html"),
        path.join(siteRoot, normalized),
      ];

  for (const candidate of candidates) {
    const safePath = path.resolve(candidate);
    if (!safePath.startsWith(siteRoot)) continue;
    try {
      await access(safePath);
      const info = await stat(safePath);
      if (info.isDirectory()) {
        const indexPath = path.join(safePath, "index.html");
        await access(indexPath);
        return indexPath;
      }
      return safePath;
    } catch {
      continue;
    }
  }

  return null;
}
