{
  pkgs,
  getExe,
  ...
}:
{ globals, ... }:
let
  zathura = getExe pkgs.zathura;
  sqlite = getExe pkgs.sqlite;
in
pkgs.writers.writeRustBin "last_zathura" {
  rustcArgs = [
    "--edition"
    "2021"
  ];
} ''
  use std::collections::{HashMap, HashSet};
  use std::error::Error;
  use std::ffi::OsStr;
  use std::io::Write;
  use std::path::{Path, PathBuf};
  use std::process::{Command, Stdio};

  const DMENU: &str = "${globals.dmenu}";
  const ZATHURA: &str = "${zathura}";
  const SQLITE: &str = "${sqlite}";

  type BoxError = Box<dyn Error>;

  fn main() {
    if let Err(e) = run() {
      eprintln!("last_zathura: {e}");
      std::process::exit(1);
    }
  }

  fn run() -> Result<(), BoxError> {
    let files = recent_files()?;
    let display = disambiguate(&files);

    let mut items = Vec::with_capacity(files.len() + 1);
    items.push("no file".to_string());
    items.extend(files.iter().map(|f| {
      display
        .get(f)
        .cloned()
        .unwrap_or_else(|| basename(f).to_string_lossy().into_owned())
    }));

    let idx = pick(&items)?;
    if idx == 0 {
      return Ok(());
    }

    let file = files
      .get(idx - 1)
      .ok_or_else(|| format!("invalid selection index {idx}"))?;
    Command::new(ZATHURA).arg(file).status()?;
    Ok(())
  }

  fn pick(items: &[String]) -> Result<usize, BoxError> {
    let mut parts = DMENU.split_whitespace();
    let prog = parts.next().ok_or("DMENU is empty")?;
    let args: Vec<&str> = parts.collect();

    let mut child = Command::new(prog)
      .args(&args)
      .arg("-format")
      .arg("i")
      .stdin(Stdio::piped())
      .stdout(Stdio::piped())
      .spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
      stdin.write_all((items.join("\n") + "\n").as_bytes())?;
    }

    let output = child.wait_with_output()?;
    let line = String::from_utf8_lossy(&output.stdout);
    if line.trim().is_empty() {
      return Ok(0);
    }
    Ok(line.trim().parse()?)
  }

  fn recent_files() -> Result<Vec<PathBuf>, BoxError> {
    let home = std::env::var_os("HOME").ok_or("HOME not set")?;
    let mut path = PathBuf::from(home);
    path.push(".local/share/zathura/bookmarks.sqlite");
    if !path.is_file() {
      return Ok(Vec::new());
    }

    let output = Command::new(SQLITE)
      .arg(&path)
      .arg("SELECT file FROM jumplist GROUP BY file ORDER BY MAX(id) DESC;")
      .output()?;
    if !output.status.success() {
      return Err(format!("sqlite exited with {}", output.status).into());
    }

    Ok(String::from_utf8_lossy(&output.stdout)
      .lines()
      .filter(|l| !l.is_empty())
      .map(PathBuf::from)
      .filter(|p| p.is_file())
      .collect())
  }

  fn basename(p: &Path) -> &OsStr {
    p.file_name().unwrap_or_else(|| OsStr::new(""))
  }

  fn last_k(path: &Path, k: usize) -> String {
    let parts: Vec<&OsStr> = path.iter().collect();
    let n = parts.len();
    let mut out = PathBuf::new();
    for p in &parts[n.saturating_sub(k)..] {
      out.push(p);
    }
    out.to_string_lossy().into_owned()
  }

  fn disambiguate(files: &[PathBuf]) -> HashMap<PathBuf, String> {
    let mut counts: HashMap<&OsStr, usize> = HashMap::new();
    for f in files {
      *counts.entry(basename(f)).or_insert(0) += 1;
    }
    let mut display = HashMap::new();
    for f in files {
      if counts[basename(f)] <= 1 {
        display.insert(f.clone(), basename(f).to_string_lossy().into_owned());
      }
    }
    let mut processed: HashSet<&OsStr> = HashSet::new();
    for f in files {
      let b = basename(f);
      if counts[b] <= 1 || !processed.insert(b) {
        continue;
      }
      let mut unresolved: Vec<&PathBuf> = files.iter().filter(|g| basename(g) == b).collect();
      let mut depth = 1;
      while !unresolved.is_empty() {
        let mut suffixes: HashMap<String, usize> = HashMap::new();
        for g in &unresolved {
          let s = last_k(g, depth);
          *suffixes.entry(s).or_insert(0) += 1;
        }
        let mut next = Vec::new();
        for g in &unresolved {
          let s = last_k(g, depth);
          if suffixes[&s] == 1 {
            display.insert((*g).clone(), s);
          } else {
            next.push(*g);
          }
        }
        unresolved = next;
        depth += 1;
      }
    }
    display
  }
''
