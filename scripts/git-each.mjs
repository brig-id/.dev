#!/usr/bin/env node
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { readRepos, readRoot } from "./repos.mjs";

const root = readRoot();
const repos = [".dev", ...readRepos()];
const args = process.argv.slice(2);

if (args.length === 0) {
  console.error("Usage: node scripts/git-each.mjs <git-args...>");
  process.exit(2);
}

let failed = 0;

for (const repo of repos) {
  const cwd = repo === ".dev" ? root : resolve(root, "..", repo);
  if (!existsSync(resolve(cwd, ".git"))) {
    console.warn(`⚠️  ${repo}: not a git repo (skipped)`);
    continue;
  }

  console.log(`\n━━━ ${repo} — git ${args.join(" ")} ━━━`);
  const result = spawnSync("git", ["--no-pager", ...args], {
    cwd,
    stdio: "inherit"
  });

  if (result.status !== 0) {
    failed++;
  }
}

process.exit(failed ? 1 : 0);
