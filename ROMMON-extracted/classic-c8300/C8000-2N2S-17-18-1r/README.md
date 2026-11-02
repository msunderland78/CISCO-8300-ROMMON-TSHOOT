# Supplied C8000-2N2S package — compatibility unresolved

Reviewed **2026-11-02, America/New_York**, under C8300-03. Exact reference artifacts; **not an approved external-programmer restore** for C8300-A, whose front panel identifies **C8300-1N1S-4T2X**.

**Later November 2 finding:** the new [IOS XE 26.2.1 extraction](../iosxe-26.02.01/curie1ru/README.md) supplies the 1N1S CE9331/curie1ru package and confirms its 26.1(1r) banner. The vendor selector chooses that package for RADIUM/THALLIUM (1N1S), and the separate CE9351/curie2ru family for URANIUM/THORIUM (2N2S). This resolves the earlier family-selection uncertainty without converting this standalone 2N2S file into a 1N1S restore. The earlier observations below remain preserved.

Source: `/Volumes/CISCO FILES/C8000-2N2S-17-18-1r.pkg`. USB source read only. Package: **12,635,196 bytes**, SHA-256 `c8844d91e2d64ddff5b939fd538221ff03b5d8fcd64c4f33634de87bf73b394d`.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `ce9351_uefi64_rel_ios_upgrade_SPA.bin` | 25,165,824 (24 MiB) | `f3176b418ed1b45ee754de2a9a16c78bc4c8116b6f2a2e577d36348176a6b5fa` |
| `ce9351_uefi64_rel_update_capsule_image_SPA.bin` | 34,328,060 | `1a38eff1c76041fa7a9a239d5543f297209377560be7b8957101dc414b1c0d66` |

The package contains ISO9660 at byte **1084**. Python 3 copied bytes from that offset to a temporary ISO; macOS `bsdtar -tf`, `-tvf`, and `-xf` listed/extracted it without executing contents. See [archive listing](archive-listing.txt) and preserved [.pkginfo contents](package-info.txt). `rommon/esg/RP/URANIUM` and `rommon/esg/RP/THORIUM` contain byte-identical versions of both payloads. `latest.bin` and `capsule.bin` are aliases; only one copy of each unique payload is kept here. Temporary ISO/full extraction: `/tmp/c8300-review-20261102`, outside the repository, disposable rather than durable evidence.

All eight embedded MD5/SHA-1 checks across both board paths passed. Local copies equal source bytes. This proves extraction consistency, **not Cisco signature authentication, download-catalog checksum verification, internal ROMMON release identification, or chassis compatibility**. Metadata says x86_64, build `2024-11-25_12.47`, version `17.17.01.0.212155.1732510067..IOSXE`, and legacy platform `ISR4300`. Those fields neither establish the internal ROMMON release nor by themselves prove mislabeling. The filename does not authenticate version 17.18(1r).

The filename says **2N2S**; the photographed router is **1N1S**. Cisco documents separate recommendations: the [17.18.x table](https://www.cisco.com/c/en/us/td/docs/routers/cloud_edge/c8300/rel_notes/17-18-x/release-notes-catalyst-8200-and-catalyst-8300-series-edge-platforms-release-17-18-x.html) recommends 17.9(7r) for 1N1S versus 17.7(1r) for 2N2S; the [26.1.x table](https://www.cisco.com/c/en/us/td/docs/routers/cloud_edge/c8300/rel_notes/26-x/release-notes-catalyst-8200-and-catalyst-8300-series-edge-platforms-release-26-1-x.html) lists 26.1(1r) versus 17.18(2r). These are release-specific recommendations, not proof that any other release is incompatible. Confirm the exact download entry and board-selection relationship before selecting a candidate.

Each photographed Micron device has a **32 MiB main array**. The upgrade payload is smaller; the capsule is larger. Neither has an established whole-chip layout. Do not pad, truncate, concatenate or write these files to fill a chip. First preserve each physical chip, determine contents/role, and establish expected changed and preserved regions, including unique identity/security data. A working native updater, if recovered, is preferable to inventing an external-flash layout.

Full provenance and photo hashes: [review evidence](../../../research-evidence/c8300-a-review-20261102/results.json). Known-value and pattern scanning cannot prove absence of all unknown binary secrets; exact binaries are excluded, never redacted, if a publication guard flags them.
