import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { MotorcyclesService } from './motorcycles.service';
import { CreateMotorcycleDto } from './dto/create-motorcycle.dto';
import { UpdateMotorcycleDto } from './dto/update-motorcycle.dto';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { RolesGuard } from '../common/roles.guard';
import { Roles } from '../common/roles.decorator';

@Controller('motorcycles')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MotorcyclesController {
  constructor(private readonly motorcycles: MotorcyclesService) {}

  @Post()
  @Roles('CITIZEN', 'ADMIN')
  create(@Req() req: any, @Body() dto: CreateMotorcycleDto) {
    return this.motorcycles.create(req.user.sub, dto);
  }

  @Get('mine')
  @Roles('CITIZEN', 'ADMIN')
  findMine(@Req() req: any) {
    return this.motorcycles.findMine(req.user.sub);
  }

  @Get(':id')
  findOne(@Req() req: any, @Param('id') id: string) {
    return this.motorcycles.findOne(req.user.sub, id, req.user.role);
  }

  @Patch(':id')
  @Roles('CITIZEN', 'ADMIN')
  update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateMotorcycleDto) {
    return this.motorcycles.update(req.user.sub, id, dto);
  }

  @Delete(':id')
  @Roles('CITIZEN', 'ADMIN')
  remove(@Req() req: any, @Param('id') id: string) {
    return this.motorcycles.softDelete(req.user.sub, id);
  }

  @Post(':id/files')
  @Roles('CITIZEN', 'ADMIN')
  attachFile(
    @Req() req: any,
    @Param('id') id: string,
    @Body()
    body: {
      type: 'INVOICE' | 'REGISTRATION_CARD' | 'MOTO_PHOTO' | 'PHOTO_CHASSIS' | 'OTHER';
      url: string;
      storagePath: string;
      mimeType?: string;
      sizeBytes?: number;
    },
  ) {
    return this.motorcycles.attachFileMeta(req.user.sub, id, body);
  }
}
