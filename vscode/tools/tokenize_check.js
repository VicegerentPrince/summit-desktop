#!/usr/bin/env node
/*
 * Tokenises sample source with the real TextMate grammars that ship with the
 * installed VS Code, resolves every token through the Summit theme with the
 * same library VS Code uses (vscode-textmate + vscode-oniguruma), and checks
 * the colours against the Summit syntax mapping.
 *
 * Read-only: nothing is launched, installed, written or downloaded. The two
 * libraries are read out of VS Code's node_modules.asar and evaluated in
 * memory.
 *
 *   node tools/tokenize_check.js            run all assertions
 *   node tools/tokenize_check.js --dump     also print every sample, coloured by role name
 *   node tools/tokenize_check.js --dump ts  only samples whose id contains "ts" ("=c" matches the id exactly)
 *   node tools/tokenize_check.js --scopes   with --dump, print the scope stack of each token
 *   node tools/tokenize_check.js --json     print the coloured tokens of every sample as JSON
 */
'use strict';
const fs = require('fs');
const path = require('path');
const Module = require('module');

const APP = process.env.VSCODE_APP || '/usr/share/code/resources/app';
const THEME = path.join(__dirname, '..', 'summit-theme', 'themes', 'summit-color-theme.json');
const SAMPLES = require('./syntax_samples.js');

const argv = process.argv.slice(2);
const DUMP = argv.includes('--dump');
const SCOPES = argv.includes('--scopes');
const JSON_OUT = argv.includes('--json');   // machine-readable tokens, used by preview.py
const FILTER = argv.filter((x) => !x.startsWith('--'))[0];

// ---- read a file out of an asar archive without unpacking it -------------
function asarReader(file) {
  const fd = fs.openSync(file, 'r');
  const head = Buffer.alloc(16);
  fs.readSync(fd, head, 0, 16, 0);
  const headerSize = head.readUInt32LE(4);
  const jsonLen = head.readUInt32LE(12);
  const json = Buffer.alloc(jsonLen);
  fs.readSync(fd, json, 0, jsonLen, 16);
  const header = JSON.parse(json.toString('utf8'));
  const base = 8 + headerSize;
  return (p) => {
    let node = header;
    for (const part of p.split('/')) {
      node = node.files && node.files[part];
      if (!node) throw new Error('not in asar: ' + p);
    }
    const buf = Buffer.alloc(node.size);
    fs.readSync(fd, buf, 0, node.size, base + Number(node.offset));
    return buf;
  };
}

function loadModuleFromSource(source, name) {
  const m = new Module(name, null);
  m.filename = name;
  m.paths = [];
  m._compile(source, name);
  return m.exports;
}

const ROLE_NAMES = {
  '#dce3ea': 'text', '#f0f4f8': 'BRIGHT', '#8693a1': 'muted', '#6e7a88': 'comment',
  '#c5cfd9': 'prop', '#4fd1c5': 'TEAL', '#81e6d9': 'teal+', '#7cb7ff': 'BLUE',
  '#b9a3f5': 'PURPLE', '#84cc6a': 'GREEN', '#e3b341': 'AMBER', '#f47067': 'RED',
};
const ROLE_HEX = {
  text: '#dce3ea', bright: '#f0f4f8', muted: '#8693a1', comment: '#6e7a88', prop: '#c5cfd9',
  teal: '#4fd1c5', tealb: '#81e6d9', blue: '#7cb7ff', purple: '#b9a3f5', green: '#84cc6a',
  amber: '#e3b341', red: '#f47067',
};

