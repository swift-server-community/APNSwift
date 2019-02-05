/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#ifndef OpenSSLHelper_h
#define OpenSSLHelper_h

#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/md4.h>
#include <openssl/md5.h>
#include <openssl/sha.h>
#include <openssl/hmac.h>
#include <openssl/rand.h>
#include <openssl/pkcs12.h>
#include <openssl/x509v3.h>

// This is a wrapper function to wrap the call to SSL_CTX_set_alpn_select_cb() which is
// only available from OpenSSL v1.0.2. Calling this function with older version will do
// nothing.
static inline SSL_CTX_set_alpn_select_cb_wrapper(SSL_CTX *ctx,
					  int (*cb) (SSL *ssl,
								 const unsigned char **out,
								 unsigned char *outlen,
								 const unsigned char *in,
								 unsigned int inlen,
								 void *arg), void *arg) {
	#if OPENSSL_VERSION_NUMBER >= 0x10002000L
		SSL_CTX_set_alpn_select_cb(ctx, cb, arg);
	#endif // OPENSSL_VERSION_NUMBER >= 0x10002000L
}

// This is a wrapper function to wrap the call to SSL_get0_alpn_selected() which is
// only available from OpenSSL v1.0.2. Calling this function with older version will do
// nothing.
static inline SSL_get0_alpn_selected_wrapper(const SSL *ssl, const unsigned char **data,
											 unsigned int *len) {
	#if OPENSSL_VERSION_NUMBER >= 0x10002000L
		SSL_get0_alpn_selected(ssl, data, len);
	#endif // OPENSSL_VERSION_NUMBER >= 0x10002000L
}

// This is a wrapper function that allows the setting of AUTO ECDH mode when running
// on OpenSSL v1.0.2. Calling this function on an older version will have no effect.
static inline SSL_CTX_setAutoECDH(SSL_CTX *ctx) {

	#if (OPENSSL_VERSION_NUMBER >= 0x1000200fL && OPENSSL_VERSION_NUMBER < 0x10100000L)
		SSL_CTX_ctrl(ctx, SSL_CTRL_SET_ECDH_AUTO, 1, NULL);
	#endif
}

// This is a wrapper function that allows older versions of OpenSSL, that use mutable
// pointers to work alongside newer versions of it that use an immutable pointer.
static inline int SSL_EVP_digestVerifyFinal_wrapper(EVP_MD_CTX *ctx, const unsigned char *sig, size_t siglen) {

	//If version higher than 1.0.2 then it needs to use immutable version of sig
	#if (OPENSSL_VERSION_NUMBER >= 0x1000200fL)
		return EVP_DigestVerifyFinal(ctx, sig, siglen);
	#else
		// Need to make sig immutable for under 1.0.2
		return EVP_DigestVerifyFinal(ctx, sig, siglen);
	#endif

}

// Initialize OpenSSL
static inline void OpenSSL_SSL_init(void) {

        SSL_library_init();
        SSL_load_error_strings();
        OPENSSL_config(NULL);
        OPENSSL_add_all_algorithms_conf();
}

// This is a wrapper function to get server SSL_METHOD based on OpenSSL version.
static inline const SSL_METHOD *OpenSSL_server_method(void) {

	#if (OPENSSL_VERSION_NUMBER < 0x10100000L)
	        return SSLv23_server_method();
	#else
		return TLS_server_method();
	#endif
}

// This is a wrapper function to get client SSL_METHOD based on OpenSSL version.
static inline const SSL_METHOD *OpenSSL_client_method(void) {

        #if (OPENSSL_VERSION_NUMBER < 0x10100000L)
                return SSLv23_client_method();
        #else
                return TLS_client_method();
        #endif
}

static inline long OpenSSL_SSL_CTX_set_mode(SSL_CTX *context, long mode) {
        return SSL_CTX_set_mode(context, mode);
}

static inline long OpenSSL_SSL_CTX_set_options(SSL_CTX *context) {
        return SSL_CTX_set_options(context, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION);
}

// This wrapper allows for a common call for both versions of OpenSSL when creating a new HMAC_CTX.
static inline HMAC_CTX *HMAC_CTX_new_wrapper() {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                return HMAC_CTX_new();
        #else
                return malloc(sizeof(HMAC_CTX));
        #endif
}


// This wrapper allows for a common call for both versions of OpenSSL when freeing a HMAC_CTX.
static inline void HMAC_CTX_free_wrapper(HMAC_CTX *ctx) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                HMAC_CTX_free(ctx);
        #else
                free(ctx);
        #endif
}

// This wrapper avoids getting a deprecation warning with OpenSSL 1.1.x.
static inline int HMAC_Init_wrapper(HMAC_CTX *ctx, const void *key, int len, const EVP_MD *md) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                return HMAC_Init_ex(ctx, key, len, md, NULL);
        #else
                return HMAC_Init(ctx, key, len, md);
        #endif	
}

// This wrapper allows for a common call for both versions of OpenSSL when creating a new EVP_MD_CTX.
static inline EVP_MD_CTX *EVP_MD_CTX_new_wrapper(void) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                return EVP_MD_CTX_new();
        #else
                return EVP_MD_CTX_create();
        #endif
}

// This wrapper allows for a common call for both versions of OpenSSL when freeing a EVP_MD_CTX.
static inline void EVP_MD_CTX_free_wrapper(EVP_MD_CTX *ctx) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                EVP_MD_CTX_free(ctx);
        #else
                EVP_MD_CTX_destroy(ctx);
        #endif
}

// This wrapper allows for a common call for both versions of OpenSSL when creating a new EVP_CIPHER_CTX.
static inline EVP_CIPHER_CTX *EVP_CIPHER_CTX_new_wrapper(void) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                return EVP_CIPHER_CTX_new();
        #else
                return malloc(sizeof(EVP_CIPHER_CTX));
        #endif
}

// This wrapper allows for a common call for both versions of OpenSSL when resetting an EVP_CIPHER_CTX.
static inline int EVP_CIPHER_CTX_reset_wrapper(EVP_CIPHER_CTX *ctx) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                return EVP_CIPHER_CTX_reset(ctx);
        #else
                return EVP_CIPHER_CTX_cleanup(ctx);
        #endif
}

// This wrapper allows for a common call for both versions of OpenSSL when freeing a new EVP_CIPHER_CTX.
static inline void EVP_CIPHER_CTX_free_wrapper(EVP_CIPHER_CTX *ctx) {

        #if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
                EVP_CIPHER_CTX_free(ctx);
        #else
                free(ctx);
        #endif
}

// This wrapper allows for a common call for both versions of OpenSSL when setting other keys for RSA.
static inline void RSA_set_keys(RSA *rsakey, BIGNUM *n, BIGNUM *e, BIGNUM *d, BIGNUM *p, BIGNUM *q, BIGNUM *dmp1, BIGNUM *dmq1, BIGNUM *iqmp) {

	#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
		RSA_set0_key(rsakey, n, e, d);
		RSA_set0_factors(rsakey, p, q);
		RSA_set0_crt_params(rsakey, dmp1, dmq1, iqmp);
	#else
		rsakey->n = n;
		rsakey->e = e;
		rsakey->d = d;
		rsakey->p = p;
		rsakey->q = q;
		rsakey->dmp1 = dmp1;
		rsakey->dmq1 = dmq1;
		rsakey->iqmp = iqmp;
	#endif
}

static inline void EVP_PKEY_assign_wrapper(EVP_PKEY *pkey, RSA *rsakey) {

	EVP_PKEY_assign(pkey, EVP_PKEY_RSA, rsakey);
}
#endif
