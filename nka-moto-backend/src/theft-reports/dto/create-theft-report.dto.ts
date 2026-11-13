export class CreateTheftReportDto {
  motorcycleId: string;
  locationText?: string;
  latitude?: number;
  longitude?: number;
  theftDatetime: string;
  description?: string;
}
