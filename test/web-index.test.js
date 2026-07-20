import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const config = JSON.parse(readFileSync("project.config.json", "utf8"))
const index = JSON.parse(readFileSync("web/src/lib/practices-index.json", "utf8"))

test("web index contains exactly the formal practices", () => {
  assert.deepEqual(index.practices.map(({ slug }) => slug).sort(), [...config.formal.practices].sort())
})
