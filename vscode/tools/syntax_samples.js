'use strict';
/*
 * Sample source and the Summit syntax mapping each token must resolve to.
 * expect entries: [token text, role, optional font style]. "text#2" means the
 * third token with that exact text. Roles: text bright muted comment prop
 * teal tealb blue purple green amber red.
 */
const F = '```';

module.exports = [
  {
    id: 'typescript',
    scope: 'source.ts',
    code: `// Fetch a user by id
import { z } from "zod";
import type { NextRequest } from "next/server";
export const MAX_RETRIES = 3;
enum Role { Admin = "admin", User = "user" }
interface User { id: number; name?: string; readonly role: Role }
type Result<T> = { ok: true; value: T } | { ok: false; error: Error };
/** Loads a user.
 * @param id the user id
 * @returns {Promise<User>} the user
 */
export async function getUser(id: number, opts: { cache?: boolean } = {}): Promise<User | null> {
  const url = \`https://api.example.com/users/\${id}?v=\${opts.cache ? 1 : 0}\\n\`;
  const res = await fetch(url, { method: "GET" });
  if (!res.ok || res.status === 404) return null;
  const data = (await res.json()) as User;
  console.log(data.name?.toUpperCase(), Math.max(1, 2), JSON.stringify(data));
  return { ...data, role: Role.Admin };
}
class Repo<T extends object> implements Iterable<T> {
  private static instance: Repo<any> | undefined;
  #items = new Map<string, T>();
  constructor(private readonly name: string) { super(); }
  @memoize()
  get size(): number { return this.#items.size; }
  add = (key: string, value: T): void => { this.#items.set(key, value); };
}
const re = /^[a-z]+(\\d{2,})$/gi;
const n = 0xff + 1_000 + 3.14e-2; let flag = true, nothing = null, undef = undefined;
for (const [k, v] of Object.entries(process.env)) { if (typeof v === "string") delete cache[k]; }
function assertNever(x: never): never { throw new Error("unreachable: " + x); }
`,
    expect: [
      ['Fetch a user by id', 'comment', 'italic'],
      ['import', 'purple'], ['from', 'purple'], ['"', 'green'], ['zod', 'green'],
      ['export', 'purple'], ['const', 'purple'], ['MAX_RETRIES', 'text'], ['3', 'amber'], ['=', 'muted'], [';', 'muted'],
      ['enum', 'purple'], ['Role', 'teal'], ['Admin', 'amber'], ['User', 'amber'],
      ['interface', 'purple'], ['User#1', 'teal'], ['id', 'prop'], ['number', 'teal'], ['readonly', 'purple'],
      ['type#1', 'purple'], ['Result', 'teal'], ['true', 'teal'],
      ['@', 'purple', 'italic'], ['param', 'purple', 'italic'], ['Loads a user.', 'comment', 'italic'],
      ['async', 'purple'], ['function', 'purple'], ['getUser', 'blue'], ['id#2', 'text', 'italic'], ['opts', 'text', 'italic'],
      ['Promise', 'teal'], ['null', 'teal'], ['null#1', 'amber'],
      ['url', 'text'], ['${', 'purple'], ['\\n', 'tealb'],
      ['await', 'purple'], ['fetch', 'blue'], ['method', 'prop'],
      ['if', 'purple'], ['return', 'purple'], ['ok#2', 'prop'], ['===', 'muted'], ['404', 'amber'],
      ['as', 'purple'], ['console', 'text'], ['log', 'blue'], ['name#1', 'prop'], ['toUpperCase', 'blue'],
      ['Math', 'text'], ['max', 'blue'], ['JSON', 'text'], ['stringify', 'blue'],
      ['...', 'muted'],
      ['class', 'purple'], ['Repo', 'teal'], ['extends', 'purple'], ['implements', 'purple'], ['Iterable', 'teal'],
      ['private', 'purple'], ['static', 'purple'], ['undefined', 'teal'],
      ['new', 'purple'], ['Map', 'teal'], ['constructor', 'purple'], ['super', 'purple', 'italic'],
      ['@#2', 'amber'], ['memoize', 'amber'],
      ['this', 'purple', 'italic'], ['size', 'blue'], ['size#1', 'prop'], ['#items', 'prop'], ['add', 'blue'],
      ['=>', 'purple'], ['void', 'teal'],
      ['/', 'tealb'], ['^', 'tealb'], ['a-z', 'tealb'], ['+', 'tealb'], ['\\d', 'tealb'], ['{2,}', 'tealb'], ['$', 'tealb'], ['gi', 'tealb'],
      ['0xff', 'amber'], ['1_000', 'amber'], ['14e-2', 'amber'], ['+#1', 'muted'], ['let', 'purple'],
      ['true#1', 'amber'], ['null#2', 'amber'], ['undefined#1', 'amber'],
      ['for', 'purple'], ['of', 'purple'], ['typeof', 'purple'], ['delete', 'purple'], ['entries', 'blue'], ['env', 'prop'],
      ['never', 'teal'], ['throw', 'purple'], ['Error', 'teal'], ['Error#1', 'teal'], ['unreachable:', 'green'],
    ],
  },
  {
    id: 'tsx',
    scope: 'source.tsx',
    code: `"use client";
import Link from "next/link";
import { useState, type ReactNode } from "react";
type Props = { title: string; children?: ReactNode };
export default function Card({ title, children }: Props) {
  const [open, setOpen] = useState<boolean>(false);
  return (
    <section className="card" data-open={open} onClick={() => setOpen(!open)}>
      <h2 id="t">{title} &amp; more</h2>
      <Link href={\`/items/\${title}\`} prefetch>Open</Link>
      {open ? <Panel.Body count={3}>{children}</Panel.Body> : null}
      <input type="text" disabled />
      {/* comment */}
    </section>
  );
}
`,
    expect: [
      ['use client', 'green'], ['default', 'purple'], ['Card', 'blue'], ['title#1', 'text', 'italic'], ['Props#1', 'teal'],
      ['useState#1', 'blue'], ['boolean', 'teal'], ['false', 'amber'],
      ['<', 'muted'], ['section', 'red'], ['className', 'amber'], ['card', 'green'], ['data-open', 'amber'], ['onClick', 'amber'],
      ['setOpen#1', 'blue'], ['h2', 'red'], ['id', 'amber'], ['&', 'tealb'], ['amp', 'tealb'], ['more', 'text'],
      ['Link#1', 'teal'], ['href', 'amber'], ['prefetch', 'amber'], ['Open', 'text'],
      ['Panel.Body', 'teal'], ['count', 'amber'], ['3', 'amber'], ['null', 'amber'],
      ['input', 'red'], ['disabled', 'amber'], ['comment', 'comment', 'italic'], ['>', 'muted'], ['/>', 'muted'],
    ],
  },
  {
    id: 'javascript',
    scope: 'source.js',
    code: `const path = require("node:path");
module.exports = { reactStrictMode: true, images: { domains: ["a.com"] } };
export function debounce(fn, wait = 100) { let t; return (...args) => { clearTimeout(t); t = setTimeout(() => fn.apply(this, args), wait); }; }
class A extends B { static x = 1; async *gen() { yield* super.gen(); } }
`,
    expect: [
      ['const', 'purple'], ['require', 'blue'], ['module', 'text'], ['reactStrictMode', 'prop'], ['true', 'amber'], ['domains', 'prop'],
      ['debounce', 'blue'], ['fn', 'text', 'italic'], ['wait', 'text', 'italic'], ['100', 'amber'], ['args', 'text', 'italic'],
      ['clearTimeout', 'blue'], ['apply', 'blue'], ['A', 'teal'], ['B', 'teal'], ['yield', 'purple'], ['gen', 'blue'],
    ],
  },
  {
    id: 'go',
    scope: 'source.go',
    code: `// Package server exposes the HTTP API.
package server

import (
	"context"
	"fmt"
	"net/http"
)

const DefaultPort = 8080

type Status int

const (
	Active Status = iota
	Disabled
)

// Server handles requests.
type Server struct {
	Addr   string \`json:"addr"\`
	mux    *http.ServeMux
	routes map[string]http.HandlerFunc
}

type Store interface {
	Get(ctx context.Context, id int64) (*User, error)
}

func New(addr string, opts ...Option) *Server {
	s := &Server{Addr: addr, routes: make(map[string]http.HandlerFunc)}
	for i, opt := range opts {
		opt(s)
		_ = i
	}
	return s
}

func (s *Server) Handle(w http.ResponseWriter, r *http.Request) error {
	if r.Method != http.MethodGet || len(s.routes) == 0 {
		return fmt.Errorf("bad method %q: %w", r.Method, ErrBad)
	}
	var total float64 = 3.5
	ok, done := true, make(chan struct{}, 1)
	go func() { defer close(done); total += 1 }()
	select {
	case <-done:
		fmt.Println("done", total, ok, nil)
	default:
	}
	return nil
}
`,
    expect: [
      ['Package server exposes the HTTP API.', 'comment', 'italic'],
      ['package', 'purple'], ['server', 'teal'], ['import', 'purple'], ['context', 'green'], ['const', 'purple'], ['DefaultPort', 'text'], ['8080', 'amber'],
      ['type', 'purple'], ['Status', 'teal'], ['int', 'teal'], ['iota', 'amber'],
      ['Server', 'teal'], ['struct', 'purple'], ['Addr', 'prop'], ['string', 'teal'], ['map', 'purple'],
      ['interface', 'purple'], ['Get', 'blue'], ['int64', 'teal'], ['error', 'teal'],
      ['func', 'purple'], ['New', 'blue'], ['addr', 'text', 'italic'], ['make', 'blue'], [':=', 'muted'],
      ['for', 'purple'], ['range', 'purple'], ['return', 'purple'],
      ['Handle', 'blue'], ['if', 'purple'], ['!=', 'muted'], ['len', 'blue'], ['0', 'amber'],
      ['Errorf', 'blue'], ['%q', 'tealb'], ['bad method', 'green'],
      ['var', 'purple'], ['float64', 'teal'], ['true', 'amber'], ['chan', 'purple'],
      ['go', 'purple'], ['defer', 'purple'], ['close', 'blue'], ['select', 'purple'], ['case', 'purple'],
      ['Println', 'blue'], ['nil', 'amber'], ['default', 'purple'], ['.', 'muted'], ['{', 'muted'],
    ],
  },
  {
    id: 'python',
    scope: 'source.python',
    code: `#!/usr/bin/env python3
"""Module docstring."""
from __future__ import annotations
import os
from dataclasses import dataclass, field
from typing import Optional

MAX_ITEMS: int = 10

@dataclass(frozen=True)
class Item(BaseModel):
    """An item."""
    name: str
    price: float = 0.0
    tags: list[str] = field(default_factory=list)

    @property
    def label(self) -> str:
        return f"{self.name!r}: {self.price:.2f}\\n"

    @classmethod
    def parse(cls, raw: dict, *, strict: bool = False, **extra) -> "Item":
        if raw is None or not isinstance(raw, dict):
            raise ValueError("bad input")
        return cls(name=raw["name"], price=float(raw.get("price", 0)))

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: Optional[str] = None) -> dict:
    items = [x * 2 for x in range(MAX_ITEMS) if x % 2 == 0]
    try:
        result = await fetch(item_id, timeout=5)
    except (KeyError, TimeoutError) as exc:
        print(f"failed: {exc}", file=os.sys.stderr)
        return {"ok": False, "items": None}
    with open(os.path.join("a", "b"), "rb") as fh:
        data = fh.read()
    lambda_fn = lambda a, b=1: a + b
    return {"ok": True, "n": len(items), "re": r"\\d+"}
`,
    expect: [
      ['!/usr/bin/env python3', 'comment', 'italic'], ['Module docstring.', 'comment', 'italic'],
      ['from', 'purple'], ['import', 'purple'], ['int', 'teal'], ['10', 'amber'],
      ['@', 'amber'], ['dataclass#1', 'amber'], ['frozen', 'text', 'italic'], ['True', 'amber'],
      ['class', 'purple'], ['Item', 'teal'], ['BaseModel', 'teal'], ['str', 'teal'], ['float', 'teal'], ['0.0', 'amber'],
      ['property', 'amber'], ['classmethod', 'amber'], ['def', 'purple'], ['label', 'blue'], ['self', 'purple', 'italic'],
      ['return', 'purple'], ['f', 'purple'], ['\\n', 'tealb'], ['price#1', 'prop'],
      ['parse', 'blue'], ['cls', 'purple', 'italic'], ['raw', 'text', 'italic'], ['strict', 'text', 'italic'], ['False', 'amber'],
      ['if', 'purple'], ['is', 'purple'], ['None', 'amber'], ['or', 'purple'], ['not', 'purple'], ['isinstance', 'blue'],
      ['raise', 'purple'], ['ValueError', 'teal'], ['bad input', 'green'],
      ['async', 'purple'], ['read_item', 'blue'], ['item_id', 'text', 'italic'], ['item_id#1', 'text'],
      ['for', 'purple'], ['in', 'purple'], ['range', 'blue'], ['%', 'muted'], ['==', 'muted'],
      ['try', 'purple'], ['await', 'purple'], ['fetch', 'blue'], ['timeout', 'text', 'italic'], ['5', 'amber'],
      ['except', 'purple'], ['KeyError', 'teal'], ['as', 'purple'], ['print', 'blue'],
      ['with', 'purple'], ['open', 'blue'], ['join', 'blue'], ['read', 'blue'], ['lambda', 'purple'], ['len', 'blue'],
      ['\\d', 'tealb'], ['+', 'muted'], ['+#1', 'tealb'],
    ],
  },
  {
    id: 'cpp',
    scope: 'source.cpp',
    code: `// Geometry helpers
#include <iostream>
#include "vec.hpp"
#define SQUARE(x) ((x) * (x))
#ifndef NDEBUG
#endif

namespace geo {

enum class Color : unsigned char { Red, Green = 2 };

template <typename T>
class Vec {
public:
    explicit Vec(std::size_t n) : data_(n), size_{n} {}
    virtual ~Vec() = default;
    T& operator[](std::size_t i) { return data_[i]; }
    [[nodiscard]] constexpr std::size_t size() const noexcept { return size_; }
private:
    std::vector<T> data_;
    std::size_t size_ = 0;
};

struct Point { double x, y; };

static inline double dist(const Point& a, const Point* b) {
    auto dx = a.x - b->x;
    return std::sqrt(SQUARE(dx) + 1.5f);
}

}  // namespace geo

int main(int argc, char** argv) {
    geo::Vec<int> v(3);
    const char* msg = "hello\\n";
    bool ok = true;
    for (auto i = 0u; i < v.size(); ++i) { v[i] = static_cast<int>(i); }
    if (argc > 1 && argv[1] != nullptr) std::cout << msg << 'c' << std::endl;
    try { throw std::runtime_error("x"); } catch (const std::exception& e) { return 1; }
    return ok ? 0 : sizeof(geo::Point);
}
`,
    expect: [
      ['Geometry helpers', 'comment', 'italic'], ['#', 'amber'], ['include', 'amber'], ['iostream', 'green'], ['define', 'amber'], ['SQUARE', 'blue'],
      ['namespace', 'purple'], ['geo', 'teal'], ['enum', 'purple'], ['class', 'purple'], ['Color', 'teal'], ['unsigned', 'teal'], ['char', 'teal'],
      ['Red', 'amber'], ['2', 'amber'],
      ['template', 'purple'], ['typename', 'purple'], ['Vec', 'teal'], ['public', 'purple'], ['explicit', 'purple'],
      ['std', 'teal'], ['::', 'muted'], ['data_', 'prop'], ['virtual', 'purple'], ['return', 'purple'], ['constexpr', 'purple'], ['const', 'purple'], ['noexcept', 'purple'],
      ['&', 'muted'], ['struct', 'purple'], ['Point', 'teal'], ['double', 'teal'], ['static', 'purple'], ['inline', 'purple'], ['dist', 'blue'],
      ['a', 'text', 'italic'], ['auto', 'teal'], ['f', 'amber'], ['sqrt', 'blue'], ['x#4', 'prop'], ['x#5', 'prop'],
      ['int', 'teal'], ['main', 'blue'], ['argc', 'text', 'italic'], ['hello', 'green'], ['\\n', 'tealb'], ['bool', 'teal'], ['true', 'amber'],
      ['for', 'purple'], ['u', 'amber'], ['static_cast', 'purple'], ['if', 'purple'], ['nullptr', 'amber'], ['<<', 'muted'],
      ['try', 'purple'], ['throw', 'purple'], ['catch', 'purple'], ['sizeof', 'purple'], ['nodiscard', 'amber'],
    ],
  },
  {
    id: 'sql',
    scope: 'source.sql',
    code: `-- Monthly revenue
CREATE TABLE IF NOT EXISTS orders (
  id BIGINT PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(id),
  total NUMERIC(10, 2) DEFAULT 0,
  note VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SELECT c.name, COUNT(*) AS n, SUM(o.total) AS revenue
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.created_at >= '2026-01-01' AND o.total > 100 AND c.name LIKE 'A%'
GROUP BY c.name
HAVING COUNT(*) > 5
ORDER BY revenue DESC
LIMIT 10;
UPDATE orders SET total = total * 1.1 WHERE id IN (1, 2, 3) OR note IS NULL;
`,
    expect: [
      ['Monthly revenue', 'comment', 'italic'], ['CREATE', 'purple'], ['TABLE', 'purple'],
      ['BIGINT', 'teal'], ['INT', 'teal'], ['VARCHAR', 'teal'], ['SELECT', 'purple'], ['FROM', 'purple'],
      ['COUNT', 'blue'], ['SUM', 'blue'], ['WHERE', 'purple'], ['2026-01-01', 'green'], ['100', 'amber'],
      ['GROUP BY', 'purple'], ['UPDATE', 'purple'], ['AND', 'purple'], ['=', 'muted'],
    ],
  },
  {
    id: 'shell',
    scope: 'source.shell',
    code: `#!/usr/bin/env bash
set -euo pipefail
# Deploy the app
APP_DIR="\${HOME}/app"
readonly TAG=\${1:-latest}
log() { echo "[$(date +%T)] $*" >&2; }
if [[ -d "$APP_DIR" && $# -gt 0 ]]; then
  cd "$APP_DIR" || exit 1
  for f in *.yaml; do
    kubectl apply -f "$f" --namespace prod | tee -a deploy.log
  done
elif [ -z "\${CI:-}" ]; then
  docker compose up -d --build api
else
  log "nothing to do"; exit 0
fi
count=$((count + 1))
cat <<EOF > out.txt
tag=$TAG
EOF
case "$TAG" in v*) export RELEASE=1 ;; *) unset RELEASE ;; esac
`,
    expect: [
      ['Deploy the app', 'comment', 'italic'], ['set', 'blue'], ['pipefail', 'text'], ['APP_DIR', 'text'], ['if', 'purple'], ['then', 'purple'],
      ['cd', 'blue'], ['exit', 'blue'], ['for', 'purple'], ['do', 'purple'], ['done', 'purple'], ['kubectl', 'blue'],
      ['apply', 'text'], ['-namespace', 'amber'], ['|#2', 'muted'], ['tee', 'blue'], ['docker', 'blue'], ['compose', 'text'],
      ['nothing to do', 'green'], ['fi', 'purple'], ['case', 'purple'], ['esac', 'purple'], ['log#1', 'blue'], ['HOME', 'text'],
    ],
  },
  {
    id: 'json',
    scope: 'source.json',
    code: `{
  "name": "app",
  "version": "1.0.0",
  "private": true,
  "count": 42,
  "ratio": -1.5e3,
  "nothing": null,
  "scripts": { "dev": "next dev --turbo", "esc": "a\\"b\\n" },
  "files": ["a.ts", 1, false]
}
`,
    expect: [
      ['name', 'blue'], ['"#0', 'blue'], ['app', 'green'], [':', 'muted'], ['true', 'amber'], ['42', 'amber'], ['null', 'amber'],
      ['dev', 'blue'], ['next dev --turbo', 'green'], ['\\n', 'tealb'], ['false', 'amber'], [',', 'muted'], ['{', 'muted'],
    ],
  },
  {
    id: 'jsonc',
    scope: 'source.json.comments',
    code: `{
  // editor settings
  "editor.fontSize": 14, /* block */
  "files.exclude": { "**/.git": true }
}
`,
    expect: [
      ['editor settings', 'comment', 'italic'], ['editor.fontSize', 'blue'], ['14', 'amber'], ['**/.git', 'blue'], ['true', 'amber'],
    ],
  },
  {
    id: 'yaml',
    scope: 'source.yaml',
    code: `# Compose file
version: "3.9"
services:
  api:
    image: ghcr.io/acme/api:1.2.3
    build: { context: ., dockerfile: Dockerfile }
    ports:
      - "8080:8080"
      - 9090
    environment: &env
      DEBUG: true
      RETRIES: 3
      EMPTY: null
      NAME: plain text value
    command: ["npm", "run", "start"]
    healthcheck:
      test: >
        curl -f http://localhost
  worker:
    <<: *env
    deploy: !!map { replicas: 2 }
---
key: 'single'
`,
    expect: [
      ['Compose file', 'comment', 'italic'], ['version', 'blue'], ['3.9', 'green'], ['services', 'blue'], ['image', 'blue'],
      ['ghcr.io/acme/api:1.2.3', 'green'], ['9090', 'amber'], ['true', 'amber'], ['3', 'amber'], ['null', 'amber'],
      ['plain text value', 'green'], ['npm', 'green'], [':', 'muted'], ['-', 'muted'], ['single', 'green'], ['replicas', 'blue'],
      ['env', 'teal'], ['env#1', 'teal'], ['---', 'muted'],
    ],
  },
  {
    // No TOML grammar ships with VS Code or Cursor. These are the scope stacks produced by the
    // common TOML extensions (taplo "Even Better TOML", and the older "Better TOML").
    id: 'toml (synthetic scopes)',
    scope: 'source.summit-synthetic',
    code: `[source.toml comment.line.number-sign.toml]comment
[source.toml meta.table.toml punctuation.definition.table.toml]bracket
[source.toml meta.table.toml support.type.property-name.table.toml]tool.poetry
[source.toml meta.array.table.toml support.type.property-name.array.toml]servers
[source.toml meta.entry.toml support.type.property-name.toml]name
[source.toml meta.entry.toml punctuation.eq.toml]=
[source.toml meta.entry.toml string.quoted.single.basic.line.toml]app
[source.toml meta.entry.toml string.quoted.single.basic.line.toml constant.character.escape.toml]\\n
[source.toml meta.entry.toml constant.language.boolean.toml]true
[source.toml meta.entry.toml constant.numeric.integer.dec.toml]8000
[source.toml meta.entry.toml constant.numeric.float.toml]1.5
[source.toml meta.entry.toml constant.other.time.datetime.offset.toml]2026-10-05T10:00:00Z
[source.toml keyword.key.toml]oldkey
[source.toml entity.other.attribute-name.table.toml]oldtable
[source.toml constant.other.boolean.toml]false
`,
    expect: [
      ['comment', 'comment', 'italic'], ['bracket', 'muted'], ['tool.poetry', 'blue'], ['servers', 'blue'], ['name', 'blue'], ['=', 'muted'],
      ['app', 'green'], ['\\n', 'tealb'], ['true', 'amber'], ['8000', 'amber'], ['1.5', 'amber'], ['2026-10-05T10:00:00Z', 'amber'],
      ['oldkey', 'blue'], ['oldtable', 'blue'], ['false', 'amber'],
    ],
  },
  {
    id: 'markdown',
    scope: 'text.html.markdown',
    code: `# Summit theme

Some **bold text**, some *italic text*, ***both***, ~~gone~~ and \`inline code\`.

## Links

A [link text](https://example.com "title") and ![image](pic.png), plus <https://auto.link>
and a [reference][ref].

[ref]: https://example.com/ref

> A quoted line
> with more

- first item
- [ ] todo item
1. numbered

| a | b |
|---|---|
| 1 | 2 |

---

${F}ts
const x: number = 1;
${F}

${F}unknownlang
plain fenced text
${F}

    indented code

Setext heading
==============
`,
    expect: [
      ['#', 'blue', 'bold'], ['Summit theme', 'blue', 'bold'], ['bold text', 'bright', 'bold'], ['italic text', 'text', 'italic'],
      ['both', 'bright', 'italic bold'], ['gone', 'muted', 'strikethrough'], ['inline code', 'green'],
      ['Links', 'blue', 'bold'], ['link text', 'teal'], ['https://example.com', 'teal', 'underline'], ['title', 'green'],
      ['A quoted line', 'muted', 'italic'], ['-', 'purple'], ['1.', 'purple'],
      ['const', 'purple'], ['x', 'text'], ['number', 'teal'], ['1#1', 'amber'],
      ['plain fenced text', 'green'], ['indented code', 'green'], ['==============', 'blue', 'bold'],
    ],
  },
  {
    id: 'dockerfile',
    scope: 'source.dockerfile',
    code: `# syntax=docker/dockerfile:1
FROM node:22-alpine AS build
ARG NODE_ENV=production
ENV PORT=3000 \\
    HOST="0.0.0.0"
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
RUN npm ci && npm run build
EXPOSE 3000
HEALTHCHECK --interval=30s CMD curl -f http://localhost:3000 || exit 1
ENTRYPOINT ["node", "server.js"]
`,
    expect: [
      ['syntax=docker/dockerfile:1', 'comment', 'italic'], ['FROM', 'purple'], ['AS', 'purple'], ['ARG', 'purple'], ['ENV', 'purple'],
      ['WORKDIR', 'purple'], ['COPY', 'purple'], ['RUN', 'purple'], ['EXPOSE', 'purple'], ['ENTRYPOINT', 'purple'],
      ['0.0.0.0', 'green'], ['node', 'green'],
    ],
  },
  {
    id: 'html',
    scope: 'text.html.derivative',
    code: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Summit &amp; friends</title>
  <style>
    body { margin: 0; color: #dce3ea; }
  </style>
  <script type="module">
    const el = document.querySelector("#app");
  </script>
</head>
<body class="dark" data-x='1'>
  <!-- a comment -->
  <a href="/docs" target="_blank" hidden>Docs</a>
  <my-widget some-attr></my-widget>
  <br/>
</body>
</html>
`,
    expect: [
      ['html#1', 'red'], ['lang', 'amber'], ['en', 'green'], ['<', 'muted'], ['meta', 'red'], ['charset', 'amber'], ['title', 'red'],
      ['&', 'tealb'], ['amp', 'tealb'], ['style', 'red'], ['body', 'teal'], ['margin', 'blue'], ['0', 'amber'], ['color', 'blue'], ['#', 'amber'], ['dce3ea', 'amber'],
      ['script', 'red'], ['type', 'amber'], ['const', 'purple'], ['querySelector', 'blue'], ['#app', 'green'],
      ['class', 'amber'], ['dark', 'green'], ['a comment', 'comment', 'italic'],
      ['a', 'red'], ['href', 'amber'], ['hidden', 'amber'], ['Docs', 'text'], ['my-widget', 'red'], ['br', 'red'], ['=', 'muted'],
    ],
  },
  {
    id: 'css',
    scope: 'source.css',
    code: `@import url("base.css");
:root { --accent: #4fd1c5; --gap: 1.5rem; }
/* layout */
html, body.dark > main#app .card:hover::before, a[href^="http"], * {
  display: flex;
  margin: 0 auto 12px -0.5em;
  color: var(--accent, rgb(79 209 197 / 80%));
  background: url(img/bg.png) no-repeat, linear-gradient(90deg, #171c23 0%, transparent);
  font: italic 600 14px/1.4 "Inter", sans-serif;
  transition: opacity 200ms ease-in-out !important;
  width: calc(100% - 2 * var(--gap));
  -webkit-font-smoothing: antialiased;
}
@media (min-width: 768px) and (prefers-color-scheme: dark) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
@keyframes fade { from { opacity: 0; } 50% { opacity: .5; } to { opacity: 1; } }
`,
    expect: [
      ['@', 'purple'], ['import', 'purple'], ['url', 'blue'], ['base.css', 'green'], ['layout', 'comment', 'italic'],
      ['--accent', 'text'], ['#', 'amber'], ['4fd1c5', 'amber'], ['1.5', 'amber'], ['rem', 'purple'],
      ['html', 'teal'], ['body', 'teal'], ['dark', 'teal'], ['main', 'teal'], ['app', 'teal'], ['card', 'teal'], ['hover', 'teal'], ['before', 'teal'],
      ['a', 'teal'], ['display', 'blue'], ['flex', 'amber'], ['margin', 'blue'], ['0', 'amber'], ['auto', 'amber'], ['12', 'amber'], ['px', 'purple'], ['em', 'purple'],
      ['color', 'blue'], ['var', 'blue'], ['rgb', 'blue'], ['79', 'amber'], ['%', 'purple'],
      ['img/bg.png', 'green'], ['no-repeat', 'amber'], ['linear-gradient', 'blue'], ['deg', 'purple'], ['transparent', 'amber'],
      ['italic', 'amber'], ['600', 'amber'], ['Inter', 'green'], ['sans-serif', 'amber'],
      ['ms', 'purple'], ['ease-in-out', 'amber'], ['!important', 'purple'], ['calc', 'blue'], ['antialiased', 'amber'],
      ['media', 'purple'], ['min-width', 'blue'], ['768', 'amber'], ['and', 'purple'], ['grid', 'teal'], ['repeat', 'blue'], ['fr', 'purple'],
      ['keyframes', 'purple'], ['fade', 'text'], ['from', 'teal'], ['to', 'teal'], [';', 'muted'], ['{', 'muted'],
    ],
  },
  {
    id: 'scss',
    scope: 'source.css.scss',
    code: `@use "sass:math";
$radius: 4px;
@mixin card($pad: 8px) { padding: $pad; border-radius: $radius; }
.btn { @include card(12px); &:hover { color: darken($accent, 10%); } &--primary { @extend %base; } }
`,
    expect: [
      ['use', 'purple'], ['$radius', 'text'], ['4', 'amber'], ['px', 'purple'], ['mixin', 'purple'], ['card', 'blue'],
      ['padding', 'blue'], ['btn', 'teal'], ['include', 'purple'], ['hover', 'teal'], ['darken', 'blue'], ['extend', 'purple'],
    ],
  },
  {
    id: 'c',
    scope: 'source.c',
    code: `#include <stdio.h>
#define MAX 10
typedef struct node { int value; struct node *next; } node_t;
static int sum(const int *xs, size_t n) {
  int total = 0;
  for (size_t i = 0; i < n; i++) total += xs[i];
  return total > MAX ? MAX : total; /* clamp */
}
int main(void) { printf("%d\\n", sum(NULL, 0)); return 0; }
`,
    expect: [
      ['include', 'amber'], ['stdio.h', 'green'], ['define', 'amber'], ['typedef', 'purple'], ['struct', 'purple'], ['int', 'teal'],
      ['static', 'purple'], ['sum', 'blue'], ['const', 'purple'], ['size_t', 'teal'], ['0', 'amber'], ['for', 'purple'], ['return', 'purple'],
      ['clamp', 'comment', 'italic'], ['printf', 'blue'], ['%d', 'tealb'], ['\\n', 'tealb'], ['NULL', 'amber'], ['void', 'teal'],
    ],
  },
  {
    id: 'rust',
    scope: 'source.rust',
    code: `use std::collections::HashMap;
/// A point.
#[derive(Debug, Clone)]
pub struct Point { pub x: f64, y: f64 }
impl Point {
    pub fn new(x: f64, y: f64) -> Self { Self { x, y } }
    fn len(&self) -> f64 { (self.x * self.x + self.y.powi(2)).sqrt() }
}
fn main() {
    let mut map: HashMap<&str, i32> = HashMap::new();
    map.insert("a", 1);
    if let Some(v) = map.get("a") { println!("{} {:?}", v, true); }
    let n = 0xff_u8 as usize;
}
`,
    expect: [
      ['use', 'purple'], ['HashMap', 'teal'], ['A point.', 'comment', 'italic'], ['derive', 'amber'], ['pub', 'purple'], ['struct', 'purple'], ['Point', 'teal'],
      ['f64', 'teal'], ['impl', 'purple'], ['fn', 'purple'], ['new', 'blue'], ['Self', 'purple', 'italic'], ['self', 'purple', 'italic'],
      ['let', 'purple'], ['mut', 'purple'], ['i32', 'teal'], ['insert', 'blue'], ['a', 'green'], ['1', 'amber'], ['if', 'purple'],
      ['println!', 'blue'], ['true', 'amber'], ['as', 'purple'], ['usize', 'teal'],
    ],
  },
  {
    id: 'java',
    scope: 'source.java',
    code: `package com.acme.app;
import java.util.List;
/** Service. */
@Service
public final class UserService implements Runnable {
    private static final int MAX = 10;
    private final List<String> names;
    public UserService(List<String> names) { this.names = names; }
    @Override
    public void run() {
        for (String n : names) { if (n != null && n.length() > MAX) System.out.println("long: " + n); }
        boolean ok = true; double d = 1.5e3;
    }
}
`,
    expect: [
      ['package', 'purple'], ['import', 'purple'], ['Service.', 'comment', 'italic'], ['Service', 'amber'], ['public', 'purple'], ['final', 'purple'],
      ['class', 'purple'], ['UserService', 'teal'], ['implements', 'purple'], ['Runnable', 'teal'], ['int', 'teal'], ['10', 'amber'],
      ['String', 'teal'], ['this', 'purple', 'italic'], ['Override', 'amber'], ['void', 'teal'], ['run', 'blue'], ['for', 'purple'],
      ['null', 'amber'], ['length', 'blue'], ['println', 'blue'], ['long:', 'green'], ['boolean', 'teal'], ['true', 'amber'], ['double', 'teal'],
    ],
  },
  {
    id: 'csharp',
    scope: 'source.cs',
    code: `using System;
namespace Acme.App {
    public record Item(string Name, decimal Price);
    public class Store : IDisposable {
        private readonly List<Item> _items = new();
        public int Count => _items.Count;
        [Obsolete("use AddAsync")]
        public async Task<bool> Add(Item item, int qty = 1) {
            if (item is null) throw new ArgumentNullException(nameof(item));
            await Task.Delay(10); return true;
        }
    }
}
`,
    expect: [
      ['using', 'purple'], ['namespace', 'purple'], ['public', 'purple'], ['record', 'purple'], ['Item', 'teal'], ['string', 'teal'], ['decimal', 'teal'],
      ['class', 'purple'], ['Store', 'teal'], ['IDisposable', 'teal'], ['readonly', 'purple'], ['new', 'purple'], ['int', 'teal'],
      ['Obsolete', 'teal'], ['use AddAsync', 'green'], ['async', 'purple'], ['bool', 'teal'], ['Add', 'blue'], ['item', 'text', 'italic'],
      ['if', 'purple'], ['is', 'purple'], ['null', 'amber'], ['throw', 'purple'], ['await', 'purple'], ['Delay', 'blue'], ['10', 'amber'], ['true', 'amber'],
    ],
  },
  {
    id: 'php',
    scope: 'text.html.php',
    code: `<?php
namespace App\\Models;
use Illuminate\\Support\\Str;
final class User extends Model {
    public const ROLE = 'admin';
    protected ?string $name = null;
    public function greet(string $who, int $times = 1): string {
        // say hi
        return sprintf("Hi %s, %d", $who, $times) . Str::upper($this->name);
    }
}
`,
    expect: [
      ['namespace', 'purple'], ['use', 'purple'], ['final', 'purple'], ['class', 'purple'], ['User', 'teal'], ['extends', 'purple'], ['Model', 'teal'],
      ['public', 'purple'], ['const', 'purple'], ['admin', 'green'], ['null', 'amber'], ['function', 'purple'], ['greet', 'blue'],
      ['say hi', 'comment', 'italic'], ['return', 'purple'], ['sprintf', 'blue'], ['string', 'teal'], ['int', 'teal'], ['upper', 'blue'], ['1', 'amber'], ['this', 'purple', 'italic'], ['$#5', 'purple', 'italic'],
    ],
  },
  {
    id: 'ruby',
    scope: 'source.ruby',
    code: `# frozen_string_literal: true
require "json"
module Billing
  class Invoice < Base
    attr_reader :total
    def initialize(total, tax: 0.2)
      @total = total * (1 + tax)
    end
    def to_s = "Total: #{@total.round(2)}"
  end
end
puts Billing::Invoice.new(100).to_s if true && !nil
`,
    expect: [
      ['frozen_string_literal: true', 'comment', 'italic'], ['require', 'purple'], ['json', 'green'], ['module', 'purple'], ['Billing', 'teal'],
      ['class', 'purple'], ['Invoice', 'teal'], ['Base', 'teal'], ['def', 'purple'], ['initialize', 'blue'], ['0.2', 'amber'],
      ['end', 'purple'], ['Total:', 'green'], ['100', 'amber'], ['if', 'purple'], ['true', 'amber'], ['nil', 'amber'],
    ],
  },
  {
    id: 'log',
    scope: 'text.log',
    code: `2026-10-05 16:42:10.123 [info] Server listening on http://localhost:3000
2026-10-05 16:42:11.456 [warning] Deprecated option "legacy" used in config.json:12
2026-10-05 16:42:12.789 [error] TypeError: Cannot read properties of undefined (reading 'id')
    at getUser (/app/src/user.ts:42:17)
2026-10-05 16:42:13.001 [debug] cache hit key=user:42 ttl=300 ok=true
[trace] verbose detail 0x1f null
`,
    expect: [
      ['[info]', 'blue'], ['[warning]', 'amber'], ['[error]', 'red'], ['[debug]', 'purple'],
      ['2026-10-05', 'comment'], ['trace', 'comment'], ['"legacy"', 'green'], ['300', 'amber'], ['at', 'muted'],
    ],
  },
  {
    id: 'makefile',
    scope: 'source.makefile',
    code: `# Build targets
BIN := bin/app
.PHONY: build test
build: $(BIN)
	go build -o $(BIN) ./cmd/app
test:
	@go test ./... -race
`,
    expect: [
      ['Build targets', 'comment', 'italic'], ['BIN', 'text'], ['build', 'blue'],
    ],
  },
  {
    id: 'git-commit',
    scope: 'text.git-commit',
    code: `Add connected tab strip colour for the Modern UI and tidy up the log level mapping too
second line should be blank

Body text explaining the change.
# Please enter the commit message for your changes. Lines starting
# On branch main
#	modified:   themes/summit-color-theme.json
`,
    expect: [
      ['Body text explaining the change.', 'text'], ['el mapping too', 'red'], ['modified:   themes/summit-color-theme.json', 'amber', 'italic'],
    ],
  },
  {
    id: 'git-rebase',
    scope: 'text.git-rebase',
    code: `pick 1a2b3c4 Add theme
squash 5d6e7f8 Fix contrast
# Rebase 0000000..5d6e7f8 onto 0000000
`,
    expect: [
      ['pick', 'blue'], ['1a2b3c4', 'amber'], ['Add theme', 'text'],
    ],
  },
  {
    id: 'diff',
    scope: 'source.diff',
    code: `diff --git a/a.ts b/a.ts
index 83db48f..bf2a7ef 100644
--- a/a.ts
+++ b/a.ts
@@ -1,3 +1,4 @@
 context
-removed line
+added line
`,
    expect: [
      ['removed line', 'red'], ['added line', 'green'], ['-', 'red'], ['+', 'green'], ['---', 'red'], ['+++', 'green'], ['@@', 'purple'], ['context', 'text'],
    ],
  },
  {
    id: 'dotenv',
    scope: 'source.dotenv',
    code: `# Database
DATABASE_URL="postgres://user:pass@localhost:5432/db"
PORT=3000
export DEBUG=true
`,
    expect: [
      ['# Database', 'comment', 'italic'], ['DATABASE_URL', 'blue'], ['PORT', 'blue'],
    ],
  },
  {
    id: 'ini',
    scope: 'source.ini',
    code: `; comment
[section]
key = value
name="quoted"
`,
    expect: [
      ['comment', 'comment', 'italic'], ['key', 'blue'], ['section', 'blue'], ['quoted', 'green'],
    ],
  },
];
