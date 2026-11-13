import { PrismaClient } from '@prisma/client';
import { randomBytes, scrypt as scryptCallback } from 'crypto';
import { promisify } from 'util';

const scrypt = promisify(scryptCallback);
const prisma = new PrismaClient();

async function hashPassword(plain: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  const derived = (await scrypt(plain, salt, 64)) as Buffer;
  return `${salt}:${derived.toString('hex')}`;
}

async function main() {
  const professionalId = process.env.SEED_ADMIN_PRO_ID || 'ADM-0001';
  const phone = process.env.SEED_ADMIN_PHONE || '+22370000000';
  const password = process.env.SEED_ADMIN_PASSWORD || 'ChangeMoi#2026';
  const fullName = process.env.SEED_ADMIN_NAME || 'Administrateur Nka';

  const existing = await prisma.user.findFirst({
    where: { OR: [{ professionalId }, { phone }] },
  });
  if (existing) {
    console.log('Un compte existe déjà pour cet identifiant ou ce téléphone :', existing.id, existing.role);
    return;
  }

  const user = await prisma.user.create({
    data: {
      phone,
      fullName,
      role: 'ADMIN',
      professionalId,
      passwordHash: await hashPassword(password),
      mustChangePassword: true,
      isVerified: true,
    },
  });

  console.log('Admin créé');
  console.log('  professionalId:', professionalId);
  console.log('  password temporaire:', password);
  console.log('  id:', user.id);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
