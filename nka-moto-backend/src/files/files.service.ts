import { BadRequestException, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { mkdir, writeFile } from 'fs/promises';
import { join } from 'path';

const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX_BYTES = 8 * 1024 * 1024;

@Injectable()
export class FilesService {
  private uploadDir() {
    return process.env.UPLOAD_DIR || join(process.cwd(), 'uploads');
  }

  async save(file: { buffer: Buffer; mimetype: string; originalname: string; size: number }) {
    if (!ALLOWED.has(file.mimetype)) {
      throw new BadRequestException('Formats acceptés : JPG, PNG, WEBP');
    }
    if (file.size > MAX_BYTES) {
      throw new BadRequestException('Fichier trop lourd (8 Mo max)');
    }

    const ext = file.mimetype === 'image/png' ? 'png' : file.mimetype === 'image/webp' ? 'webp' : 'jpg';
    const name = `${randomUUID()}.${ext}`;
    const dir = this.uploadDir();
    await mkdir(dir, { recursive: true });
    const storagePath = join(dir, name);
    await writeFile(storagePath, file.buffer);

    return {
      url: `/uploads/${name}`,
      storagePath,
      mimeType: file.mimetype,
      sizeBytes: file.size,
    };
  }
}
