# swift-ngtcp2

[ngtcp2](https://github.com/ngtcp2/ngtcp2) (QUIC) and [nghttp3](https://github.com/ngtcp2/nghttp3) (HTTP/3) as a Swift package, on the BoringSSL that [swift-nio-ssl](https://github.com/apple/swift-nio-ssl) already builds.

The repository holds no upstream source.
ngtcp2 and nghttp3 are git submodules pinned to upstream release tags, inside their targets' directories under `Sources/`.
`Package.swift` compiles ngtcp2's `lib` and its BoringSSL crypto backend, and nghttp3's `lib`.
SwiftPM checks the submodules out with the package.

## BoringSSL

This package adds no TLS library.
ngtcp2's BoringSSL backend is compiled against swift-nio-ssl's copy of BoringSSL (its `CNIOBoringSSL` target) and links to it, so a program that also uses swift-nio-ssl carries one BoringSSL for TLS and QUIC.

- The `ngtcp2` target depends on swift-nio-ssl's `NIOSSL` product, which links `CNIOBoringSSL` into the program and puts its headers on the include path.
- `Sources/ngtcp2/include/openssl/` holds one line per header ngtcp2's backend includes, such as `<openssl/ssl.h>`, mapping it to swift-nio-ssl's `CNIOBoringSSL_ssl.h`.
- swift-nio-ssl renames every BoringSSL symbol with the prefix `CNIOBoringSSL_` through `#define`s, so ngtcp2's calls link to its renamed functions, and Swift code calls them by those names: `import CNIOBoringSSL`, then `CNIOBoringSSL_SSL_CTX_new`.

`CNIOBoringSSL` is not one of swift-nio-ssl's products: this relies on its headers reaching every target that depends on `NIOSSL`, and on the BoringSSL version it vendors.
CI builds against the newest swift-nio-ssl release every week, so a swift-nio-ssl release that breaks either fails here first.

## Use

```swift
dependencies: [
    .package(url: "https://github.com/victor-software-house/swift-ngtcp2.git", exact: "0.0.3"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "ngtcp2", package: "swift-ngtcp2"),
        .product(name: "nghttp3", package: "swift-ngtcp2"),
    ]),
]
```

| Module | Interface |
|:--|:--|
| `ngtcp2` | `ngtcp2.h`, `ngtcp2_crypto.h`, `ngtcp2_crypto_boringssl.h` |
| `nghttp3` | `nghttp3.h` |
| `CNIOBoringSSL` | swift-nio-ssl's BoringSSL, with every name prefixed `CNIOBoringSSL_` |

## Versions

Each release of this package pins one release of ngtcp2 and nghttp3, and takes swift-nio-ssl from the version listed up to its next major version.
0.0.1 cannot be used as a dependency: its manifest read files from the submodules, which SwiftPM does not check out when it reads a manifest.
0.0.1 and 0.0.2 built their own BoringSSL.

| Package | ngtcp2 | nghttp3 | BoringSSL |
|:--|:--|:--|:--|
| 0.0.1 | v1.25.0 | v1.18.0 | 0.20261020.0, built here |
| 0.0.2 | v1.25.0 | v1.18.0 | 0.20261020.0, built here |
| 0.0.3 | v1.25.0 | v1.18.0 | swift-nio-ssl 2.37.5 and later 2.x |

A workflow checks ngtcp2's and nghttp3's latest releases every week and opens a pull request that moves the submodules.

## Licence

ngtcp2 and nghttp3 are MIT; their licences are in the submodules.
The packaging in this repository is MIT; see `LICENSE`.