async function main() {
  const read = asarReader(path.join(APP, 'node_modules.asar'));
  const vsctm = loadModuleFromSource(read('vscode-textmate/release/main.js').toString('utf8'), 'vscode-textmate.js');
  const onig = loadModuleFromSource(read('vscode-oniguruma/release/main.js').toString('utf8'), 'vscode-oniguruma.js');
  const wasm = fs.readFileSync(path.join(APP, 'node_modules.asar.unpacked/vscode-oniguruma/release/onig.wasm'));
  await onig.loadWASM(wasm.buffer.slice(wasm.byteOffset, wasm.byteOffset + wasm.byteLength));

  // grammar index from the built-in extensions
  const grammars = new Map();     // scopeName -> { path, embeddedLanguages, tokenTypes }
  const injections = new Map();   // scopeName -> [injected scopeName]
  const extDirs = [path.join(APP, 'extensions')].concat((process.env.EXTRA_EXT_DIRS || '').split(':').filter(Boolean));
  for (const extDir of extDirs) {
    for (const ext of fs.readdirSync(extDir)) {
      const pj = path.join(extDir, ext, 'package.json');
      if (!fs.existsSync(pj)) continue;
      let pkg;
      try { pkg = JSON.parse(fs.readFileSync(pj, 'utf8')); } catch { continue; }
      for (const g of (pkg.contributes && pkg.contributes.grammars) || []) {
        if (!g.scopeName || !g.path) continue;
        if (!grammars.has(g.scopeName)) grammars.set(g.scopeName, { path: path.join(extDir, ext, g.path), language: g.language });
        for (const target of g.injectTo || []) {
          if (!injections.has(target)) injections.set(target, []);
          injections.get(target).push(g.scopeName);
        }
      }
    }
  }

  // Synthetic grammar: "[scope.a scope.b]token" yields a token carrying exactly that scope stack.
  // Used for languages whose grammar does not ship with the editor.
  const SYNTHETIC = 'source.summit-synthetic';
  const syntheticGrammar = JSON.stringify({
    scopeName: SYNTHETIC,
    patterns: [{ match: '\\[([^\\]]+)\\](.+)$', captures: { 2: { name: '$1' } } }],
  });
  grammars.set(SYNTHETIC, { path: null });

  const theme = JSON.parse(fs.readFileSync(THEME, 'utf8'));
  const rawTheme = {
    name: theme.name,
    settings: [{ settings: { foreground: theme.colors['editor.foreground'], background: theme.colors['editor.background'] } }]
      .concat(theme.tokenColors),
  };

  const registry = new vsctm.Registry({
    onigLib: Promise.resolve({
      createOnigScanner: (patterns) => new onig.OnigScanner(patterns),
      createOnigString: (s) => new onig.OnigString(s),
    }),
    loadGrammar: async (scopeName) => {
      const g = grammars.get(scopeName);
      if (!g) return null;
      if (scopeName === SYNTHETIC) return vsctm.parseRawGrammar(syntheticGrammar, 'synthetic.json');
      return vsctm.parseRawGrammar(fs.readFileSync(g.path, 'utf8'), g.path);
    },
    getInjections: (scopeName) => injections.get(scopeName) || [],
  });
  registry.setTheme(rawTheme);
  const colorMap = registry.getColorMap().map((c) => (c ? c.toLowerCase() : c));

  let failures = 0;
  let checks = 0;
  const jsonResult = {};
  const missing = [];
  for (const sample of SAMPLES) {
    if (FILTER && (FILTER.startsWith('=') ? sample.id !== FILTER.slice(1) : !sample.id.includes(FILTER))) continue;
    if (!grammars.has(sample.scope)) { missing.push(sample.id + ' (' + sample.scope + ')'); continue; }
    const grammar = await registry.loadGrammar(sample.scope);
    const lines = sample.code.replace(/\n$/, '').split('\n');
    let stack = vsctm.INITIAL;
    let stack2 = vsctm.INITIAL;
    const tokens = [];   // { text, color, style, scopes, line }
    lines.forEach((line, ln) => {
      const r1 = grammar.tokenizeLine(line, stack);
      const r2 = grammar.tokenizeLine2(line, stack2);
      stack = r1.ruleStack; stack2 = r2.ruleStack;
      const meta = [];
      for (let i = 0; i < r2.tokens.length; i += 2) meta.push([r2.tokens[i], r2.tokens[i + 1]]);
      for (const t of r1.tokens) {
        let m = meta[0][1];
        for (const [start, md] of meta) { if (start <= t.startIndex) m = md; else break; }
        const fg = (m & 0x00ff8000) >>> 15;
        const fs_ = (m & 0x00007800) >>> 11;
        const style = [(fs_ & 1) && 'italic', (fs_ & 2) && 'bold', (fs_ & 4) && 'underline', (fs_ & 8) && 'strikethrough'].filter(Boolean).join(' ');
        tokens.push({ text: line.slice(t.startIndex, t.endIndex), color: colorMap[fg], style, scopes: t.scopes, line: ln });
      }
    });

    if (JSON_OUT) {
      const out = lines.map(() => []);
      for (const t of tokens) out[t.line].push({ text: t.text, color: t.color, style: t.style });
      jsonResult[sample.id] = out;
    }
    if (DUMP) {
      console.log('\n=== ' + sample.id + '  [' + sample.scope + '] ' + '='.repeat(Math.max(0, 50 - sample.id.length)));
      let ln = -1; let out = '';
      for (const t of tokens) {
        if (t.line !== ln) { if (ln >= 0) console.log(out); out = ''; ln = t.line; }
        if (!t.text.trim()) { out += t.text; continue; }
        const role = ROLE_NAMES[t.color] || t.color;
        out += t.text + '‹' + role + (t.style ? ',' + t.style : '') + '›';
        if (SCOPES) out += '\n      ' + t.scopes.join('  ') + '\n';
      }
      console.log(out);
    }

    for (const exp of (JSON_OUT ? [] : sample.expect || [])) {
      const [needle, role, style] = exp;
      let nth = 0; let text = needle;
      const mm = /^(.*)#(\d+)$/s.exec(needle);
      if (mm) { text = mm[1]; nth = Number(mm[2]); }
      const hits = tokens.filter((t) => t.text.trim() === text);
      checks++;
      if (hits.length <= nth) {
        failures++;
        console.log('FAIL ' + sample.id + ': no token ' + JSON.stringify(text) + ' (occurrence ' + nth + ')');
        continue;
      }
      const t = hits[nth];
      const want = ROLE_HEX[role];
      const wantStyle = style || '';
      if (t.color !== want || t.style !== wantStyle) {
        failures++;
        console.log('FAIL ' + sample.id + ': ' + JSON.stringify(text) + ' is ' + (ROLE_NAMES[t.color] || t.color) + (t.style ? ' ' + t.style : '')
          + ', expected ' + role + (wantStyle ? ' ' + wantStyle : '') + '\n       scopes: ' + t.scopes.join('  '));
      }
    }
  }
  if (JSON_OUT) { console.log(JSON.stringify(jsonResult)); process.exit(0); }
  console.log('\n' + checks + ' syntax assertions, ' + failures + ' failed' + (missing.length ? '; no built-in grammar for: ' + missing.join(', ') : ''));
  process.exit(failures ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(2); });
