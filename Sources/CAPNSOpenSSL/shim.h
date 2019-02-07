#ifndef C_APNS_OPENSSL_H
#define C_APNS_OPENSSL_H

#include <openssl/bio.h>
#include <openssl/sha.h>
#include <openssl/ecdsa.h>
#include <openssl/pem.h>

#endif

#include <openssl/opensslv.h>

#if OPENSSL_VERSION_NUMBER >= 0x10100000L
typedef struct ECDSA_SIG_st {
    BIGNUM *r;
    BIGNUM *s;
} ECDSA_SIG;
#endif
