//! Shared repo-list/path resolution, backing every `brigid repos` subcommand.

use std::path::PathBuf;

use anyhow::{Context, Result};
use serde::Deserialize;

#[derive(Deserialize)]
struct ReposFile {
    repos: Vec<String>,
}

/// Absolute path to the `.dev` repo root (baked in at compile time).
pub fn dev_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

/// Absolute path to the directory containing every sibling repo.
pub fn workspace_root() -> PathBuf {
    dev_root()
        .parent()
        .expect("`.dev` must have a parent directory")
        .to_path_buf()
}

/// Sibling repo names from `repos.json`, in declaration order (`.dev` excluded —
/// callers that want `.dev` included should use [`all_repos`]).
pub fn sibling_repo_names() -> Result<Vec<String>> {
    let path = dev_root().join("repos.json");
    let raw =
        std::fs::read_to_string(&path).with_context(|| format!("reading {}", path.display()))?;
    let parsed: ReposFile =
        serde_json::from_str(&raw).with_context(|| format!("parsing {}", path.display()))?;
    Ok(parsed.repos)
}

pub struct Repo {
    pub name: String,
    pub path: PathBuf,
}

pub enum ProjectKind {
    Cargo,
    Pnpm,
    None,
}

impl Repo {
    pub fn kind(&self) -> ProjectKind {
        if self.path.join("Cargo.toml").is_file() {
            ProjectKind::Cargo
        } else if self.path.join("package.json").is_file() {
            ProjectKind::Pnpm
        } else {
            ProjectKind::None
        }
    }

    pub fn is_git_repo(&self) -> bool {
        self.path.join(".git").exists()
    }

    /// Whether this repo's `package.json` declares a `scripts.<name>` entry.
    pub fn has_pnpm_script(&self, name: &str) -> bool {
        let Ok(raw) = std::fs::read_to_string(self.path.join("package.json")) else {
            return false;
        };
        let Ok(value) = serde_json::from_str::<serde_json::Value>(&raw) else {
            return false;
        };
        value
            .get("scripts")
            .and_then(|scripts| scripts.get(name))
            .is_some()
    }
}

/// Every repo brigid operates over: `.dev` itself, then each sibling in `repos.json`.
pub fn all_repos() -> Result<Vec<Repo>> {
    let mut repos = vec![Repo {
        name: ".dev".to_string(),
        path: dev_root(),
    }];
    for name in sibling_repo_names()? {
        let path = workspace_root().join(&name);
        repos.push(Repo { name, path });
    }
    Ok(repos)
}
