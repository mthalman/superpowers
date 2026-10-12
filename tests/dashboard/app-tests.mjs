import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const root = dirname(fileURLToPath(import.meta.url));
const source = readFileSync(join(root, '..', '..', 'dashboard', 'assets', 'app.js'), 'utf8');
const sandbox = { window: {}, console };
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(source, sandbox);
const D = sandbox.window.SuperpowersDashboard;

let passed = 0;
let failed = 0;
function test(name, action) {
  try {
    action();
    passed++;
    console.log('  ok  ' + name);
  } catch (error) {
    failed++;
    console.error('  FAIL ' + name + ': ' + error.message);
  }
}

test('parseJsonl ignores blanks and malformed rows', function () {
  const rows = D.parseJsonl('{"a":1}\n\nbad\n{"b":2}\n');
  assert.equal(rows.length, 2);
  assert.equal(rows[1].b, 2);
});

test('passRate reads only successful Vally rows', function () {
  assert.equal(D.passRate({ status: 'ok', metrics: { pass_rate: 0.75 } }), 0.75);
  assert.equal(D.passRate({ status: 'error', metrics: { pass_rate: 1 } }), null);
});

test('computeBiggestDrop uses pass-rate percentage points', function () {
  const drop = D.computeBiggestDrop([
    { status: 'ok', metrics: { pass_rate: 0.9 }, short_sha: 'a' },
    { status: 'error', metrics: { pass_rate: 0 }, short_sha: 'b' },
    { status: 'ok', metrics: { pass_rate: 0.5 }, short_sha: 'c' },
    { status: 'ok', metrics: { pass_rate: 0.6 }, short_sha: 'd' },
  ], 10);
  assert.equal(drop.delta, -0.4);
  assert.equal(drop.short_sha, 'c');
});

test('builds commit and workflow URLs', function () {
  assert.equal(D.buildCommitUrl('owner/repo', 'abc'), 'https://github.com/owner/repo/commit/abc');
  assert.equal(D.buildRunUrl('owner/repo', '123'), 'https://github.com/owner/repo/actions/runs/123');
  assert.equal(D.buildRunUrl('owner/repo', 'local-20261007'), null);
});

test('validates skill names and allowlists', function () {
  assert.equal(D.validateSkillName('code-review', ['code-review']), true);
  assert.equal(D.validateSkillName('../secret', ['code-review']), false);
  assert.equal(D.validateSkillName('other', ['code-review']), false);
});

test('formats percentages and deltas', function () {
  assert.equal(D.formatPercent(0.875), '87.5%');
  assert.equal(D.formatPercent(null), '—');
  assert.equal(D.formatDelta(-0.125), '▼ -12.5 pp');
  assert.equal(D.deltaClass(0.1), 'delta-up');
  assert.equal(D.statusClass('regression'), 'status-regression');
});

test('sparkline paths break across error gaps', function () {
  const result = D.buildSparklinePath([0.5, 0.75, null, 1], 200, 36);
  assert.equal((result.path.match(/M/g) || []).length, 2);
});

console.log('');
console.log(passed + ' passed, ' + failed + ' failed');
if (failed) process.exit(1);
