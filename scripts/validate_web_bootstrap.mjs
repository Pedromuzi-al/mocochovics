import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';

const source = (await readFile(new URL('../web/flutter_bootstrap.js', import.meta.url), 'utf8'))
  .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');

async function boot({failLoad = false, failEngine = false} = {}) {
  const nodes = Object.fromEntries(['app-startup', 'startup-message', 'startup-retry']
    .map(id => [id, {hidden: id === 'startup-retry', textContent: '', addEventListener() {}}]));
  const listeners = new Map();
  let timer, ran = false, loaderConfig;
  vm.runInNewContext(source, {
    document: {baseURI: 'http://localhost:3000/bar/', getElementById: id => nodes[id]},
    URL,
    window: {addEventListener: (event, callback) => listeners.set(event, callback), location: {reload() {}}},
    console: {error() {}}, setTimeout: callback => { timer = callback; return 1; }, clearTimeout() {},
    _flutter: {loader: {load: async options => {
      loaderConfig = options.config;
      if (failLoad) throw new Error('Network unavailable');
      await options.onEntrypointLoaded({initializeEngine: async () => {
        if (failEngine) throw new Error('Renderer unavailable');
        return {runApp: async () => { ran = true; }};
      }});
    }}},
  });
  await new Promise(resolve => setImmediate(resolve));
  return {nodes, listeners, timeout: () => timer(), ran, loaderConfig};
}

const successful = await boot();
assert(successful.ran);
assert.equal(successful.loaderConfig.canvasKitBaseUrl, 'http://localhost:3000/bar/canvaskit/');
assert.equal(successful.nodes['app-startup'].hidden, false);
successful.listeners.get('flutter-first-frame')();
assert.equal(successful.nodes['app-startup'].hidden, true);
successful.timeout();
assert.equal(successful.nodes['startup-retry'].hidden, true);

for (const failure of [{failLoad: true}, {failEngine: true}]) {
  const result = await boot(failure);
  assert.equal(result.ran, false);
  assert.equal(result.nodes['startup-retry'].hidden, false);
  assert.match(result.nodes['startup-message'].textContent, /Não foi possível/);
}

const delayed = await boot();
delayed.timeout();
assert.equal(delayed.nodes['startup-retry'].hidden, false);
assert.match(delayed.nodes['startup-message'].textContent, /mais tempo/);
delayed.listeners.get('flutter-first-frame')();
assert.equal(delayed.nodes['app-startup'].hidden, true);
console.log('PASS: startup, first frame, network/engine failures and delayed recovery.');
