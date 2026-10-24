#!/usr/bin/env python3
"""Prepare, audit, and sync router recovery evidence without publishing credentials.

Original logs/configs are never rewritten. Locally discovered secrets are stored
only under .git/recovery-private, outside versioned files. Checks report paths
and categories, never matching values. Uses only Python's standard library.
"""

import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
LIMIT = 50_000_000  # Deliberate user cap; reject files at or above this size.
MARKER = "[REDACTED]"
CONFIG = re.compile(
    r"^([ \t]*(?:[\w.()/:-]+[>#][ \t]*)?"
    r"(?:enable[ \t]+(?:secret|password)|"
    r"username[ \t]+\S+(?:[ \t]+privilege[ \t]+\d+)?[ \t]+(?:secret|password)|"
    r"password|snmp-server[ \t]+community|key-string)[ \t]+)([^\r\n]+)$",
    re.I | re.M,
)
PROMPT = re.compile(
    r"(?:enter|confirm|repeat)[^\r\n]*?(?:secret|password)[ \t]*:|^[ \t]*Password[ \t]*:",
    re.I,
)
TOKEN = re.compile(
    rb"(?:github_pat_[A-Za-z0-9_]{30,}|gh[pousr]_[A-Za-z0-9]{20,}|"
    rb"AKIA[A-Z0-9]{16}|xox[baprs]-[A-Za-z0-9-]{20,})"
)
PRIVATE_KEY = re.compile(
    rb"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----"
    rb"[\s\S]+?-----END (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----"
)
HASH = re.compile(rb"\$(?:[15689]|2[aby])\$[A-Za-z0-9./$]{10,}")
AUTH_URL = re.compile(rb"https?://[^\s/:<>]+:[^\s/@<>]+@[^\s<>]+")
RAW_CONFIG_DIR = "c8375-recovery/original-staged-firmware/"
MANIFEST = ROOT / "REPOSITORY-MANIFEST.json"


