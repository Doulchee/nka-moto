import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from './prisma.service';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { MotorcyclesController } from './motorcycles/motorcycles.controller';
import { MotorcyclesService } from './motorcycles/motorcycles.service';
import { TheftReportsController } from './theft-reports/theft-reports.controller';
import { TheftReportsService } from './theft-reports/theft-reports.service';
import { ControlsController } from './controls/controls.controller';
import { ControlsService } from './controls/controls.service';
import { SyncController } from './sync/sync.controller';
import { SyncService } from './sync/sync.service';
import { AdminController } from './admin/admin.controller';
import { AdminService } from './admin/admin.service';
import { FilesController } from './files/files.controller';
import { FilesService } from './files/files.service';
import { JwtAuthGuard } from './common/jwt-auth.guard';
import { RolesGuard } from './common/roles.guard';

@Global()
@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_ACCESS_SECRET || 'dev-access',
    }),
  ],
  controllers: [
    AuthController,
    MotorcyclesController,
    TheftReportsController,
    ControlsController,
    SyncController,
    AdminController,
    FilesController,
  ],
  providers: [
    PrismaService,
    { provide: PrismaClient, useExisting: PrismaService },
    AuthService,
    MotorcyclesService,
    TheftReportsService,
    ControlsService,
    SyncService,
    AdminService,
    FilesService,
    JwtAuthGuard,
    RolesGuard,
  ],
  exports: [PrismaService, PrismaClient, JwtModule],
})
export class AppModule {}
