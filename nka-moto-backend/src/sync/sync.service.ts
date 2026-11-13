import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { createHmac } from 'crypto';

@Injectable()
export class SyncService {
  constructor(private readonly prisma: PrismaClient) {}

  private signPack(payload: unknown): string {
    const secret = process.env.SYNC_PACK_SECRET || process.env.JWT_ACCESS_SECRET || 'dev-sync-secret';
    return createHmac('sha256', secret).update(JSON.stringify(payload)).digest('hex');
  }

  async stolenPack() {
    const stolen = await this.prisma.motorcycle.findMany({
      where: { status: 'STOLEN', deletedAt: null },
      include: {
        owner: { select: { fullName: true, phone: true } },
        theftReports: {
          where: { status: 'VALIDATED' },
          orderBy: { validatedAt: 'desc' },
          take: 1,
        },
        files: {
          where: { type: 'MOTO_PHOTO' },
          take: 1,
        },
      },
    });

    const items = stolen.map((m) => {
      const report = m.theftReports[0];
      return {
        motorcycleId: m.id,
        chassisHash: m.chassisHash,
        plateNumber: m.plateNumber,
        brand: m.brand,
        model: m.model,
        color: m.color,
        ownerName: m.owner?.fullName ?? null,
        ownerPhone: m.owner?.phone ?? null,
        theftDatetime: report?.theftDatetime ?? null,
        theftLocation: report?.locationText ?? null,
        shareCode: report?.shareCode ?? null,
        photoUrl: m.files[0]?.url ?? null,
      };
    });

    const generatedAt = new Date();
    const expiresAt = new Date(generatedAt.getTime() + 12 * 60 * 60 * 1000);

    const pack = {
      version: 1,
      generatedAt,
      expiresAt,
      count: items.length,
      items,
    };

    return {
      ...pack,
      signature: this.signPack({
        generatedAt: generatedAt.toISOString(),
        expiresAt: expiresAt.toISOString(),
        count: items.length,
        hashes: items.map((i) => i.chassisHash),
      }),
    };
  }
}
