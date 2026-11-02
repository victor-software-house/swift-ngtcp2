import CNgtcp2BoringSSL
import Testing
import nghttp3
import ngtcp2

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// The package links and works: ngtcp2 writes a client's first Initial packet, which takes the TLS
/// ClientHello from BoringSSL, the Initial keys from HKDF, AES-GCM packet protection and AES header
/// protection. A BoringSSL symbol that one target renamed and another did not fails the link.
@Test func aClientWritesItsFirstInitialPacket() throws {
    let context = try #require(SSL_CTX_new(TLS_method()))
    defer { SSL_CTX_free(context) }
    #expect(ngtcp2_crypto_boringssl_configure_client_context(context) == 0)
    let ssl = try #require(SSL_new(context))
    defer { SSL_free(ssl) }
    SSL_set_connect_state(ssl)
    let alpn: [UInt8] = [2, UInt8(ascii: "h"), UInt8(ascii: "3")]
    #expect(SSL_set_alpn_protos(ssl, alpn, alpn.count) == 0)

    // ngtcp2's crypto callbacks find the connection through the SSL's app data.
    let connection = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
    connection.initialize(to: nil)
    defer { connection.deallocate() }
    var reference = ngtcp2_crypto_conn_ref(
        get_conn: { reference in
            reference!.pointee.user_data.assumingMemoryBound(to: OpaquePointer?.self).pointee
        },
        user_data: UnsafeMutableRawPointer(connection))
    #expect(SSL_set_ex_data(ssl, 0, &reference) == 1)

    var callbacks = ngtcp2_callbacks()
    callbacks.client_initial = ngtcp2_crypto_client_initial_cb
    callbacks.recv_crypto_data = ngtcp2_crypto_recv_crypto_data_cb
    callbacks.encrypt = ngtcp2_crypto_encrypt_cb
    callbacks.decrypt = ngtcp2_crypto_decrypt_cb
    callbacks.hp_mask = ngtcp2_crypto_hp_mask_cb
    callbacks.recv_retry = ngtcp2_crypto_recv_retry_cb
    callbacks.update_key = ngtcp2_crypto_update_key_cb
    callbacks.delete_crypto_aead_ctx = ngtcp2_crypto_delete_crypto_aead_ctx_cb
    callbacks.delete_crypto_cipher_ctx = ngtcp2_crypto_delete_crypto_cipher_ctx_cb
    callbacks.get_path_challenge_data2 = ngtcp2_crypto_get_path_challenge_data2_cb
    callbacks.version_negotiation = ngtcp2_crypto_version_negotiation_cb
    callbacks.rand = { destination, length, _ in _ = RAND_bytes(destination, length) }
    callbacks.get_new_connection_id2 = { _, cid, token, length, _ in
        withUnsafeMutableBytes(of: &cid!.pointee.data) { _ = RAND_bytes($0.baseAddress!.assumingMemoryBound(to: UInt8.self), length) }
        cid!.pointee.datalen = length
        withUnsafeMutableBytes(of: &token!.pointee.data) { _ = RAND_bytes($0.baseAddress!.assumingMemoryBound(to: UInt8.self), $0.count) }
        return 0
    }

    var settings = ngtcp2_settings()
    ngtcp2_settings_default_versioned(NGTCP2_SETTINGS_VERSION, &settings)
    settings.initial_ts = 1
    var parameters = ngtcp2_transport_params()
    ngtcp2_transport_params_default_versioned(NGTCP2_TRANSPORT_PARAMS_VERSION, &parameters)
    parameters.initial_max_streams_bidi = 1
    parameters.initial_max_data = 1 << 20

    var destination = ngtcp2_cid()
    var source = ngtcp2_cid()
    var random = [UInt8](repeating: 0, count: 16)
    _ = RAND_bytes(&random, random.count)
    ngtcp2_cid_init(&destination, random, 8)
    ngtcp2_cid_init(&source, Array(random[8...]), 8)

    var local = sockaddr_in()
    local.sin_family = sa_family_t(AF_INET)
    local.sin_port = in_port_t(50000).bigEndian
    local.sin_addr.s_addr = in_addr_t(0x7f00_0001).bigEndian
    var remote = local
    remote.sin_port = in_port_t(443).bigEndian
    let written = withUnsafeMutablePointer(to: &local) { local in
        withUnsafeMutablePointer(to: &remote) { remote in
            local.withMemoryRebound(to: sockaddr.self, capacity: 1) { local in
                remote.withMemoryRebound(to: sockaddr.self, capacity: 1) { remote in
                    var path = ngtcp2_path(
                        local: ngtcp2_addr(addr: local, addrlen: ngtcp2_socklen(MemoryLayout<sockaddr_in>.size)),
                        remote: ngtcp2_addr(addr: remote, addrlen: ngtcp2_socklen(MemoryLayout<sockaddr_in>.size)),
                        user_data: nil)
                    let created = ngtcp2_conn_client_new_versioned(
                        connection, &destination, &source, &path, NGTCP2_PROTO_VER_V1,
                        NGTCP2_CALLBACKS_VERSION, &callbacks, NGTCP2_SETTINGS_VERSION, &settings,
                        NGTCP2_TRANSPORT_PARAMS_VERSION, &parameters, nil, nil)
                    guard created == 0, let conn = connection.pointee else { return Int(created) }
                    ngtcp2_conn_set_tls_native_handle(conn, UnsafeMutableRawPointer(ssl))
                    var packet = [UInt8](repeating: 0, count: 1500)
                    return Int(ngtcp2_conn_write_pkt_versioned(
                        conn, nil, NGTCP2_PKT_INFO_VERSION, nil, &packet, packet.count, 2))
                }
            }
        }
    }
    if let conn = connection.pointee { ngtcp2_conn_del(conn) }
    // A client pads every datagram that carries an Initial packet to at least 1200 bytes.
    #expect(written >= 1200)
}

/// nghttp3 links, and reports the release version.h names.
@Test func nghttp3ReportsItsVersion() throws {
    let info = try #require(nghttp3_version(0))
    #expect(String(cString: info.pointee.version_str) == NGHTTP3_VERSION)
}
