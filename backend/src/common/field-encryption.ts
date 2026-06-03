/**
 * AES-256-CBC at-rest encryption for sensitive database columns.
 *
 * Key source: DB_FIELD_ENCRYPTION_KEY env var (first 32 UTF-8 bytes).
 * IV strategy: HMAC-SHA256(key, plaintext)[0..16] — deterministic so that
 *   UNIQUE indexes on encrypted columns remain valid (same plaintext →
 *   same ciphertext), while still producing a per-value IV that prevents
 *   rainbow-table attacks.
 *
 * Legacy-row fallback: if the stored value contains no ':' separator it
 *   is assumed to be an unencrypted row written before this feature was
 *   enabled. decryptField() returns it as-is, and the next write will
 *   encrypt it.
 *
 * Usage in a TypeORM entity:
 *   @Column({ type: 'varchar', ..., transformer: encryptedFieldTransformer })
 *   sensitiveField!: string;
 */

import { createCipheriv, createDecipheriv, createHmac } from 'crypto';

const ALG = 'aes-256-cbc';
const ENV_KEY = 'DB_FIELD_ENCRYPTION_KEY';

let _cachedKey: Buffer | null = null;

function getKey(): Buffer {
  if (_cachedKey) return _cachedKey;
  const raw = process.env[ENV_KEY] ?? '';
  // Pad to 32 bytes if shorter — in production, always set a strong 32-char key.
  const padded = raw.padEnd(32, '\0').slice(0, 32);
  _cachedKey = Buffer.from(padded, 'utf8');
  return _cachedKey;
}

function ivFor(key: Buffer, plain: string): Buffer {
  return createHmac('sha256', key).update(plain, 'utf8').digest().subarray(0, 16);
}

export function encryptField(plain: string): string {
  const key = getKey();
  const iv = ivFor(key, plain);
  const cipher = createCipheriv(ALG, key, iv);
  const enc = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
  return `${iv.toString('hex')}:${enc.toString('hex')}`;
}

export function decryptField(stored: string): string {
  const sep = stored.indexOf(':');
  if (sep < 0) return stored; // unencrypted legacy row
  const iv = Buffer.from(stored.slice(0, sep), 'hex');
  const data = Buffer.from(stored.slice(sep + 1), 'hex');
  const key = getKey();
  const decipher = createDecipheriv(ALG, key, iv);
  return Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
}

/** Drop this into any TypeORM @Column as `{ transformer: encryptedFieldTransformer }`. */
export const encryptedFieldTransformer = {
  to(plain: string | null | undefined): string | null {
    return plain == null ? null : encryptField(plain);
  },
  from(stored: string | null | undefined): string | null {
    return stored == null ? null : decryptField(stored);
  },
};
