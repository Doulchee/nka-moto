import { Controller, Get, UseGuards } from '@nestjs/common';
import { SyncService } from './sync.service';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { RolesGuard } from '../common/roles.guard';
import { Roles } from '../common/roles.decorator';

@Controller('sync')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('AUTHORITY', 'ADMIN')
export class SyncController {
  constructor(private readonly sync: SyncService) {}

  @Get('stolen-pack')
  stolenPack() {
    return this.sync.stolenPack();
  }
}
