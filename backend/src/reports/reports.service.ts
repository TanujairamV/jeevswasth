import { Injectable } from '@nestjs/common';

export interface LivestockHealthReport {
  species: string;
  animalCount: number;
  village: string;
  symptoms: string[];
  reportTimestamp: string;
  clientReportId?: string;
  farmerName?: string;
  farmerPhone?: string;
  clinicalSigns?: string[];
  notes?: string;
  location?: { latitude: number; longitude: number; address?: string; accuracyMeters?: number };
  ownerUid?: string;
}

export interface SurveillanceCluster {
  clusterId: string;
  latitude: number;
  longitude: number;
  reportCount: number;
  affectedAnimals: number;
  firstReportTimestamp: string;
  lastReportTimestamp: string;
  species: string[];
  privacy: { minimumReports: number; coordinatesAggregated: true };
}

@Injectable()
export class ReportsService {
  private readonly reports = new Map<string, LivestockHealthReport>();

  create(report: LivestockHealthReport) {
    const existing = report.clientReportId && [...this.reports.entries()].find(([, value]) => value.clientReportId === report.clientReportId && value.ownerUid === report.ownerUid);
    if (existing) return { reportId: existing[0], status: 'submitted', idempotent: true };
    const reportId = `report_${Date.now()}_${this.reports.size + 1}`;
    this.reports.set(reportId, report);
    return { reportId, status: 'submitted' };
  }

  mine(ownerUid: string) {
    return [...this.reports.entries()].filter(([, report]) => report.ownerUid === ownerUid).map(([reportId, report]) => ({ reportId, ...report }));
  }

  clusters(options: { since?: Date; minimumReports: number }): SurveillanceCluster[] {
    const buckets = new Map<string, LivestockHealthReport[]>();

    for (const report of this.reports.values()) {
      if (!report.location || (options.since && new Date(report.reportTimestamp) < options.since)) continue;
      const latitudeBucket = Math.round(report.location.latitude / 0.05);
      const longitudeBucket = Math.round(report.location.longitude / 0.05);
      const key = `${latitudeBucket}:${longitudeBucket}`;
      const bucket = buckets.get(key) ?? [];
      bucket.push(report);
      buckets.set(key, bucket);
    }

    return [...buckets.entries()]
      .filter(([, reports]) => reports.length >= options.minimumReports)
      .map(([key, reports]) => {
        const locations = reports.map((report) => report.location!);
        const latitude = locations.reduce((sum, location) => sum + location.latitude, 0) / locations.length;
        const longitude = locations.reduce((sum, location) => sum + location.longitude, 0) / locations.length;
        const timestamps = reports.map((report) => report.reportTimestamp).sort();

        return {
          clusterId: `cluster_${key.replace(':', '_')}`,
          latitude: Number(latitude.toFixed(4)),
          longitude: Number(longitude.toFixed(4)),
          reportCount: reports.length,
          affectedAnimals: reports.reduce((sum, report) => sum + report.animalCount, 0),
          firstReportTimestamp: timestamps[0],
          lastReportTimestamp: timestamps[timestamps.length - 1],
          species: [...new Set(reports.map((report) => report.species))].sort(),
          privacy: { minimumReports: options.minimumReports, coordinatesAggregated: true },
        };
      });
  }
}
