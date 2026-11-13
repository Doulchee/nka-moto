export class SearchControlDto {
  query: string;
  type?: 'CHASSIS' | 'PLATE' | 'AUTO';
  locationText?: string;
  latitude?: number;
  longitude?: number;
  isOffline?: boolean;
  controlledAt?: string;
  offlineResult?: 'GREEN' | 'RED';
  skipAlert?: boolean;
}
