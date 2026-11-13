export class CreateAuthorityDto {
  fullName: string;
  professionalId: string;
  phone: string;
  temporaryPassword: string;
  role?: 'AUTHORITY' | 'ADMIN';
}
