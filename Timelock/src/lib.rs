/*
 * Time-lock encryption for Code Locker, callable from Swift (see timelock.h).
 * Locks a 16-byte key so it can only be opened with the signature that the
 * drand network publishes for a chosen future round. A thin wrapper around
 * the tlock crate, which does the actual maths.
 */

use std::{panic, slice};

const KEY_SIZE: usize = 16;

/// Locks a 16-byte key for a drand round. Works offline.
/// Returns the number of bytes written to `out`, or -1 on failure.
#[no_mangle]
pub unsafe extern "C" fn timelock_encrypt(
    public_key: *const u8,
    public_key_len: usize,
    round: u64,
    key: *const u8,
    out: *mut u8,
    out_capacity: usize,
) -> isize {
    let public_key = slice::from_raw_parts(public_key, public_key_len);
    let key = slice::from_raw_parts(key, KEY_SIZE);

    let mut locked = vec![];
    if tlock::encrypt(&mut locked, key, public_key, round).is_err() || locked.len() > out_capacity {
        return -1;
    }

    slice::from_raw_parts_mut(out, locked.len()).copy_from_slice(&locked);
    locked.len() as isize
}

/// Opens a locked key with the round's drand signature. Writes 16 bytes to `out`.
/// Returns 0, or -1 if the signature is for a different round.
#[no_mangle]
pub unsafe extern "C" fn timelock_decrypt(
    signature: *const u8,
    signature_len: usize,
    locked: *const u8,
    locked_len: usize,
    out: *mut u8,
) -> i32 {
    let signature = slice::from_raw_parts(signature, signature_len);
    let locked = slice::from_raw_parts(locked, locked_len);

    // tlock panics on a wrong signature instead of returning an error.
    let result = panic::catch_unwind(|| {
        let mut key = vec![];
        tlock::decrypt(&mut key, locked, signature).map(|_| key)
    });

    let Ok(Ok(mut key)) = result else { return -1 };
    if key.len() > KEY_SIZE {
        return -1;
    }

    // tlock drops trailing zero bytes, so put them back.
    key.resize(KEY_SIZE, 0);
    slice::from_raw_parts_mut(out, KEY_SIZE).copy_from_slice(&key);
    0
}
