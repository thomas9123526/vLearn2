import * as crypto from 'crypto';

/**
 * AES-256-GCM column transformer for TypeORM.
 *
 * Set FIELD_ENCRYPTION_KEY (32 random bytes as hex, e.g. `openssl rand -hex 32`)
 * in .env.  When the key is absent the transformer stores the value in plain
 * text so existing deployments can boot without the variable and the admin can
 * add it when ready.
 *
 * Stored format (base64-url, colon-delimited):
 *   <iv-12-bytes>:<tag-16-bytes>:<ciphertext>
 *
 * All parts are base64url-encoded before joining so the colon separator is
 * unambiguous.
 */

const ALGORITHM = 'aes-256-gcm';
const IV_LEN = 12;
const TAG_LEN = 16;
const MARKER = 'enc1:';

function getKey(): Buffer | null {
  const hex = process.env.FIELD_ENCRYPTION_KEY;
  if (!hex) return null;
  const buf = Buffer.from(hex, 'hex');
  if (buf.length !== 32) {
    throw new Error(
      'FIELD_ENCRYPTION_KEY must be exactly 64 hex characters (32 bytes)',
    );
  }
  return buf;
}

function encrypt(plaintext: string): string {
  const key = getKey();
  if (!key) return plaintext;

  const iv = crypto.randomBytes(IV_LEN);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv) as crypto.CipherGCM;
  const enc = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();

  return (
    MARKER +
    iv.toString('base64url') +
    ':' +
    tag.toString('base64url') +
    ':' +
    enc.toString('base64url')
  );
}

function decrypt(stored: string): string {
  if (!stored.startsWith(MARKER)) return stored;

  const key = getKey();
  if (!key) return stored;

  const payload = stored.slice(MARKER.length);
  const parts = payload.split(':');
  if (parts.length !== 3) return stored;

  const iv = Buffer.from(parts[0], 'base64url');
  const tag = Buffer.from(parts[1], 'base64url');
  const enc = Buffer.from(parts[2], 'base64url');

  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    key,
    iv,
  ) as crypto.DecipherGCM;
  decipher.setAuthTag(tag);
  return decipher.update(enc) + decipher.final('utf8');
}

/**
 * Pass this as `transformer` in @Column to get transparent field encryption.
 *
 * ```ts
 * @Column({ type: 'text', nullable: true, transformer: encryptTransformer })
 * license_serial!: string | null;
 * ```
 */
export const encryptTransformer = {
  to(value: string | null | undefined): string | null {
    if (value == null || value === '') return null;
    return encrypt(value);
  },
  from(stored: string | null | undefined): string | null {
    if (stored == null) return null;
    return decrypt(stored);
  },
};
