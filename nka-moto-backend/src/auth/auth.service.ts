import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaClient } from '@prisma/client';
import { hashPassword, verifyPassword } from '../common/password.util';

const OTP_TTL_MINUTES = 5;
const OTP_MAX_PER_HOUR = 5;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaClient,
    private readonly jwt: JwtService,
  ) {}

  private normalizePhone(phone: string): string {
    const cleaned = phone.replace(/\s+/g, '');
    if (!cleaned.startsWith('+')) {
      throw new BadRequestException('Le numéro doit être au format international, ex: +223XXXXXXXX');
    }
    return cleaned;
  }

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async requestOtp(phoneRaw: string) {
    const phone = this.normalizePhone(phoneRaw);

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentCount = await this.prisma.otpCode.count({
      where: { phone, createdAt: { gte: oneHourAgo } },
    });

    if (recentCount >= OTP_MAX_PER_HOUR) {
      throw new BadRequestException('Trop de demandes OTP. Réessayez dans une heure.');
    }

    const code = this.generateOtp();
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

    await this.prisma.otpCode.create({
      data: { phone, code, expiresAt },
    });

    // TODO: brancher le vrai SMS (Twilio / Orange SMS Mali / etc.)
    // En dev on log le code. En prod, jamais le renvoyer dans la réponse.
    const debug = process.env.NODE_ENV === 'production' ? undefined : code;
    if (debug) console.log(`[OTP] ${phone} → ${debug}`);
    return {
      message: 'OTP envoyé',
      expiresInMinutes: OTP_TTL_MINUTES,
      debugCode: debug,
    };
  }

  async verifyOtp(phoneRaw: string, code: string, fullName?: string) {
    const phone = this.normalizePhone(phoneRaw);

    const otp = await this.prisma.otpCode.findFirst({
      where: { phone, used: false },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp || otp.code !== code) {
      throw new UnauthorizedException('Code OTP invalide');
    }
    if (otp.expiresAt.getTime() < Date.now()) {
      throw new UnauthorizedException('Code OTP expiré');
    }

    await this.prisma.otpCode.update({
      where: { id: otp.id },
      data: { used: true },
    });

    let user = await this.prisma.user.findUnique({ where: { phone } });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone,
          fullName: fullName ?? null,
          role: 'CITIZEN',
          isVerified: true,
        },
      });
    } else if (user.deletedAt) {
      throw new UnauthorizedException('Compte désactivé');
    } else if (fullName?.trim() && !user.fullName) {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { fullName: fullName.trim() },
      });
    }

    return this.issueTokens(user.id, user.role, user.phone, user.fullName);
  }

  async authorityLogin(professionalId: string, password: string) {
    if (!professionalId?.trim() || !password) {
      throw new BadRequestException('Identifiant professionnel et mot de passe requis');
    }

    const user = await this.prisma.user.findFirst({
      where: {
        professionalId: professionalId.trim(),
        role: { in: ['AUTHORITY', 'ADMIN'] },
      },
    });

    if (!user || user.deletedAt || !user.passwordHash) {
      throw new UnauthorizedException('Identifiants invalides');
    }
    if (!user.isVerified) {
      throw new UnauthorizedException('Compte non activé par l’administration');
    }

    const ok = await verifyPassword(password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    const tokens = await this.issueTokens(user.id, user.role, user.phone, user.fullName);
    return {
      ...tokens,
      user: {
        id: user.id,
        role: user.role,
        phone: user.phone,
        fullName: user.fullName,
        professionalId: user.professionalId,
        mustChangePassword: user.mustChangePassword,
      },
    };
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    if (!newPassword || newPassword.length < 8) {
      throw new BadRequestException('Le nouveau mot de passe doit faire au moins 8 caractères');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException();
    }

    const ok = await verifyPassword(currentPassword, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Mot de passe actuel incorrect');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: await hashPassword(newPassword),
        mustChangePassword: false,
      },
    });

    return { message: 'Mot de passe mis à jour' };
  }

  async refresh(refreshToken: string) {
    try {
      const payload = await this.jwt.verifyAsync(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET,
      });
      const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
      if (!user || user.deletedAt) {
        throw new UnauthorizedException();
      }
      return this.issueTokens(user.id, user.role, user.phone, user.fullName);
    } catch {
      throw new UnauthorizedException('Refresh token invalide');
    }
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        fullName: true,
        role: true,
        professionalId: true,
        isVerified: true,
        createdAt: true,
      },
    });
    if (!user || user === null) throw new UnauthorizedException();
    return user;
  }

  async updateMe(userId: string, fullName?: string) {
    if (!fullName?.trim()) throw new BadRequestException('Nom requis');
    return this.prisma.user.update({
      where: { id: userId },
      data: { fullName: fullName.trim() },
      select: { id: true, phone: true, fullName: true, role: true },
    });
  }

  private async issueTokens(userId: string, role: string, phone: string, fullName?: string | null) {
    const payload = { sub: userId, role, phone };

    const accessToken = await this.jwt.signAsync(payload, {
      secret: process.env.JWT_ACCESS_SECRET,
      expiresIn: '15m',
    });

    const refreshToken = await this.jwt.signAsync(payload, {
      secret: process.env.JWT_REFRESH_SECRET,
      expiresIn: '30d',
    });

    return {
      accessToken,
      refreshToken,
      user: { id: userId, role, phone, fullName: fullName ?? null },
    };
  }
}
