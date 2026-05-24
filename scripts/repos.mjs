#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, "..");
const reposPath = resolve(root, "repos.json");

export function readRepos() {
  const raw = JSON.parse(readFileSync(reposPath, "utf8"));
  if (!Array.isArray(raw.repos)) {
    throw new Error("repos.json must contain a repos array");
  }

  return raw.repos;
}

export function readRoot() {
  return root;
}
