// PreToolUse guard for Bash commands. Reads the hook JSON on stdin.
//
// - git push in any form (git -C dir push, git -c k=v push, /usr/bin/git push,
//   inside bash -c / eval / $(...) / backticks): blocked (exit 2).
// - sed scripts using the e command or the e flag of s/// (runs a shell
//   command): ask. Writing files (-i, w, W) is allowed like any edit.
// - sed -f (script read from a file, can't be inspected): ask.
// - git commit carrying an AI attribution trailer (Co-authored-by: Codex,
//   Generated with Claude, ...): blocked. Codex has no local switch for it.
//
// Usage: node guard-bash.mjs [claude|codex]. Codex hooks can't ask, so with
// "codex" every ask becomes an allow: Codex's sandbox still asks before
// writes outside the workspace or network access.
//
// Permission rules only support * wildcards, so these checks live here.
// Known gaps: git aliases that expand to push (git p), commands fed to a
// shell through a heredoc or a script file, commit messages read from a
// file (git commit -F).

import { readFileSync } from "node:fs";
import { basename } from "node:path";

const SEP = Symbol("separator");
const SHELLS = new Set(["bash", "sh", "zsh", "dash", "ksh", "fish"]);
const WRAPPERS = new Set([
  "env",
  "command",
  "builtin",
  "exec",
  "nohup",
  "nice",
  "timeout",
  "stdbuf",
  "xargs",
  "sudo",
  "doas",
  "flock",
  "setsid",
  "unbuffer",
]);
const KEYWORDS = new Set([
  "if",
  "then",
  "elif",
  "else",
  "do",
  "while",
  "until",
  "time",
]);
const GIT_VALUE_OPTS = new Set([
  "-C",
  "-c",
  "--git-dir",
  "--work-tree",
  "--namespace",
  "--exec-path",
  "--config-env",
  "--super-prefix",
]);
const ASSIGNMENT = /^[A-Za-z_][A-Za-z0-9_]*=/;
const HARNESS = process.argv[2] ?? "claude";
const GIT_COMMIT = /\bgit\b[\s\S]*\bcommit\b/;
const AI_TRAILER =
  /\b(co-authored-by|assisted-by|generated-by|co-developed-by):[^\n]*\b(codex|claude|openai|anthropic|chatgpt)\b|\bgenerated with \W*(codex|claude)\b/i;

class Decision extends Error {
  constructor(kind, reason) {
    super(reason);
    this.kind = kind;
  }
}
const deny = (reason) => {
  throw new Decision("deny", reason);
};
const ask = (reason) => {
  throw new Decision("ask", reason);
};

// Heredoc bodies are data, not commands: drop them.
function stripHeredocs(text) {
  const out = [];
  let delim = null,
    dash = false;
  for (const line of text.split("\n")) {
    if (delim !== null) {
      if ((dash ? line.replace(/^\t+/, "") : line) === delim) delim = null;
      continue;
    }
    out.push(line);
    const m = line.match(/<<(-?)\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?/);
    if (m) {
      dash = m[1] === "-";
      delim = m[2];
    }
  }
  return out.join("\n");
}

// Split into words honoring quotes and backslashes; shell operators become SEP.
function tokenize(text) {
  const tokens = [];
  let cur = "",
    has = false,
    quote = null;
  const flush = () => {
    if (has) tokens.push(cur);
    cur = "";
    has = false;
  };
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quote) {
      if (c === quote) quote = null;
      else if (quote === '"' && c === "\\") cur += text[++i] ?? "";
      else cur += c;
      continue;
    }
    if (c === "'" || c === '"') {
      quote = c;
      has = true;
    } else if (c === "\\") {
      cur += text[++i] ?? "";
      has = true;
    } else if (" \t\r".includes(c)) flush();
    else if (";&|(){}!\n".includes(c)) {
      flush();
      tokens.push(SEP);
    } else {
      cur += c;
      has = true;
    }
  }
  if (quote) deny("can't parse command (unbalanced quotes); blocking");
  flush();
  return tokens;
}

function checkGit(args) {
  for (let i = 0; i < args.length; i++) {
    if (GIT_VALUE_OPTS.has(args[i])) i++;
    else if (args[i].startsWith("-")) continue;
    else {
      if (args[i] === "push")
        deny("git push is blocked. Ask the user to push.");
      return;
    }
  }
}

