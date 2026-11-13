import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { hashPassword } from '../common/password.util';
import { CreateAuthorityDto } from './dto/create-authority.dto';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaClient) {}

  async createAuthority(dto: CreateAuthorityDto) {
    if (!dto.fullName?.trim() || !dto.professionalId?.trim() || !dto.phone?.trim() || !dto.temporaryPassword) {
      throw new BadRequestException('Nom, identifiant pro, téléphone et mot de passe temporaire requis');
    }
    if (dto.temporaryPassword.length < 8) {
      throw new BadRequestException('Mot de passe temporaire : 8 caractères minimum');
    }

    const phone = dto.phone.replace(/\s+/g, '');
    if (!phone.startsWith('+')) {
      throw new BadRequestException('Téléphone au format international, ex: +223XXXXXXXX');
    }

    const existingPhone = await this.prisma.user.findUnique({ where: { phone } });
    if (existingPhone) throw new BadRequestException('Ce numéro est déjà utilisé');

    const existingPro = await this.prisma.user.findFirst({
      where: { professionalId: dto.professionalId.trim() },
    });
    if (existingPro) throw new BadRequestException('Cet identifiant professionnel existe déjà');

    const role = dto.role === 'ADMIN' ? 'ADMIN' : 'AUTHORITY';

    const user = await this.prisma.user.create({
      data: {
        phone,
        fullName: dto.fullName.trim(),
        role,
        professionalId: dto.professionalId.trim(),
        passwordHash: await hashPassword(dto.temporaryPassword),
        mustChangePassword: true,
        isVerified: true,
      },
    });

    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      role: user.role,
      professionalId: user.professionalId,
      mustChangePassword: user.mustChangePassword,
    };
  }

  async deactivateUser(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: new Date(), isVerified: false },
    });
    return { message: 'Compte désactivé' };
  }

  async reactivateUser(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: null, isVerified: true },
    });
    return { message: 'Compte réactivé' };
  }

  async dashboard() {
    const [users, motos, stolen, recovered, pending, alertsUnread] = await Promise.all([
      this.prisma.user.count({ where: { deletedAt: null } }),
      this.prisma.motorcycle.count({ where: { deletedAt: null } }),
      this.prisma.motorcycle.count({ where: { status: 'STOLEN', deletedAt: null } }),
      this.prisma.motorcycle.count({ where: { status: 'RECOVERED', deletedAt: null } }),
      this.prisma.theftReport.count({ where: { status: 'PENDING' } }),
      this.prisma.adminAlert.count({ where: { isRead: false } }),
    ]);

    return {
      users,
      motosActives: motos,
      motosEnRecherche: stolen,
      motosRetrouvees: recovered,
      signalementsEnAttente: pending,
      alertesNonLues: alertsUnread,
    };
  }

  async pendingReports() {
    return this.prisma.theftReport.findMany({
      where: { status: 'PENDING' },
      include: {
        reporter: { select: { id: true, phone: true, fullName: true } },
        motorcycle: {
          include: { files: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async users() {
    return this.prisma.user.findMany({
      where: { deletedAt: null },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        phone: true,
        fullName: true,
        role: true,
        professionalId: true,
        isVerified: true,
        createdAt: true,
        _count: { select: { motorcycles: true, controlLogs: true } },
      },
    });
  }

  async userDetail(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        phone: true,
        fullName: true,
        role: true,
        professionalId: true,
        isVerified: true,
        mustChangePassword: true,
        dateOfBirth: true,
        gender: true,
        serviceUnit: true,
        createdAt: true,
        updatedAt: true,
        deletedAt: true,
        motorcycles: {
          where: { deletedAt: null },
          select: {
            id: true,
            brand: true,
            model: true,
            color: true,
            plateNumber: true,
            status: true,
            createdAt: true,
          },
          orderBy: { createdAt: 'desc' },
        },
        _count: {
          select: {
            motorcycles: true,
            theftReports: true,
            controlLogs: true,
          },
        },
      },
    });
    if (!user) throw new NotFoundException('Utilisateur introuvable');

    const motosEnRecherche = user.motorcycles.filter((m) => m.status === 'STOLEN').length;
    const motosRetrouvees = user.motorcycles.filter((m) => m.status === 'RECOVERED').length;

    return {
      ...user,
      stats: {
        motos: user.motorcycles.length,
        motosEnRecherche,
        motosRetrouvees,
        signalements: user._count.theftReports,
        controles: user._count.controlLogs,
      },
    };
  }

  async resetPassword(id: string, temporaryPassword: string) {
    if (!temporaryPassword || temporaryPassword.length < 8) {
      throw new BadRequestException('Mot de passe temporaire : 8 caractères minimum');
    }
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    if (user.role === 'CITIZEN') {
      throw new BadRequestException('Un citoyen n’a pas encore de mot de passe. Utiliser l’OTP.');
    }
    await this.prisma.user.update({
      where: { id },
      data: {
        passwordHash: await hashPassword(temporaryPassword),
        mustChangePassword: true,
      },
    });
    return {
      message: 'Mot de passe réinitialisé. L’agent devra le changer à la prochaine connexion.',
      temporaryPassword,
    };
  }

  async motorcycles() {
    return this.prisma.motorcycle.findMany({
      where: { deletedAt: null },
      include: {
        owner: { select: { id: true, phone: true, fullName: true } },
        files: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async alerts(onlyUnread = false) {
    return this.prisma.adminAlert.findMany({
      where: onlyUnread ? { isRead: false } : undefined,
      include: {
        targetUser: { select: { id: true, phone: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAlertRead(id: string) {
    const alert = await this.prisma.adminAlert.findUnique({ where: { id } });
    if (!alert) throw new NotFoundException('Alerte introuvable');
    return this.prisma.adminAlert.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async mapPoints() {
    const reports = await this.prisma.theftReport.findMany({
      where: {
        status: { in: ['VALIDATED', 'CLOSED'] },
        latitude: { not: null },
        longitude: { not: null },
      },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        locationText: true,
        theftDatetime: true,
        status: true,
        motorcycle: { select: { brand: true, model: true, status: true } },
      },
    });
    return reports;
  }
}
