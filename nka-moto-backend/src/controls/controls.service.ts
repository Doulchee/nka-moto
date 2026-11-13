import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { hashChassis, normalizeChassis } from '../common/chassis.util';
import { SearchControlDto } from './dto/search-control.dto';

@Injectable()
export class ControlsService {
  constructor(private readonly prisma: PrismaClient) {}

  private detectType(query: string, forced?: SearchControlDto['type']): 'CHASSIS' | 'PLATE' {
    if (forced === 'CHASSIS' || forced === 'PLATE') return forced;
    const cleaned = query.replace(/\s+/g, '');
    if (/^[A-Z0-9-]{1,12}$/i.test(cleaned) && cleaned.includes('-')) return 'PLATE';
    return 'CHASSIS';
  }

  async search(authorityId: string, dto: SearchControlDto) {
    if (!dto.query?.trim()) {
      throw new BadRequestException('Saisissez un numéro de châssis ou une plaque');
    }

    const raw = dto.query.trim();
    const type = this.detectType(raw, dto.type);
    const now = new Date();

    const moto =
      type === 'CHASSIS' ? await this.findByChassis(raw) : await this.findByPlate(raw);

    const isRed = moto?.status === 'STOLEN';
    const result = isRed ? 'RED' : 'GREEN';

    const log = await this.prisma.controlLog.create({
      data: {
        authorityId,
        motorcycleId: moto?.id ?? null,
        searchedValue: type === 'CHASSIS' ? hashChassis(raw) : normalizeChassis(raw),
        result,
        locationText: dto.locationText ?? null,
        latitude: dto.latitude ?? null,
        longitude: dto.longitude ?? null,
        isOffline: dto.isOffline ?? false,
        controlledAt: dto.controlledAt ? new Date(dto.controlledAt) : now,
        syncedAt: dto.isOffline ? null : now,
      },
    });

    if (!dto.skipAlert) {
      await this.notifyAdmin({
        authorityId,
        result,
        moto,
        isOffline: dto.isOffline ?? false,
        controlledAt: dto.controlledAt ? new Date(dto.controlledAt) : now,
        offlineResult: dto.offlineResult,
      });
    }

    if (!moto || !isRed) {
      return {
        result: 'GREEN' as const,
        message: 'Moto non signalée volée',
        controlId: log.id,
        motorcycle: moto
          ? {
              id: moto.id,
              brand: moto.brand,
              model: moto.model,
              color: moto.color,
              status: moto.status,
            }
          : null,
      };
    }

    const lastValidated = moto.theftReports.find((r) => r.status === 'VALIDATED');

    return {
      result: 'RED' as const,
      message: 'Moto signalée volée',
      controlId: log.id,
      motorcycle: {
        id: moto.id,
        brand: moto.brand,
        model: moto.model,
        color: moto.color,
        status: moto.status,
      },
      theft: lastValidated
        ? {
            date: lastValidated.theftDatetime,
            location: lastValidated.locationText,
            shareCode: lastValidated.shareCode,
          }
        : null,
      owner: moto.owner
        ? {
            fullName: moto.owner.fullName,
            phone: moto.owner.phone,
          }
        : null,
    };
  }

  private async notifyAdmin(input: {
    authorityId: string;
    result: 'GREEN' | 'RED';
    moto: { id: string; brand: string; model: string; status: string } | null;
    isOffline: boolean;
    controlledAt: Date;
    offlineResult?: 'GREEN' | 'RED';
  }) {
    const agent = await this.prisma.user.findUnique({
      where: { id: input.authorityId },
      select: { fullName: true, professionalId: true },
    });
    const who = agent?.professionalId || agent?.fullName || 'Agent';
    const motoLabel = input.moto ? `${input.moto.brand} ${input.moto.model}` : 'moto inconnue';
    const when = input.controlledAt.toLocaleString('fr-FR');
    const currentRed = input.moto?.status === 'STOLEN';
    const currentResult = currentRed ? 'RED' : 'GREEN';
    const changed = input.offlineResult && input.offlineResult !== currentResult;

    const title = changed
      ? 'Contrôle hors ligne — statut changé'
      : input.isOffline
        ? 'Contrôle hors ligne synchronisé'
        : 'Contrôle agent';

    const message = changed
      ? `${who} a contrôlé ${motoLabel} le ${when} : ${input.offlineResult}. État actuel : ${currentResult}. Le pack était périmé.`
      : `${who} a contrôlé ${motoLabel} le ${when} : ${input.result}.`;

    await this.prisma.adminAlert.create({
      data: {
        type: 'OTHER',
        title,
        message,
        targetUserId: input.authorityId,
        motorcycleId: input.moto?.id ?? null,
      },
    });
  }

  private findByChassis(query: string) {
    return this.prisma.motorcycle.findFirst({
      where: { chassisHash: hashChassis(query), deletedAt: null },
      include: {
        owner: true,
        theftReports: { orderBy: { createdAt: 'desc' } },
      },
    });
  }

  private findByPlate(query: string) {
    return this.prisma.motorcycle.findFirst({
      where: { plateNumber: normalizeChassis(query), deletedAt: null },
      include: {
        owner: true,
        theftReports: { orderBy: { createdAt: 'desc' } },
      },
    });
  }

  async history(authorityId: string) {
    return this.prisma.controlLog.findMany({
      where: { authorityId },
      include: {
        motorcycle: {
          select: { id: true, brand: true, model: true, color: true, status: true },
        },
      },
      orderBy: { controlledAt: 'desc' },
      take: 200,
    });
  }

  async syncOfflineLogs(
    authorityId: string,
    items: Array<{
      searchedValue: string;
      type?: 'CHASSIS' | 'PLATE';
      result?: 'GREEN' | 'RED';
      locationText?: string;
      latitude?: number;
      longitude?: number;
      controlledAt: string;
    }>,
  ) {
    const created: Awaited<ReturnType<ControlsService['search']>>[] = [];

    for (const item of items) {
      const res = await this.search(authorityId, {
        query: item.searchedValue,
        type: item.type ?? 'AUTO',
        locationText: item.locationText,
        latitude: item.latitude,
        longitude: item.longitude,
        isOffline: true,
        controlledAt: item.controlledAt,
        offlineResult: item.result,
      });
      created.push(res);
    }

    return { synced: created.length, items: created };
  }
}
