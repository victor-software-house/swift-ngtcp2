// swift-tools-version: 6.0

import PackageDescription

// SwiftPM reads a dependency's manifest from git without its submodules, so this manifest cannot read
// them: the source lists below are written from the pinned submodules by scripts/sources.swift
// (the .c files in ngtcp2's and nghttp3's lib/).
// BEGIN sources, written by `mise run sources`
let ngtcp2Sources: [String] = [
    "ngtcp2/lib/ngtcp2_acktr.c",
    "ngtcp2/lib/ngtcp2_addr.c",
    "ngtcp2/lib/ngtcp2_balloc.c",
    "ngtcp2/lib/ngtcp2_bbr.c",
    "ngtcp2/lib/ngtcp2_buf.c",
    "ngtcp2/lib/ngtcp2_callbacks.c",
    "ngtcp2/lib/ngtcp2_cc.c",
    "ngtcp2/lib/ngtcp2_cid.c",
    "ngtcp2/lib/ngtcp2_conn.c",
    "ngtcp2/lib/ngtcp2_conn_info.c",
    "ngtcp2/lib/ngtcp2_conv.c",
    "ngtcp2/lib/ngtcp2_crypto.c",
    "ngtcp2/lib/ngtcp2_dcidtr.c",
    "ngtcp2/lib/ngtcp2_err.c",
    "ngtcp2/lib/ngtcp2_fmt.c",
    "ngtcp2/lib/ngtcp2_frame_chain.c",
    "ngtcp2/lib/ngtcp2_gaptr.c",
    "ngtcp2/lib/ngtcp2_idtr.c",
    "ngtcp2/lib/ngtcp2_ksl.c",
    "ngtcp2/lib/ngtcp2_log.c",
    "ngtcp2/lib/ngtcp2_map.c",
    "ngtcp2/lib/ngtcp2_mem.c",
    "ngtcp2/lib/ngtcp2_objalloc.c",
    "ngtcp2/lib/ngtcp2_opl.c",
    "ngtcp2/lib/ngtcp2_path.c",
    "ngtcp2/lib/ngtcp2_pcg.c",
    "ngtcp2/lib/ngtcp2_pkt.c",
    "ngtcp2/lib/ngtcp2_pmtud.c",
    "ngtcp2/lib/ngtcp2_ppe.c",
    "ngtcp2/lib/ngtcp2_pq.c",
    "ngtcp2/lib/ngtcp2_pv.c",
    "ngtcp2/lib/ngtcp2_qlog.c",
    "ngtcp2/lib/ngtcp2_range.c",
    "ngtcp2/lib/ngtcp2_ratelim.c",
    "ngtcp2/lib/ngtcp2_ringbuf.c",
    "ngtcp2/lib/ngtcp2_rob.c",
    "ngtcp2/lib/ngtcp2_rst.c",
    "ngtcp2/lib/ngtcp2_rtb.c",
    "ngtcp2/lib/ngtcp2_settings.c",
    "ngtcp2/lib/ngtcp2_str.c",
    "ngtcp2/lib/ngtcp2_strm.c",
    "ngtcp2/lib/ngtcp2_transport_params.c",
    "ngtcp2/lib/ngtcp2_unreachable.c",
    "ngtcp2/lib/ngtcp2_vec.c",
    "ngtcp2/lib/ngtcp2_version.c",
    "ngtcp2/lib/ngtcp2_wf.c",
    "ngtcp2/crypto/shared.c",
    "ngtcp2/crypto/boringssl/boringssl.c",
]

let nghttp3Sources: [String] = [
    "nghttp3/lib/nghttp3_balloc.c",
    "nghttp3/lib/nghttp3_buf.c",
    "nghttp3/lib/nghttp3_callbacks.c",
    "nghttp3/lib/nghttp3_conn.c",
    "nghttp3/lib/nghttp3_conv.c",
    "nghttp3/lib/nghttp3_debug.c",
    "nghttp3/lib/nghttp3_err.c",
    "nghttp3/lib/nghttp3_frame.c",
    "nghttp3/lib/nghttp3_gaptr.c",
    "nghttp3/lib/nghttp3_http.c",
    "nghttp3/lib/nghttp3_idtr.c",
    "nghttp3/lib/nghttp3_ksl.c",
    "nghttp3/lib/nghttp3_map.c",
    "nghttp3/lib/nghttp3_mem.c",
    "nghttp3/lib/nghttp3_objalloc.c",
    "nghttp3/lib/nghttp3_opl.c",
    "nghttp3/lib/nghttp3_pq.c",
    "nghttp3/lib/nghttp3_qpack.c",
    "nghttp3/lib/nghttp3_qpack_huffman.c",
    "nghttp3/lib/nghttp3_qpack_huffman_data.c",
    "nghttp3/lib/nghttp3_range.c",
    "nghttp3/lib/nghttp3_ratelim.c",
    "nghttp3/lib/nghttp3_rcbuf.c",
    "nghttp3/lib/nghttp3_ringbuf.c",
    "nghttp3/lib/nghttp3_settings.c",
    "nghttp3/lib/nghttp3_str.c",
    "nghttp3/lib/nghttp3_stream.c",
    "nghttp3/lib/nghttp3_tnode.c",
    "nghttp3/lib/nghttp3_unreachable.c",
    "nghttp3/lib/nghttp3_vec.c",
    "nghttp3/lib/nghttp3_version.c",
    "nghttp3/lib/sfparse/sfparse.c",
]
// END sources

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
    ],
    dependencies: [
        // The BoringSSL ngtcp2 links: the copy swift-nio-ssl already builds (README "BoringSSL").
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.37.5"),
    ],
    targets: [
        // ngtcp2's library and its BoringSSL crypto backend. include/openssl/ maps the headers the
        // backend includes to swift-nio-ssl's CNIOBoringSSL_*.h.
        .target(
            name: "ngtcp2",
            dependencies: [.product(name: "NIOSSL", package: "swift-nio-ssl")],
            sources: ngtcp2Sources,
            cSettings: platform + [.headerSearchPath("ngtcp2/lib"), .headerSearchPath("ngtcp2/crypto")]
        ),
        // nghttp3's library and the structured field parser it includes (lib/sfparse).
        .target(
            name: "nghttp3",
            sources: nghttp3Sources,
            cSettings: platform + [.headerSearchPath("nghttp3/lib")]
        ),
        .testTarget(name: "ngtcp2Tests", dependencies: ["ngtcp2", "nghttp3"]),
    ],
    // C11 with GNU extensions, as CMake builds ngtcp2 and nghttp3: glibc declares be64toh only then.
    cLanguageStandard: .gnu11
)
