# swift-ngtcp2: agent guidance

This repository packages upstream ngtcp2 and nghttp3 for SwiftPM, on swift-nio-ssl's BoringSSL. `README.md` describes the layout, the BoringSSL arrangement and the version table.

## Rules

- Never copy upstream source into this repository. ngtcp2 and nghttp3 are submodules pinned to upstream release tags. The only generated files are their `version.h`, which `mise run version-headers` writes from `version.h.in` as their own builds do.
- `Package.swift` reads no files. SwiftPM reads a dependency's manifest from git without its submodules, so a manifest that lists `lib/` builds here and fails for every consumer (0.0.1 did). Its source lists are literals that `mise run sources` writes from the submodules; `mise run check:sources` (part of `mise run check`) fails when they differ.
- Move a submodule only to an upstream release tag, never to a branch head, then run `mise run version-headers` and `mise run sources`. The `Upstream releases` workflow does this every week and opens a pull request.
- Add no TLS library. ngtcp2 links swift-nio-ssl's BoringSSL (README "BoringSSL"); a header ngtcp2's backend newly includes gets a one-line mapping in `Sources/ngtcp2/include/openssl/`.
- Each release pins one release of ngtcp2 and nghttp3: add a row to the README version table and tag the merged commit. Bump the patch for new upstream releases, and the minor when the package's own interface breaks.
- Keep the package free of wrapper code. The tests only prove the package links and that ngtcp2 builds a client Initial packet through swift-nio-ssl's BoringSSL.
- CI builds and tests the package on Linux and macOS on GitHub-hosted runners, on every pull request and every week against the newest swift-nio-ssl; the repository is public, so they cost nothing.
