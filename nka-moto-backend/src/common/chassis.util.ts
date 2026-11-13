import { createHash, createCipheriv, createDecipheriv, randomBytes } from 'crypto';

function getKey(): Buffer {
  const raw = process.env.CHASSIS_ENCRYPTION_KEY;
  if (!raw || raw.length < 32) {
    throw new Error('CHASSIS_ENCRYPTION_KEY doit faire au moins 32 caractères');
  }
  return createHash('sha256').update(raw).digest();
}

export function normalizeChassis(value: string): string {
  return value.replace(/\s+/g, '').toUpperCase();
}

export function hashChassis(value: string): string {
  return createHash('sha256').update(normalizeChassis(value)).digest('hex');
}

export function encryptChassis(value: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', getKey(), iv);
  const plain = Buffer.from(normalizeChassis(value), 'utf8');
  const encrypted = Buffer.concat([cipher.update(plain), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`;
}

export function decryptChassis(payload: string): string {
  const [ivHex, tagHex, dataHex] = payload.split(':');
  const decipher = createDecipheriv('aes-256-gcm', getKey(), Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(tagHex, 'hex'));
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(dataHex, 'hex')),
    decipher.final(),
  ]);
  return decrypted.toString('utf8');
}
