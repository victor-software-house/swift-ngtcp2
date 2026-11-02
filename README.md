# swift-ngtcp2

[ngtcp2](https://github.com/ngtcp2/ngtcp2) (QUIC), [nghttp3](https://github.com/ngtcp2/nghttp3) (HTTP/3) and [BoringSSL](https://boringssl.googlesource.com/boringssl) (TLS 1.3 for QUIC) as a Swift package.

The repository holds no upstream source.
Each library is a git submodule pinned to an upstream release tag, inside its target's directory under `Sources/`.
`Package.swift` compiles the sources each release lists:
BoringSSL's `gen/sources.json`, ngtcp2's `lib` and its BoringSSL crypto backend, nghttp3's `lib`.
SwiftPM checks the submodules out with the package.

## Renamed BoringSSL symbols

Every BoringSSL symbol is renamed with the prefix `CNgtcp2BoringSSL_`, so this copy of BoringSSL links into the same process as another one,
such as swift-nio-ssl's or swift-crypto's, or a system OpenSSL.
BoringSSL ships the rename list in its tree (`include/openssl/prefix_symbols.h`); defining `BORINGSSL_PREFIX` turns it on.
Swift code calls the original names, such as `SSL_CTX_new`; the compiler links them to the renamed symbols.
BoringSSL's C++ internals are in the namespace `bssl::CNgtcp2BoringSSL`.
The only global symbols left unrenamed are weak ones every C++ object can emit: libc++ template instances, `__clang_call_terminate` and the `typeinfo` of `evp_pkey_ctx_st` (`nm` of the objects on macOS, 0.0.1).

## Use

```swift
dependencies: [
    .package(url: "https://github.com/victor-software-house/swift-ngtcp2.git", exact: "0.0.2"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "ngtcp2", package: "swift-ngtcp2"),
        .product(name: "nghttp3", package: "swift-ngtcp2"),
        .product(name: "CNgtcp2BoringSSL", package: "swift-ngtcp2"),
    ]),
]
```

| Module | Interface |
|:--|:--|
| `ngtcp2` | `ngtcp2.h`, `ngtcp2_crypto.h`, `ngtcp2_crypto_boringssl.h` |
| `nghttp3` | `nghttp3.h` |
| `CNgtcp2BoringSSL` | the BoringSSL headers a QUIC endpoint uses: `ssl.h`, `evp.h`, `x509.h`, `pem.h`, `bio.h`, `err.h`, `rand.h` and the primitives ngtcp2 calls |

## Versions

Each release of this package pins one release of each library:

| Package | ngtcp2 | nghttp3 | BoringSSL |
|:--|:--|:--|:--|
| 0.0.1 | v1.25.0 | v1.18.0 | 0.20261020.0 |
| 0.0.2 | v1.25.0 | v1.18.0 | 0.20261020.0 |

## Licence

ngtcp2 and nghttp3 are MIT; BoringSSL is Apache 2.0 with parts under the OpenSSL and ISC licences.
Their licences are in the submodules.
The packaging in this repository is MIT; see `LICENSE`.
