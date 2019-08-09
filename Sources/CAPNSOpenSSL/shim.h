#ifndef C_APNS_OPENSSL_H
#define C_APNS_OPENSSL_H

#include <openssl/bio.h>
#include <openssl/sha.h>
#include <openssl/ecdsa.h>
#include <openssl/pem.h>
#include <openssl/opensslv.h>
#include <openssl/crypto.h>


/// ECDSA_SIG_get0() returns internal pointers the r and s values contained in
/// sig and stores them in *pr and *ps, respectively. The pointer pr or ps can
/// be NULL, in which case the corresponding value is not returned.
static inline void CAPNSOpenSSL_ECDSA_SIG_get0(const ECDSA_SIG *sig, const BIGNUM **pr, const BIGNUM **ps) {
#if (OPENSSL_VERSION_NUMBER < 0x10100000L) || defined(LIBRESSL_VERSION_NUMBER)
        if (pr != NULL)
            *pr = sig->r;
        if (ps != NULL)
            *ps = sig->s;
#else
        ECDSA_SIG_get0(sig, pr, ps);
#endif
}

#endif
