/*
 * C interface to the Rust time-lock library in this folder.
 * Imported into Swift as the project's bridging header; used by Helpers/Timelock.swift.
 */

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

ssize_t timelock_encrypt(const uint8_t *public_key, size_t public_key_len, uint64_t round,
                         const uint8_t *key, uint8_t *out, size_t out_capacity);

int32_t timelock_decrypt(const uint8_t *signature, size_t signature_len,
                         const uint8_t *locked, size_t locked_len, uint8_t *out);
