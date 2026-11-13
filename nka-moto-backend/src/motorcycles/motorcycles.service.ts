import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { CreateMotorcycleDto } from './dto/create-motorcycle.dto';
import { UpdateMotorcycleDto } from './dto/update-motorcycle.dto';
import { decryptChassis, encryptChassis, hashChassis, normalizeChassis } from '../common/chassis.util';

@Injectable()
export class MotorcyclesService {
  constructor(private readonly prisma: PrismaClient) {}

  private maskChassis(normalized: string): string {
    if (normalized.length <= 6) return '••••';
    return `${normalized.slice(0, 3)}••••${normalized.slice(-3)}`;
  }

  private toPublic(moto: {
    chassisNumber: string;
    chassisHash: string;
    [key: string]: unknown;
  }) {
    const normalized = this.safeDecryptOrHashFallback(moto.chassisNumber, moto.chassisHash);
    const { chassisNumber, chassisHash, ...rest } = moto;
    return {
      ...rest,
      chassisMasked: this.maskChassis(normalized),
    };
  }

  private safeDecryptOrHashFallback(encrypted: string, hash: string): string {
    try {
      return decryptChassis(encrypted);
    } catch {
      return hash.slice(0, 6).toUpperCase();
    }
  }

  async create(ownerId: string, dto: CreateMotorcycleDto) {
    if (!dto.brand?.trim() || !dto.model?.trim() || !dto.chassisNumber?.trim()) {
      throw new BadRequestException('Marque, modèle et numéro de châssis sont obligatoires');
    }

    const chassisHash = hashChassis(dto.chassisNumber);

    const activeSameChassis = await this.prisma.motorcycle.findFirst({
      where: { chassisHash, deletedAt: null },
    });

    if (activeSameChassis) {
      throw new BadRequestException(
        'Une moto active porte déjà ce numéro de châssis',
      );
    }

    const previous = await this.prisma.motorcycle.findMany({
      where: { chassisHash, deletedAt: { not: null } },
      orderBy: { deletedAt: 'desc' },
      take: 5,
    });

    const moto = await this.prisma.motorcycle.create({
      data: {
        ownerId,
        brand: dto.brand.trim(),
        model: dto.model.trim(),
        color: dto.color?.trim() || null,
        chassisNumber: encryptChassis(dto.chassisNumber),
        chassisHash,
        plateNumber: dto.plateNumber ? normalizeChassis(dto.plateNumber) : null,
        registrationYear: dto.registrationYear ?? null,
        status: 'REGISTERED',
      },
    });

    if (previous.length > 0) {
      await this.prisma.adminAlert.create({
        data: {
          type: 'RE_REGISTRATION',
          title: 'Réenregistrement de châssis',
          message: `Le châssis ${this.maskChassis(normalizeChassis(dto.chassisNumber))} a été réenregistré. ${previous.length} fiche(s) soft-deleted existaient déjà.`,
          targetUserId: ownerId,
          motorcycleId: moto.id,
        },
      });
    }

    return this.toPublic(moto);
  }

  async findMine(ownerId: string) {
    const list = await this.prisma.motorcycle.findMany({
      where: { ownerId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: { files: true },
    });
    return list.map((m) => this.toPublic(m));
  }

  async findOne(ownerId: string, id: string, role: string) {
    const moto = await this.prisma.motorcycle.findFirst({
      where: { id, deletedAt: null },
      include: { files: true, theftReports: true },
    });
    if (!moto) throw new NotFoundException('Moto introuvable');
    if (role === 'CITIZEN' && moto.ownerId !== ownerId) {
      throw new ForbiddenException();
    }
    return this.toPublic(moto);
  }

  async update(ownerId: string, id: string, dto: UpdateMotorcycleDto) {
    const moto = await this.prisma.motorcycle.findFirst({
      where: { id, ownerId, deletedAt: null },
    });
    if (!moto) throw new NotFoundException('Moto introuvable');
    if (moto.status === 'STOLEN') {
      throw new BadRequestException('Impossible de modifier une moto signalée volée');
    }

    const updated = await this.prisma.motorcycle.update({
      where: { id },
      data: {
        brand: dto.brand?.trim(),
        model: dto.model?.trim(),
        color: dto.color?.trim(),
        plateNumber: dto.plateNumber ? normalizeChassis(dto.plateNumber) : undefined,
        registrationYear: dto.registrationYear,
      },
    });

    return this.toPublic(updated);
  }

  async softDelete(ownerId: string, id: string) {
    const moto = await this.prisma.motorcycle.findFirst({
      where: { id, ownerId, deletedAt: null },
    });
    if (!moto) throw new NotFoundException('Moto introuvable');
    if (moto.status === 'STOLEN') {
      throw new BadRequestException('Impossible de supprimer une moto actuellement recherchée');
    }

    await this.prisma.motorcycle.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    return { message: 'Moto supprimée (conservée en archive interne)' };
  }

  async attachFileMeta(
    ownerId: string,
    motorcycleId: string,
    file: {
      type: 'INVOICE' | 'REGISTRATION_CARD' | 'MOTO_PHOTO' | 'PHOTO_CHASSIS' | 'OTHER';
      url: string;
      storagePath: string;
      mimeType?: string;
      sizeBytes?: number;
    },
  ) {
    const moto = await this.prisma.motorcycle.findFirst({
      where: { id: motorcycleId, ownerId, deletedAt: null },
    });
    if (!moto) throw new NotFoundException('Moto introuvable');

    return this.prisma.file.create({
      data: {
        uploaderId: ownerId,
        motorcycleId,
        type: file.type,
        url: file.url,
        storagePath: file.storagePath,
        mimeType: file.mimeType,
        sizeBytes: file.sizeBytes,
      },
    });
  }
}
