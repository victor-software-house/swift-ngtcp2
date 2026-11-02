// swift-tools-version: 6.0

import Foundation
import PackageDescription

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

/// BoringSSL's own list of its sources (gen/sources.json): each library's C++ sources and the
/// prebuilt assembly for every platform, each assembly file guarded by its target's macros.
struct BoringSSLSources: Decodable {
    struct Library: Decodable {
        let srcs: [String]
        let asm: [String]?
    }
    let bcm: Library
    let crypto: Library
    let ssl: Library

    var all: [String] { [bcm, crypto, ssl].flatMap { $0.srcs + ($0.asm ?? []) }.map { "boringssl/" + $0 } }
}

let boringssl = try JSONDecoder().decode(
    BoringSSLSources.self,
    from: Data(contentsOf: root.appendingPathComponent("Sources/CNgtcp2BoringSSL/boringssl/gen/sources.json")))

/// nghttp3's lib/*.c. The directory also holds sfparse's tests and examples in lib/sfparse.
let nghttp3Sources = try FileManager.default
    .contentsOfDirectory(atPath: root.appendingPathComponent("Sources/nghttp3/nghttp3/lib").path)
    .filter { $0.hasSuffix(".c") }
    .sorted()
    .map { "nghttp3/lib/" + $0 }

/// Renames every BoringSSL symbol to CNgtcp2BoringSSL_<name> (README "Renamed BoringSSL symbols").
let prefix = "CNgtcp2BoringSSL"

/// The configure results ngtcp2's and nghttp3's own builds reach on macOS and on Linux (glibc).
let platform: [CSetting] = [
    .define("HAVE_ARPA_INET_H"),
    .define("HAVE_NETINET_IN_H"),
    .define("HAVE_UNISTD_H"),
    .define("HAVE_ENDIAN_H", .when(platforms: [.linux])),
    .define("HAVE_BYTESWAP_H", .when(platforms: [.linux])),
    .define("HAVE_DECL_BE64TOH", to: "1", .when(platforms: [.linux])),
    .define("HAVE_DECL_BSWAP_64", to: "1", .when(platforms: [.linux])),
    .define("HAVE_DECL_BE64TOH", to: "0", .when(platforms: [.macOS])),
    .define("HAVE_DECL_BSWAP_64", to: "0", .when(platforms: [.macOS])),
    .define("HAVE_EXPLICIT_BZERO", .when(platforms: [.linux])),
]

let package = Package(
    name: "swift-ngtcp2",
    products: [
        .library(name: "ngtcp2", targets: ["ngtcp2"]),
        .library(name: "nghttp3", targets: ["nghttp3"]),
        .library(name: "CNgtcp2BoringSSL", targets: ["CNgtcp2BoringSSL"]),
    ],
    targets: [
        // BoringSSL's crypto and ssl libraries, from the release the submodule pins.
        .target(
            name: "CNgtcp2BoringSSL",
            sources: boringssl.all,
            cSettings: [.headerSearchPath("boringssl/include"), .define("BORINGSSL_PREFIX", to: prefix)],
            cxxSettings: [.headerSearchPath("boringssl/include"), .define("BORINGSSL_PREFIX", to: prefix)]
        ),
        // ngtcp2's library and its BoringSSL crypto backend.
        .target(
            name: "ngtcp2",
            dependencies: ["CNgtcp2BoringSSL"],
            sources: ["ngtcp2/lib", "ngtcp2/crypto/shared.c", "ngtcp2/crypto/boringssl/boringssl.c"],
            cSettings: platform + [
                .headerSearchPath("ngtcp2/lib"),
                .headerSearchPath("ngtcp2/crypto"),
                .define("BORINGSSL_PREFIX", to: prefix),
            ]
        ),
        // nghttp3's library and the structured field parser it includes (lib/sfparse).
        .target(
            name: "nghttp3",
            sources: ["nghttp3/lib/sfparse/sfparse.c"] + nghttp3Sources,
            cSettings: platform + [.headerSearchPath("nghttp3/lib")]
        ),
        .testTarget(name: "ngtcp2Tests", dependencies: ["ngtcp2", "nghttp3", "CNgtcp2BoringSSL"]),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx17
)
