import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { RolesGuard } from '../common/roles.guard';
import { Roles } from '../common/roles.decorator';
import { CreateAuthorityDto } from './dto/create-authority.dto';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('dashboard')
  dashboard() {
    return this.admin.dashboard();
  }

  @Get('theft-reports/pending')
  pending() {
    return this.admin.pendingReports();
  }

  @Get('users')
  users() {
    return this.admin.users();
  }

  @Get('users/:id')
  userDetail(@Param('id') id: string) {
    return this.admin.userDetail(id);
  }

  @Patch('users/:id/reset-password')
  resetPassword(@Param('id') id: string, @Body() body: { temporaryPassword: string }) {
    return this.admin.resetPassword(id, body.temporaryPassword);
  }

  @Post('authorities')
  createAuthority(@Body() dto: CreateAuthorityDto) {
    return this.admin.createAuthority(dto);
  }

  @Patch('users/:id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.admin.deactivateUser(id);
  }

  @Patch('users/:id/reactivate')
  reactivate(@Param('id') id: string) {
    return this.admin.reactivateUser(id);
  }

  @Get('motorcycles')
  motorcycles() {
    return this.admin.motorcycles();
  }

  @Get('alerts')
  alerts(@Query('unread') unread?: string) {
    return this.admin.alerts(unread === 'true');
  }

  @Patch('alerts/:id/read')
  markRead(@Param('id') id: string) {
    return this.admin.markAlertRead(id);
  }

  @Get('map')
  map() {
    return this.admin.mapPoints();
  }
}
