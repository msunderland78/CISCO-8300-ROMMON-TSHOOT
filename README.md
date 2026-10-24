# Cisco 8200 and 8300 ROMMON recovery research

Troubleshooting records, board photographs, console tools, ROMMON artifacts, and verified flash backups for three **C8235-G2** routers, one **C8375-G2 / C8375-E-G2**, and one **C8300-1N1S**. The repository name mentions 8300; its scope includes both the 8200 and 8300 work.

Start with [the active test plan and tracking log](ROUTER-RECOVERY-TEST-PLAN.md). These routers are reported nonworking. A completed firmware write or matching checksum is not evidence of a successful boot or compatibility with a particular board.

## Recovery records

| Record | Purpose |
| --- | --- |
| [Active test plan](ROUTER-RECOVERY-TEST-PLAN.md) | Five-device register, task IDs, measurements, test outcomes, next steps |
| [C8235 context](C8235-G2-RECOVERY-CONTEXT.txt) | Worked Arata prototype, TPM halt, board mapping, prior experiments |
| [C8375 context](C8375-G2-RECOVERY-CONTEXT.md) | Crestone recovery history, exact backups, firmware experiment, restoration path |
| [C8375 condensed handoff](C8375-E-G2-RECOVERY-CONTEXT.txt) | Shorter current-state summary |
| [Canonical extracted ROMMON](ROMMON-extracted/README.txt) | SoC1/SoC2 packages, raw images, capsules, and checksums |
| [Original C8375 restore notes](c8375-recovery/restore-original-20261023/RESTORE-NOTES.txt) | Exact full-chip original for chassis FDO2742M0FK only |
| [Publication manifest](REPOSITORY-MANIFEST.json) | Included files and SHA-256 hashes; local exclusions and their reasons |

Older chronological notes describe intermediate states. Use the current context documents before acting. Experimental files are research outputs, not generally compatible recovery firmware. Full flash images can contain chassis-specific identity/security data; do not clone them blindly to another router. No license to third-party firmware or research sources is implied by their inclusion.

## What is tracked

- Recovery documentation, the detailed Markdown plan, source scripts, research evidence, and board photographs/crops.
- Canonical ROMMON packages, raw images, update capsules, smaller staged firmware, and checksums.
- Exact 32 MiB C8375 original and post-experiment main-array flash backups that pass publication checks.
- Experimental ROMMON artifacts, device trees, selected upgrade scripts, and platform/driver evidence.
- Sanitized console captures and configuration snapshots in [sanitized-evidence](sanitized-evidence/README.md).

All selected files are **below 50,000,000 bytes**, the project cap requested by the owner. No Git LFS or split-image workaround is used.

Full IOS-XE images and the large mono packages remain local. Redundant unpacked ROMMON trees are omitted because their canonical copies are already in `ROMMON-extracted/`. Raw shopping HTML is omitted in favor of excerpts and product photos. See `.gitignore` and the manifest for the actual selection.

The intermediate `after-native-flash-crc-failure.bin` readback contains detected credential material and stays local without modification. The exact original restore image and final verified readback are separate artifacts and remain included after their publication checks.

## Public copies and private originals

The owner requested a public repository with configured or supplied passwords removed. Original raw logs and configuration backups stay unchanged on the local machine and are excluded from Git. Their sanitized counterparts preserve the original relative path beneath `sanitized-evidence/`. References in historical notes may point to the original local paths; prepend `sanitized-evidence/` to find a published counterpart.

Preparation removes discovered password values, configured password hashes, logged replies to password prompts, recognizable access tokens, private keys, and credentials embedded in URLs. Local known-value material is stored only inside `.git/recovery-private/` with restricted permissions; it is not versioned. GitHub authentication uses the existing GitHub CLI credential helper, not a token placed in a script or remote URL.

Binary ROMMON and SPI restore files remain **byte-exact**. They are scanned for known passwords and recognizable credential patterns. A detection blocks publication so the original can be excluded; sanitization must never patch a restore image. Scanning cannot prove that every unknown binary security field is absent. Device identifiers and other recovery evidence remain public as requested.

## Repeatable preparation and sync

Requires Python 3 and Git. Pushing additionally requires authorized GitHub credentials; this workstation already has an authenticated GitHub CLI session. No router connection is made by these commands.

```sh
# Regenerate sanitized copies and the file/hash manifest; do not commit or push.
python3 scripts/repository_tools.py prepare

# Enable the repository-local size/credential guards after cloning.
python3 scripts/repository_tools.py install-hooks

# Verify the tooling's redaction and preservation behavior.
python3 -m unittest discover -s tests -v

# Prepare, stage, audit, commit if changed, and push to origin/main.
python3 scripts/repository_tools.py sync --message "Record today's recovery measurements"
```

The pre-commit guard audits the staged bytes, not just the working files. The pre-push guard checks all new Git blobs, including a file deleted in a later local commit. Checks report filenames and categories without printing detected secrets. GitHub Actions also tests the tools and checks the published tree; it cannot access the workstation's private known-password list. Local hooks must be installed explicitly after a clone.

Sync is an explicit command, not a background upload service. Review new evidence before running it. A non-fast-forward push is rejected; the script does not force-push or automatically merge remote changes. New oversized or credential-bearing files block sync until their inclusion/exclusion is resolved.

## Python tools and provenance

- [Publication, credential checks, manifest, and sync](scripts/repository_tools.py): created for this repository; Python standard library only.
- [Publication regression tests](tests/test_repository_tools.py): verifies password redaction, binary credential detection, size enforcement, and preservation of local originals.
- [C8235 console bridge](c8235_serial_console.py): existing JSON-controlled serial logging and trigger tool.
- [C8375 RJ45 console bridge](c8375-recovery/rj45_serial_console.py): existing serial tool with baud switching.
- [C8375 USB console bridge](c8375-recovery/serial_console.py): existing serial tool.

The serial bridges open hardware ports when executed; inspect their settings and ensure the port is not in use before running them. They are separate from the repository sync tool.

AI-assisted work is recorded through the actual scripts, regression tests, documentation, manifests, and Git commits. Existing extracted vendor code and historical artifacts are kept distinct from newly authored tooling; the repository does not claim they were all written during this setup.
