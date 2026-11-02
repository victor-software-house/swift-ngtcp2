# swift-ngtcp2: agent guidance

This repository packages upstream ngtcp2, nghttp3 and BoringSSL for SwiftPM. `README.md` describes the layout, the renamed symbols and the version table.

## Rules

- Never copy upstream source into this repository. Each library is a submodule pinned to an upstream release tag. The only generated files are ngtcp2's and nghttp3's `version.h`, which their own builds write from `version.h.in`; regenerate them with `mise run version-headers` whenever a submodule moves.
- Move a submodule only to an upstream release tag, never to a branch head.
- Each release pins one release of each library: move the submodules, add a row to the README version table, and tag the merged commit. The first release is `0.0.1`; bump the patch for new upstream releases, and the minor when the package's own interface breaks.
- Every C target and every module defines `BORINGSSL_PREFIX` as `CNgtcp2BoringSSL`. The rename works through `#pragma redefine_extname`, which does not cross a Clang module boundary, so every BoringSSL header a target or a Swift caller uses must come from the same translation unit or module that defined the prefix. A header missing from `CNgtcp2BoringSSL.h` fails the link with undefined unprefixed symbols.
- Keep the package free of wrapper code. The tests only prove the package links and that ngtcp2 builds a client Initial packet through BoringSSL.
- CI builds and tests the package on Linux and macOS on GitHub-hosted runners; the repository is public, so they cost nothing.
