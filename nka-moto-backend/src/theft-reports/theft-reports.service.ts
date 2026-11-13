import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { randomBytes } from 'crypto';
import { CreateTheftReportDto } from './dto/create-theft-report.dto';

const DECLARATION_HOURS = 48;
const FRAUD_REJECTED_LIMIT = 2;

@Injectable()
export class TheftReportsService {
  constructor(private readonly prisma: PrismaClient) {}

  private generateShareCode(): string {
    return `NK-${randomBytes(4).toString('hex').toUpperCase()}`;
  }

  private declarationDeadlineFrom(date: Date): Date {
    return new Date(date.getTime() + DECLARATION_HOURS * 60 * 60 * 1000);
  }

  private async canAutoValidate(ownerId: string, motorcycleId: string) {
    const moto = await this.prisma.motorcycle.findFirst({
      where: { id: motorcycleId, deletedAt: null },
      include: { files: true },
    });

    if (!moto) {
      return { ok: false, reason: 'Moto introuvable' };
    }
    if (moto.ownerId !== ownerId) {
      return { ok: false, reason: 'Le signaleur n’est pas le propriétaire enregistré' };
    }
    if (moto.status === 'STOLEN') {
      return { ok: false, reason: 'Moto déjà signalée volée' };
    }

    const hasProof = moto.files.some(
      (f) => f.type === 'INVOICE' || f.type === 'REGISTRATION_CARD',
    );
    if (!hasProof) {
      return { ok: false, reason: 'Preuve de propriété manquante' };
    }

    const rejectedCount = await this.prisma.theftReport.count({
      where: { reporterId: ownerId, status: 'REJECTED' },
    });
    if (rejectedCount >= FRAUD_REJECTED_LIMIT) {
      return { ok: false, reason: 'Compte avec signalements rejetés trop nombreux' };
    }

    return { ok: true, moto };
  }

  async create(reporterId: string, dto: CreateTheftReportDto) {
    const moto = await this.prisma.motorcycle.findFirst({
      where: { id: dto.motorcycleId, deletedAt: null },
      include: { files: true },
    });
    if (!moto) throw new NotFoundException('Moto introuvable');
    if (moto.ownerId !== reporterId) {
      throw new ForbiddenException('Vous ne pouvez signaler que vos propres motos');
    }
    if (moto.status === 'STOLEN') {
      throw new BadRequestException('Cette moto est déjà en recherche');
    }

    const openReport = await this.prisma.theftReport.findFirst({
      where: {
        motorcycleId: moto.id,
        status: { in: ['PENDING', 'VALIDATED'] },
      },
    });
    if (openReport) {
      throw new BadRequestException('Un signalement est déjà en cours pour cette moto');
    }

    const theftDatetime = new Date(dto.theftDatetime);
    if (Number.isNaN(theftDatetime.getTime())) {
      throw new BadRequestException('Date de vol invalide');
    }

    const check = await this.canAutoValidate(reporterId, moto.id);
    const now = new Date();
    const shareCode = this.generateShareCode();

    if (check.ok) {
      const report = await this.prisma.$transaction(async (tx) => {
        const created = await tx.theftReport.create({
          data: {
            motorcycleId: moto.id,
            reporterId,
            locationText: dto.locationText ?? null,
            latitude: dto.latitude ?? null,
            longitude: dto.longitude ?? null,
            theftDatetime,
            description: dto.description ?? null,
            status: 'VALIDATED',
            isAutoValidated: true,
            validatedAt: now,
            shareCode,
            declarationDeadline: this.declarationDeadlineFrom(now),
          },
        });

        await tx.motorcycle.update({
          where: { id: moto.id },
          data: { status: 'STOLEN' },
        });

        return created;
      });

      return {
        ...report,
        validation: 'AUTO',
        policeStatus: 'RED',
        shareUrl: `/r/${report.shareCode}`,
        declarationDeadline: report.declarationDeadline,
      };
    }

    const report = await this.prisma.theftReport.create({
      data: {
        motorcycleId: moto.id,
        reporterId,
        locationText: dto.locationText ?? null,
        latitude: dto.latitude ?? null,
        longitude: dto.longitude ?? null,
        theftDatetime,
        description: dto.description ?? null,
        status: 'PENDING',
        isAutoValidated: false,
        shareCode,
      },
    });

    return {
      ...report,
      validation: 'MANUAL_REQUIRED',
      policeStatus: 'GREEN',
      blockedReason: check.reason,
      message:
        'Signalement enregistré et bloqué en attente de validation manuelle. La moto n’apparaît pas encore en rouge.',
    };
  }

