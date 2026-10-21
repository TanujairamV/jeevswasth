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
  location?: { latitude: number; longitude: number; address?: string };
}

@Injectable()
export class ReportsService {
  private readonly reports = new Map<string, LivestockHealthReport>();

  create(report: LivestockHealthReport) {
    const reportId = `report_${Date.now()}_${this.reports.size + 1}`;
    this.reports.set(reportId, report);
    return { reportId, status: 'submitted' };
  }
}
