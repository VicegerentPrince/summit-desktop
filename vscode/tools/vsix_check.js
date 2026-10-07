#!/usr/bin/env node
/*
 * Opens summit-theme-1.0.0.vsix with the same zip reader VS Code uses to
 * install extensions (yauzl, read out of VS Code's node_modules.asar and
 * evaluated in memory), then walks the archive the way the installer does:
 * read extension/package.json, check the engine range, extract everything
 * under extension/ (in memory only) and load the contributed theme.
 *
 * Read-only: nothing is installed, launched, extracted to disk or downloaded.
 *
 *   node tools/vsix_check.js
 */
'use strict';
const fs = require('fs');
const path = require('path');
const Module = require('module');

const APP = process.env.VSCODE_APP || '/usr/share/code/resources/app';
const ROOT = path.join(__dirname, '..');
const VSIX = path.join(ROOT, 'summit-theme-1.0.0.vsix');
const SRC = path.join(ROOT, 'summit-theme');

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
      if (!node) return null;
    }
    const buf = Buffer.alloc(node.size);
    fs.readSync(fd, buf, 0, node.size, base + Number(node.offset));
    return buf;
  };
}

// a tiny CommonJS loader over the asar, enough for yauzl and its two dependencies
function asarRequire(read) {
  const cache = new Map();
  const load = (file) => {
    if (cache.has(file)) return cache.get(file).exports;
    const src = read(file);
    if (!src) throw new Error('not in asar: ' + file);
    const m = new Module(file, null);
    m.filename = file;
    m.paths = [];
    cache.set(file, m);
    const dir = path.posix.dirname(file);
    m.require = (id) => {
      if (id.startsWith('.')) {
        const target = path.posix.join(dir, id);
        return load(read(target) ? target : target + '.js');
      }
      if (Module.builtinModules.includes(id.replace(/^node:/, ''))) return require(id);
      const pkg = JSON.parse(read(id + '/package.json').toString('utf8'));
      return load(path.posix.join(id, pkg.main || 'index.js'));
    };
    const wrapper = Module.wrap(src.toString('utf8'));
    const fn = require('vm').runInThisContext(wrapper, { filename: file });
    fn.call(m.exports, m.exports, m.require, m, file, dir);
    return m.exports;
  };
  return (id) => {
    const pkg = JSON.parse(read(id + '/package.json').toString('utf8'));
    return { exports: load(path.posix.join(id, pkg.main || 'index.js')), version: pkg.version };
  };
}

// VS Code's modeFromEntry()
function modeFromEntry(entry) {
  const attr = entry.externalFileAttributes >> 16 || 33188;
  return [448, 56, 7].map((mask) => attr & mask).reduce((a, b) => a + b, attr & 61440);
}

// the caret-range test VS Code applies to engines.vscode (major must match, minor/patch must not exceed)
function engineSatisfied(range, version) {
  const m = /^\^(\d+)\.(\d+)\.(\d+)$/.exec(range);
  if (!m) return false;
  const want = m.slice(1).map(Number);
  const have = version.split('.').map(Number);
  if (have[0] !== want[0]) return false;
  if (have[1] !== want[1]) return have[1] > want[1];
  return have[2] >= want[2];
}

function readAll(zip, entry) {
  return new Promise((resolve, reject) => {
    zip.openReadStream(entry, (err, stream) => {
      if (err) return reject(err);
      const chunks = [];
      stream.on('data', (c) => chunks.push(c));
      stream.on('end', () => resolve(Buffer.concat(chunks)));
      stream.on('error', reject);
    });
  });
}

async function main() {
  const { exports: yauzl, version } = asarRequire(asarReader(path.join(APP, 'node_modules.asar')))('yauzl');
  console.log('zip reader: yauzl ' + version + ' from ' + APP);

  const zip = await new Promise((resolve, reject) =>
    yauzl.open(VSIX, { lazyEntries: true }, (err, z) => (err ? reject(err) : resolve(z))));
  const entries = [];
  await new Promise((resolve, reject) => {
    zip.on('entry', (entry) => {
      readAll(zip, entry).then((data) => { entries.push({ entry, data }); zip.readEntry(); }, reject);
    });
    zip.on('end', resolve);
    zip.on('error', reject);
    zip.readEntry();
  });

  const problems = [];
  const byName = new Map(entries.map((e) => [e.entry.fileName, e]));
  for (const { entry, data } of entries) {
    const name = entry.fileName;
    const mode = modeFromEntry(entry);
    console.log('  ' + name.padEnd(46) + String(data.length).padStart(7) + ' bytes  mode ' + (mode & 0o777).toString(8)
      + (name.startsWith('extension/') ? '  -> extracted' : '  (not extracted)'));
    if (name.includes('\\') || name.startsWith('/') || name.split('/').includes('..')) problems.push('unsafe entry name: ' + name);
    if (name.startsWith('extension/')) {
      const src = path.join(SRC, name.slice('extension/'.length));
      if (!fs.existsSync(src) || !fs.readFileSync(src).equals(data)) problems.push('differs from source: ' + name);
    }
  }
  for (const required of ['extension.vsixmanifest', '[Content_Types].xml', 'extension/package.json']) {
    if (!byName.has(required)) problems.push('missing ' + required);
  }

  // what the installer does next
  const manifest = JSON.parse(byName.get('extension/package.json').data.toString('utf8'));
  const id = manifest.publisher + '.' + manifest.name;
  if (!/^([a-z0-9A-Z][a-z0-9-A-Z]*)\.([a-z0-9A-Z][a-z0-9-A-Z]*)$/.test(id)) problems.push('invalid extension id ' + id);
  console.log('extension id: ' + id + '   version ' + manifest.version + '   engines.vscode ' + manifest.engines.vscode);
  for (const [label, app] of [['VS Code', '/usr/share/code/resources/app'], ['Cursor', '/usr/share/cursor/resources/app']]) {
    const pj = path.join(app, 'product.json');
    if (!fs.existsSync(pj)) continue;
    const product = JSON.parse(fs.readFileSync(pj, 'utf8'));
    const base = product.vscodeVersion || product.version;
    const ok = engineSatisfied(manifest.engines.vscode, base);
    console.log('  ' + label + ' ' + product.version + ' (VS Code base ' + base + '): engine range ' + (ok ? 'satisfied' : 'NOT satisfied'));
    if (!ok) problems.push('engine range not satisfied by ' + label);
  }
  for (const t of manifest.contributes.themes) {
    const p = 'extension/' + path.posix.normalize(t.path);
    const e = byName.get(p);
    if (!e) { problems.push('theme file not in archive: ' + p); continue; }
    const theme = JSON.parse(e.data.toString('utf8'));
    console.log('theme "' + t.label + '" (' + t.uiTheme + ') -> ' + p + ': type ' + theme.type + ', '
      + Object.keys(theme.colors).length + ' colours, ' + theme.tokenColors.length + ' token rules, '
      + Object.keys(theme.semanticTokenColors).length + ' semantic rules');
    if (t.uiTheme !== 'vs-dark' || theme.type !== 'dark') problems.push('theme type mismatch');
  }

  if (problems.length) {
    console.log('\nFAILED:\n  - ' + problems.join('\n  - '));
    process.exit(1);
  }
  console.log('\nOK: the archive reads cleanly with VS Code\'s zip reader and every extracted file matches the source');
}

main().catch((e) => { console.error('FAILED: ' + (e && e.stack || e)); process.exit(2); });