  async findMine(reporterId: string) {
    return this.prisma.theftReport.findMany({
      where: { reporterId },
      include: { motorcycle: true, files: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(userId: string, role: string, id: string) {
    const report = await this.prisma.theftReport.findUnique({
      where: { id },
      include: { motorcycle: true, files: true, sightings: true },
    });
    if (!report) throw new NotFoundException('Signalement introuvable');
    if (role === 'CITIZEN' && report.reporterId !== userId) {
      throw new ForbiddenException();
    }
    return report;
  }

  async getPublicByShareCode(shareCode: string) {
    const report = await this.prisma.theftReport.findFirst({
      where: { shareCode, status: 'VALIDATED' },
      include: {
        motorcycle: { include: { files: true } },
      },
    });
    if (!report) throw new NotFoundException('Fiche introuvable ou non publique');

    const photo = report.motorcycle.files.find((f) => f.type === 'MOTO_PHOTO');

    return {
      shareCode: report.shareCode,
      brand: report.motorcycle.brand,
      model: report.motorcycle.model,
      color: report.motorcycle.color,
      locationText: report.locationText,
      theftDatetime: report.theftDatetime,
      description: report.description,
      photoUrl: photo?.url ?? null,
      status: report.motorcycle.status,
      canReportSighting: true,
    };
  }

  async moderate(adminId: string, reportId: string, action: 'VALIDATE' | 'REJECT', reason?: string) {
    const report = await this.prisma.theftReport.findUnique({
      where: { id: reportId },
    });
    if (!report) throw new NotFoundException('Signalement introuvable');
    if (report.status !== 'PENDING') {
      throw new BadRequestException('Ce signalement n’est plus en attente');
    }

    const now = new Date();

    if (action === 'REJECT') {
      return this.prisma.theftReport.update({
        where: { id: reportId },
        data: {
          status: 'REJECTED',
          validatedById: adminId,
          validatedAt: now,
        },
      });
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const validated = await tx.theftReport.update({
        where: { id: reportId },
        data: {
          status: 'VALIDATED',
          isAutoValidated: false,
          validatedById: adminId,
          validatedAt: now,
          declarationDeadline: this.declarationDeadlineFrom(now),
        },
      });

      await tx.motorcycle.update({
        where: { id: report.motorcycleId },
        data: { status: 'STOLEN' },
      });

      return validated;
    });

    return updated;
  }

  async markRecovered(adminId: string, reportId: string) {
    const report = await this.prisma.theftReport.findUnique({
      where: { id: reportId },
    });
    if (!report) throw new NotFoundException('Signalement introuvable');
    if (report.status !== 'VALIDATED') {
      throw new BadRequestException('Seuls les signalements validés peuvent être clôturés');
    }

    const now = new Date();

    return this.prisma.$transaction(async (tx) => {
      const closed = await tx.theftReport.update({
        where: { id: reportId },
        data: {
          status: 'CLOSED',
          closedAt: now,
          validatedById: adminId,
        },
      });

      await tx.motorcycle.update({
        where: { id: report.motorcycleId },
        data: { status: 'RECOVERED' },
      });

      return closed;
    });
  }

  async attachLossDeclaration(
    userId: string,
    reportId: string,
    file: { url: string; storagePath: string; mimeType?: string; sizeBytes?: number },
  ) {
    const report = await this.prisma.theftReport.findUnique({
      where: { id: reportId },
    });
    if (!report) throw new NotFoundException('Signalement introuvable');
    if (report.reporterId !== userId) throw new ForbiddenException();
    if (report.status !== 'VALIDATED') {
      throw new BadRequestException('La déclaration de perte ne s’ajoute qu’après validation');
    }

    const now = new Date();
    if (report.declarationDeadline && now > report.declarationDeadline) {
      await this.prisma.adminAlert.create({
        data: {
          type: 'DECLARATION_MISSING',
          title: 'Déclaration de perte hors délai',
          message: `Le propriétaire a ajouté la déclaration après les ${DECLARATION_HOURS}h.`,
          targetUserId: userId,
          motorcycleId: report.motorcycleId,
        },
      });
    }

    const created = await this.prisma.file.create({
      data: {
        uploaderId: userId,
        theftReportId: reportId,
        type: 'LOSS_DECLARATION',
        url: file.url,
        storagePath: file.storagePath,
        mimeType: file.mimeType,
        sizeBytes: file.sizeBytes,
      },
    });

    await this.prisma.theftReport.update({
      where: { id: reportId },
      data: { declarationUploadedAt: now },
    });

    return created;
  }

  async stats() {
    const [inSearch, recovered, pending] = await Promise.all([
      this.prisma.motorcycle.count({ where: { status: 'STOLEN', deletedAt: null } }),
      this.prisma.motorcycle.count({ where: { status: 'RECOVERED', deletedAt: null } }),
      this.prisma.theftReport.count({ where: { status: 'PENDING' } }),
    ]);

    return {
      motosEnRecherche: inSearch,
      motosRetrouvees: recovered,
      signalementsEnAttente: pending,
    };
  }

  async feed() {
    const reports = await this.prisma.theftReport.findMany({
      where: { status: 'VALIDATED' },
      include: {
        motorcycle: { include: { files: true } },
      },
      orderBy: { validatedAt: 'desc' },
      take: 50,
    });

    return reports.map((r) => ({
      id: r.id,
      shareCode: r.shareCode,
      shareUrl: `/r/${r.shareCode}`,
      brand: r.motorcycle.brand,
      model: r.motorcycle.model,
      color: r.motorcycle.color,
      locationText: r.locationText,
      theftDatetime: r.theftDatetime,
      description: r.description,
      photoUrl: r.motorcycle.files.find((f) => f.type === 'MOTO_PHOTO')?.url ?? null,
    }));
  }
}
