#ifndef NGTCP2_MODULE_H
#define NGTCP2_MODULE_H

// ngtcp2_crypto_boringssl.h includes <openssl/ssl.h>. Importing the BoringSSL module first gives this
// module BoringSSL's renamed declarations instead of a second, unrenamed copy.
#include <CNgtcp2BoringSSL.h>

#include <ngtcp2/ngtcp2.h>
#include <ngtcp2/ngtcp2_crypto.h>
#include <ngtcp2/ngtcp2_crypto_boringssl.h>

#endif
