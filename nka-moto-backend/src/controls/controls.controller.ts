import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { ControlsService } from './controls.service';
import { SearchControlDto } from './dto/search-control.dto';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { RolesGuard } from '../common/roles.guard';
import { Roles } from '../common/roles.decorator';

@Controller('controls')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('AUTHORITY', 'ADMIN')
export class ControlsController {
  constructor(private readonly controls: ControlsService) {}

  @Post('search')
  search(@Req() req: any, @Body() dto: SearchControlDto) {
    return this.controls.search(req.user.sub, dto);
  }

  @Get('history')
  history(@Req() req: any) {
    return this.controls.history(req.user.sub);
  }

  @Post('sync')
  sync(
    @Req() req: any,
    @Body()
    body: {
      items: Array<{
        searchedValue: string;
        type?: 'CHASSIS' | 'PLATE';
        locationText?: string;
        latitude?: number;
        longitude?: number;
        controlledAt: string;
      }>;
    },
  ) {
    return this.controls.syncOfflineLogs(req.user.sub, body.items ?? []);
  }
}
