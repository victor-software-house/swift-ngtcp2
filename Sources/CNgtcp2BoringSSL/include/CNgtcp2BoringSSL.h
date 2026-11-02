#ifndef CNGTCP2BORINGSSL_H
#define CNGTCP2BORINGSSL_H

// Renames every BoringSSL symbol to CNgtcp2BoringSSL_<name>. BoringSSL's prefix_symbols.h does the
// renaming with #pragma redefine_extname, which applies only inside the translation unit or module
// that read it, so each header a caller uses is included here, after the prefix is defined.
#define BORINGSSL_PREFIX CNgtcp2BoringSSL

#include <openssl/aes.h>
#include <openssl/bio.h>
#include <openssl/chacha.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/hkdf.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#endif
