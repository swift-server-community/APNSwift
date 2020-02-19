//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2020 Kyle Browning and the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
#ifndef C_APNSWIFT_BORINGSSL_SHIMS_H
#define C_APNSWIFT_BORINGSSL_SHIMS_H

// This is for instances when `swift package generate-xcodeproj` is used as CAPNSwiftBoringSSL
// is treated as a framework and requires the framework's name as a prefix.
#if __has_include(<CAPNSwiftBoringSSL/CAPNSwiftBoringSSL.h>)
#include <CAPNSwiftBoringSSL/CAPNSwiftBoringSSL.h>
#else
#include <CAPNSwiftBoringSSL.h>
#endif

// MARK:- Pointer type shims
// This section of the code handles shims that change uint8_t* pointers to
// void *s. This is done because Swift does not have the rule that C does, that
// pointers to uint8_t can safely alias any other pointer. That means that Swift
// Unsafe[Mutable]RawPointer cannot be passed to uint8_t * APIs, which is very
// awkward, so we shim these to avoid the need to call bindMemory in Swift (which is
// wrong).
int CAPNSwiftBoringSSLShims_EVP_AEAD_CTX_init(EVP_AEAD_CTX *ctx, const EVP_AEAD *aead,
                                            const void *key, size_t key_len, size_t tag_len,
                                            ENGINE *impl);

int CAPNSwiftBoringSSLShims_EVP_AEAD_CTX_seal_scatter(
    const EVP_AEAD_CTX *ctx,
    void *out,
    void *out_tag,
    size_t *out_tag_len,
    size_t max_out_tag_len,
    const void *nonce,
    size_t nonce_len,
    const void *in,
    size_t in_len,
    const void *extra_in,
    size_t extra_in_len,
    const void *ad,
    size_t ad_len);

int CAPNSwiftBoringSSLShims_EVP_AEAD_CTX_open_gather(const EVP_AEAD_CTX *ctx, void *out,
                                                   const void *nonce, size_t nonce_len,
                                                   const void *in, size_t in_len,
                                                   const void *in_tag, size_t in_tag_len,
                                                   const void *ad, size_t ad_len);

void CAPNSwiftBoringSSLShims_ED25519_keypair(void *out_public_key, void *out_private_key);

void CAPNSwiftBoringSSLShims_ED25519_keypair_from_seed(void *out_public_key,
                                                     void *out_private_key,
                                                     const void *seed);

ECDSA_SIG *CAPNSwiftBoringSSLShims_ECDSA_do_sign(const void *digest, size_t digest_len,
                                               const EC_KEY *eckey);

int CAPNSwiftBoringSSLShims_ECDSA_do_verify(const void *digest, size_t digest_len,
                                          const ECDSA_SIG *sig, const EC_KEY *eckey);

void CAPNSwiftBoringSSLShims_X25519_keypair(void *out_public_value, void *out_private_key);

void CAPNSwiftBoringSSLShims_X25519_public_from_private(void *out_public_value,
                                                      const void *private_key);

int CAPNSwiftBoringSSLShims_X25519(void *out_shared_key, const void *private_key,
                                 const void *peer_public_value);

ECDSA_SIG *CAPNSwiftBoringSSLShims_ECDSA_SIG_from_bytes(const void *in, size_t in_len);

int CAPNSwiftBoringSSLShims_ED25519_verify(const void *message, size_t message_len,
                                         const void *signature, const void *public_key);

int CAPNSwiftBoringSSLShims_ED25519_sign(void *out_sig, const void *message,
                                       size_t message_len, const void *private_key);

BIGNUM *CAPNSwiftBoringSSLShims_BN_bin2bn(const void *in, size_t len, BIGNUM *ret);

size_t CAPNSwiftBoringSSLShims_BN_bn2bin(const BIGNUM *in, void *out);

#endif  // C_APNSWIFT_BORINGSSL_SHIMS_H

