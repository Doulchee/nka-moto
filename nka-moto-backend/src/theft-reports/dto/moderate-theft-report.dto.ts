export class ModerateTheftReportDto {
  action: 'VALIDATE' | 'REJECT';
  reason?: string;
}