def git(*args, input_data=None, check=True):
    result = subprocess.run(
        ["git", *args], cwd=ROOT, input=input_data,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if check and result.returncode:
        # Do not relay command output that could include credential values.
        raise RuntimeError("Git operation failed: " + args[0])
    return result


def private_dir():
    path = Path(git("rev-parse", "--absolute-git-dir").stdout.decode().strip())
    path = path / "recovery-private"
    path.mkdir(mode=0o700, exist_ok=True)
    path.chmod(0o700)
    return path


def is_raw_source(rel):
    """Logs/config snapshots that need a sanitized publication counterpart."""
    if rel.startswith("sanitized-evidence/"):
        return False
    p = Path(rel)
    if p.suffix == ".log" or p.name.endswith("readable.txt"):
        return True
    return rel.startswith(RAW_CONFIG_DIR) and p.suffix == ".txt" and any(
        word in p.name.lower() for word in ("config", "running", "startup")
    )


def files_on_disk():
    # Prune private/Git/tool directories rather than examining their contents.
    for parent, dirs, names in os.walk(ROOT):
        dirs[:] = sorted(d for d in dirs if d not in {
            ".git", ".venv", "venv", "__pycache__", "tmp", "local-private"
        })
        for name in sorted(names):
            path = Path(parent) / name
            if not path.is_symlink() and path.is_file():
                yield path


def config_values(text):
    for match in CONFIG.finditer(text):
        tail = match.group(2).strip()
        typed = bool(re.match(r"^(?:0|4|5|6|7|8|9)\s+", tail))
        # Wrapped recovery prose such as "enable secret was entered during
        # setup" is not a configuration statement. Plain IOS passwords are a
        # single token; SNMP community statements can also have RO/RW/ACL args.
        if not typed and len(tail.split()) > 1 and "snmp-server" not in match.group(1).lower():
            continue
        tail = re.sub(r"^(?:0|4|5|6|7|8|9)\s+", "", tail)
        value = tail.split()[0] if tail else ""
        if value and MARKER not in value and not value.startswith("<"):
            yield value


def prompt_replies(text):
    pending = -100
    for number, line in enumerate(text.splitlines()):
        if PROMPT.search(line):
            pending = number
        if "[TX " in line and 0 <= number - pending <= 3:
            try:
                payload = ast.literal_eval(line.split("] ", 1)[1])
                if isinstance(payload, bytes):
                    value = payload.decode().rstrip("\r\n")
                    if value and any(ord(c) >= 32 for c in value) and MARKER not in value:
                        yield value
            except (SyntaxError, ValueError, UnicodeError, IndexError):
                pass
            pending = -100


def discover_secrets(sources):
    secret_file = private_dir() / "known-secrets.json"
    secrets = set(json.loads(secret_file.read_text())) if secret_file.exists() else set()
    for path in sources:
        text = path.read_text(errors="replace")
        secrets.update(config_values(text))
        secrets.update(prompt_replies(text))
    secrets = {s for s in secrets if s and any(ord(c) >= 32 for c in s)
               and MARKER not in s}
    secret_file.write_text(json.dumps(sorted(secrets)))
    secret_file.chmod(0o600)
    return secrets


def load_secrets():
    path = private_dir() / "known-secrets.json"
    return set(json.loads(path.read_text())) if path.exists() else set()


def strong_secrets(secrets):
    # A short attempted default password must not redact every vendor name or
    # firmware string. Its actual credential contexts are handled separately.
    return sorted((s for s in secrets if len(s) >= 8), key=len, reverse=True)


def sanitize(data, secrets):
    text = data.decode("utf-8", errors="replace")
    for value in strong_secrets(secrets):
        text = text.replace(value, MARKER)
    text = CONFIG.sub(lambda m: m.group(1) + MARKER, text)
    for value in prompt_replies(text):
        # Redact a weak/default value in logged replies, without erasing
        # unrelated occurrences such as a username or a manufacturer string.
        escaped = repr(value.encode())[2:-1]
        text = re.sub(
            r"(\[TX [^\r\n]+?\] b['\"])" + re.escape(escaped) + r"(?=\\r|\\n|['\"])",
            lambda m: m.group(1) + MARKER, text,
        )
    result = text.encode()
    result = PRIVATE_KEY.sub(MARKER.encode(), result)
    result = TOKEN.sub(MARKER.encode(), result)
    result = HASH.sub(MARKER.encode(), result)
    result = AUTH_URL.sub(MARKER.encode(), result)
    return result


def findings(data, secrets=()):
    result = []
    for label, pattern in (("access-token", TOKEN), ("private-key", PRIVATE_KEY),
                           ("password-hash", HASH), ("credential-in-url", AUTH_URL)):
        if pattern.search(data):
            result.append(label)
    for value in strong_secrets(secrets):
        if value.encode() in data:
            result.append("known-password-or-hash")
            break
    # Firmware code contains credential-related words; only treat anchored
    # configuration syntax as a credential in text-like content.
    if b"\0" not in data:
        text = data.decode("utf-8", errors="replace")
        if any(config_values(text)):
            result.append("configured-credential")
        if any(prompt_replies(text)):
            result.append("password-prompt-reply")
    return sorted(set(result))


def ignored_paths(paths):
    if not paths:
        return set()
    payload = b"\0".join(str(p.relative_to(ROOT)).encode() for p in paths) + b"\0"
    result = git("check-ignore", "--no-index", "-z", "--stdin", input_data=payload, check=False)
    if result.returncode not in (0, 1):
        raise RuntimeError("Cannot evaluate ignore rules")
    return {s.decode() for s in result.stdout.split(b"\0") if s}


def exclusion_reason(rel):
    if rel == "c8375-recovery/spi-backups-20261023/after-native-flash-crc-failure.bin":
        return "intermediate failed-write dump contains detected credential material; exact original retained locally"
    if is_raw_source(rel):
        return "original log/config retained locally; sanitized counterpart published"
    if rel.startswith("c8kg2be-") and (rel.endswith(".pkg") or rel.startswith("c8kg2be-universalk9.")):
        return "full IOS-XE image or large mono package"
    if "/rommon/" in rel or "/mono/firmware/" in rel:
        return "redundant ROMMON extraction; canonical files in ROMMON-extracted/"
    if "snapshot.html" in rel:
        return "raw shopping-page capture; excerpts retained"
    return "local metadata, credential file, cache, or explicit .gitignore exclusion"


def prepare():
    paths = list(files_on_disk())
    sources = [p for p in paths if is_raw_source(str(p.relative_to(ROOT)))]
    secrets = discover_secrets(sources)
    generated = []
    for source in sources:
        if source.stat().st_size >= LIMIT:
            continue
        relative = source.relative_to(ROOT)
        output = ROOT / "sanitized-evidence" / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        cleaned = sanitize(source.read_bytes(), secrets)
        problems = findings(cleaned, secrets)
        if problems:
            raise RuntimeError("Sanitization requires review: " + str(relative) + " (" + ", ".join(problems) + ")")
        output.write_bytes(cleaned)
        generated.append(str(output.relative_to(ROOT)))

    paths = list(files_on_disk())
    ignored = ignored_paths(paths)
    included, excluded, problems = [], [], []
    for path in sorted(paths):
        relative = str(path.relative_to(ROOT))
        if path == MANIFEST:
            continue  # The manifest cannot contain its own content hash.
        size = path.stat().st_size
        if relative in ignored:
            excluded.append({"path": relative, "bytes": size, "reason": exclusion_reason(relative)})
            continue
        if size >= LIMIT:
            problems.append((relative, "file-at-or-above-50-MB"))
            continue
        data = path.read_bytes()
        hits = findings(data, secrets)
        if hits:
            problems.append((relative, ", ".join(hits)))
            continue
        included.append({"path": relative, "bytes": size, "sha256": hashlib.sha256(data).hexdigest()})
    if problems:
        for path, reason in problems:
            print("REVIEW REQUIRED:", path, "[" + reason + "]", file=sys.stderr)
        raise RuntimeError("No manifest published; resolve flagged files without modifying exact restore images")
    result = {
        "repository": "https://github.com/msunderland78/CISCO-8300-ROMMON-TSHOOT",
        "scope": "Cisco 8200 and 8300 recovery research, including three C8235-G2, C8375-G2 and C8300-1N1S",
        "maximum_file_bytes_exclusive": LIMIT,
        "manifest_self_hash_omitted": True,
        "sanitized_files": generated,
        "included": included,
        "excluded_local_files": excluded,
        "totals": {"included_files_without_manifest": len(included),
                   "included_bytes_without_manifest": sum(item["bytes"] for item in included),
                   "excluded_local_files": len(excluded)},
        "limitations": "Pattern and known-value scanning cannot prove absence of every unknown binary secret. Original restore images are kept byte-exact; any detected credential requires excluding the original, not patching it.",
    }
    MANIFEST.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print("Prepared", len(generated), "sanitized files; selected", len(included) + 1,
          "files including manifest; excluded", len(excluded), "local files.")


def audit_blobs(items, secrets=None):
    secrets = load_secrets() if secrets is None else secrets
    failures = []
    checked = set()
    for oid, path in items:
        if oid in checked:
            continue
        checked.add(oid)
        size = int(git("cat-file", "-s", oid).stdout)
        if size >= LIMIT:
            failures.append((path, "file-at-or-above-50-MB"))
            continue
        data = git("cat-file", "blob", oid).stdout
        hits = findings(data, secrets)
        if hits:
            failures.append((path, ", ".join(hits)))
        if is_raw_source(path):
            failures.append((path, "raw-log-or-configuration; publish sanitized counterpart"))
    if failures:
        for path, reason in failures:
            print("BLOCKED:", path, "[" + reason + "]", file=sys.stderr)
        raise RuntimeError("Repository audit failed; no matching values printed")
    print("Audit passed:", len(checked), "unique blobs; file-size and credential checks passed.")


def audit_index():
    items = []
    for record in git("ls-files", "--stage", "-z").stdout.split(b"\0"):
        if record:
            metadata, path = record.split(b"\t", 1)
            mode, oid, stage = metadata.split()
            if stage != b"0":
                raise RuntimeError("Resolve index conflicts before syncing")
            if mode != b"160000":
                items.append((oid.decode(), path.decode()))
    audit_blobs(items)


def audit_tree():
    items = []
    for record in git("ls-tree", "-r", "-z", "HEAD").stdout.split(b"\0"):
        if record:
            metadata, path = record.split(b"\t", 1)
            mode, kind, oid = metadata.split()
            if kind == b"blob":
                items.append((oid.decode(), path.decode()))
    audit_blobs(items)


def audit_history():
    base = git("rev-parse", "--verify", "refs/remotes/origin/main", check=False)
    revision = "refs/remotes/origin/main..HEAD" if base.returncode == 0 else "HEAD"
    items = []
    for line in git("rev-list", "--objects", revision).stdout.splitlines():
        oid, _, path = line.partition(b" ")
        if git("cat-file", "-t", oid.decode()).stdout.strip() == b"blob":
            items.append((oid.decode(), path.decode() or "<unnamed blob>"))
    audit_blobs(items)


def install_hooks():
    for name in ("pre-commit", "pre-push"):
        (ROOT / ".githooks" / name).chmod(0o755)
    git("config", "core.hooksPath", ".githooks")
    print("Installed repository-local pre-commit and pre-push guards.")


def sync(message):
    if git("branch", "--show-current").stdout.decode().strip() != "main":
        raise RuntimeError("Sync expects the main branch; review branch changes before publishing")
    remote = git("remote", "get-url", "origin").stdout.decode().strip()
    expected = "github.com/msunderland78/CISCO-8300-ROMMON-TSHOOT"
    allowed = {"https://" + expected, "https://" + expected + ".git",
               "git@" + expected.replace("github.com/", "github.com:"),
               "git@" + expected.replace("github.com/", "github.com:") + ".git"}
    if remote not in allowed:
        raise RuntimeError("Unexpected or credential-bearing origin URL; review before sync")
    install_hooks()
    prepare()
    git("add", "--all")
    audit_index()
    changed = git("diff", "--cached", "--quiet", check=False).returncode
    if changed == 1:
        git("commit", "-m", message)
        print("Committed recovery updates.")
    elif changed != 0:
        raise RuntimeError("Cannot inspect staged changes")
    else:
        print("No new file changes to commit.")
    audit_history()
    git("push", "--set-upstream", "origin", "main")
    print("Synced origin/main successfully.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("prepare", "audit-index", "audit-tree", "audit-history", "install-hooks", "sync"))
    parser.add_argument("--message", default="Update Cisco 8200 and 8300 recovery evidence")
    args = parser.parse_args()
    try:
        {"prepare": prepare, "audit-index": audit_index, "audit-tree": audit_tree,
         "audit-history": audit_history, "install-hooks": install_hooks,
         "sync": lambda: sync(args.message)}[args.command]()
    except (RuntimeError, OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