// Does a sed script run a shell command: the e command, or s/// with the e
// flag? GNU sed needs no space after e (edate), so any e in command position
// counts.
function sedScriptRuns(script) {
  const addr = String.raw`(?:\d+(?:~\d+)?|\$|/(?:\\.|[^/\n])*/[IM]*)`;
  const command = new RegExp(
    String.raw`(?:^|[;\n{}])\s*(?:${addr}(?:\s*,\s*${addr})?)?\s*!?\s*e`,
  );
  if (command.test(script)) return true;
  const subst = /s([^\w\s\\])(?:\\.|(?!\1).)*\1(?:\\.|(?!\1).)*\1([^;\n}]*)/g;
  for (const m of script.matchAll(subst)) {
    if (/^[gpIiMm0-9]*e/.test(m[2])) return true;
  }
  return false;
}

function checkSed(args) {
  const scripts = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "-e" || a === "--expression") scripts.push(args[++i] ?? "");
    else if (a.startsWith("--expression=")) scripts.push(a.slice(13));
    else if (a.startsWith("-e") && !a.startsWith("--"))
      scripts.push(a.slice(2));
    else if (
      a === "-f" ||
      a === "--file" ||
      a.startsWith("--file=") ||
      (a.startsWith("-f") && !a.startsWith("--"))
    )
      ask("sed reads its script from a file, which the guard can't inspect.");
    else if (a.startsWith("-")) continue;
    else if (scripts.length === 0) scripts.push(a);
  }
  if (scripts.some(sedScriptRuns))
    ask("sed script uses e (runs a shell command).");
}

function runSimple(argv, depth) {
  let i = 0;
  // Skip assignments, keywords and wrapper commands (with their options).
  while (i < argv.length) {
    const name = basename(argv[i]);
    if (ASSIGNMENT.test(argv[i]) || KEYWORDS.has(argv[i])) i++;
    else if (WRAPPERS.has(name)) {
      i++;
      while (
        i < argv.length &&
        (argv[i].startsWith("-") || ASSIGNMENT.test(argv[i]))
      ) {
        if (
          [
            "nice:-n",
            "timeout:-s",
            "timeout:-k",
            "stdbuf:-i",
            "stdbuf:-o",
            "stdbuf:-e",
            "flock:-w",
          ].includes(`${name}:${argv[i]}`)
        )
          i++;
        i++;
      }
      if (name === "timeout" || name === "flock") i++;
    } else break;
  }
  const [program, ...args] = argv.slice(i);
  if (!program) return;
  const name = basename(program);
  if (name === "git") checkGit(args);
  else if (name === "sed") checkSed(args);
  else if (name === "eval") check(args.join(" "), depth + 1);
  else if (SHELLS.has(name)) {
    const c = args.findIndex((a) => /^-[A-Za-z]*c[A-Za-z]*$/.test(a));
    if (c >= 0 && c + 1 < args.length) check(args[c + 1], depth + 1);
  }
}

function check(text, depth = 0) {
  if (depth > 6)
    deny("command nests too deeply for the guard to inspect; blocking");
  text = stripHeredocs(text);
  // Command substitutions run as commands too.
  for (const m of text.matchAll(/\$\(((?:[^()]|\([^()]*\))*)\)|`([^`]*)`/g)) {
    check(m[1] ?? m[2], depth + 1);
  }
  let cur = [];
  for (const token of [...tokenize(text), SEP]) {
    if (token === SEP) {
      if (cur.length) runSimple(cur, depth);
      cur = [];
    } else cur.push(token);
  }
}

// Quote one argv element for the shell, so an argv array becomes one string.
const shellQuote = (a) =>
  /^[\w@%+=:,./-]+$/.test(a) ? a : `'${a.replace(/'/g, "'\\''")}'`;

try {
  const input = JSON.parse(readFileSync(0, "utf8"));
  let command = input?.tool_input?.command;
  if (Array.isArray(command)) command = command.map(String).map(shellQuote).join(" ");
  if (typeof command === "string") {
    if (GIT_COMMIT.test(command) && AI_TRAILER.test(command))
      deny("commit message has an AI attribution trailer. Remove it: all work is authored by the user.");
    check(command);
  }
  process.exit(0);
} catch (error) {
  if (error instanceof Decision && error.kind === "ask" && HARNESS === "codex")
    process.exit(0);
  if (error instanceof Decision && error.kind === "ask") {
    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "ask",
          permissionDecisionReason: `guard-bash: ${error.message}`,
        },
      }),
    );
    process.exit(0);
  }
  const reason =
    error instanceof Decision
      ? error.message
      : `internal error (${error}); blocking`;
  process.stderr.write(`guard-bash: ${reason}\n`);
  process.exit(2);
}
