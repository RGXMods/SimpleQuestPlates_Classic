import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { basename } from "node:path";
import vm from "node:vm";

const source = readFileSync(new URL("./publish-release.mjs", import.meta.url), "utf8");
const start = source.indexOf("async function publishCurseForge(");
const end = source.indexOf("// ── Wago", start);
assert.ok(start >= 0 && end > start);
let uploaded = false;
const context = vm.createContext({
  FormData, Blob, basename,
  console: { log() {}, warn() {} },
  readFileSync: () => Buffer.from("fixture archive"),
  CF_GAME_TYPE_ID: new Map([["classic", 67408]]),
  fail: (message) => { throw new Error(message); },
  fetchWithRetry: async (url, options) => {
    if (url.endsWith("/versions")) {
      return { ok: true, json: async () => [{ gameVersionTypeID: 67408, name: "11509", id: 42 }] };
    }
    assert.equal(options.method, "POST");
    const metadata = options.body.get("metadata");
    assert.equal(typeof metadata, "string", "CurseForge metadata must be a text field, not a file part (HTTP 400/1001)");
    assert.deepEqual(JSON.parse(metadata).gameVersions, [42]);
    assert.equal(JSON.parse(metadata).releaseType, "release");
    const wire = await new Request(url, { method: "POST", body: options.body }).text();
    assert.match(wire, /name="metadata"\r\n\r\n/);
    assert.doesNotMatch(wire, /name="metadata"; filename=/);
    assert.equal(options.body.get("file").name, "fixture.zip");
    uploaded = true;
    return { status: 200 };
  },
});
vm.runInContext(source.slice(start, end), context);
await context.publishCurseForge({
  projectId: "1600794", apiKey: "fixture-not-a-secret",
  flavors: [{ flavor: "classic", interface: 11509 }],
  version: "1.9.10-classic.2", releaseType: "release", changelog: "fixture", archive: "fixture.zip",
});
assert.ok(uploaded);
console.log("PASS: production publisher sends metadata as a multipart text field and archive as a file");
