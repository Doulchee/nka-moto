import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { TheftReportsService } from './theft-reports.service';
import { CreateTheftReportDto } from './dto/create-theft-report.dto';
import { ModerateTheftReportDto } from './dto/moderate-theft-report.dto';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { RolesGuard } from '../common/roles.guard';
import { Roles } from '../common/roles.decorator';

@Controller()
export class TheftReportsController {
  constructor(private readonly reports: TheftReportsService) {}

  @Get('r/:shareCode')
  getPublic(@Param('shareCode') shareCode: string) {
    return this.reports.getPublicByShareCode(shareCode);
  }

  @Get('feed')
  feed() {
    return this.reports.feed();
  }

  @Get('stats')
  stats() {
    return this.reports.stats();
  }

  @Post('theft-reports')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CITIZEN', 'ADMIN')
  create(@Req() req: any, @Body() dto: CreateTheftReportDto) {
    return this.reports.create(req.user.sub, dto);
  }

  @Get('theft-reports/mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CITIZEN', 'ADMIN')
  mine(@Req() req: any) {
    return this.reports.findMine(req.user.sub);
  }

  @Get('theft-reports/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  one(@Req() req: any, @Param('id') id: string) {
    return this.reports.findOne(req.user.sub, req.user.role, id);
  }

  @Post('theft-reports/:id/loss-declaration')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('CITIZEN', 'ADMIN')
  lossDeclaration(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: { url: string; storagePath: string; mimeType?: string; sizeBytes?: number },
  ) {
    return this.reports.attachLossDeclaration(req.user.sub, id, body);
  }

  @Patch('admin/theft-reports/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'AUTHORITY')
  moderate(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: ModerateTheftReportDto,
  ) {
    return this.reports.moderate(req.user.sub, id, dto.action, dto.reason);
  }

  @Patch('admin/theft-reports/:id/recover')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'AUTHORITY')
  recover(@Req() req: any, @Param('id') id: string) {
    return this.reports.markRecovered(req.user.sub, id);
  }
}
