import { BadRequestException, Body, Controller, Get, Post, Query } from '@nestjs/common';
import { LivestockHealthReport, ReportsService } from './reports.service.js';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('locations/clusters')
  clusters(@Query('since') since?: string, @Query('minimumReports') minimumReports?: string) {
    const parsedMinimum = minimumReports === undefined ? 5 : Number(minimumReports);
    if (!Number.isInteger(parsedMinimum) || parsedMinimum < 2 || parsedMinimum > 1000) {
      throw new BadRequestException({ status: 'rejected', message: 'minimumReports must be an integer between 2 and 1000' });
    }

    const parsedSince = since === undefined ? undefined : new Date(since);
    if (parsedSince && Number.isNaN(parsedSince.getTime())) {
      throw new BadRequestException({ status: 'rejected', message: 'since must be a valid ISO timestamp' });
    }

    return {
      status: 'ok',
      privacy: { minimumReports: parsedMinimum, individualCoordinates: 'redacted' },
      clusters: this.reportsService.clusters({ since: parsedSince, minimumReports: parsedMinimum }),
    };
  }

  @Post()
  create(@Body() report: Partial<LivestockHealthReport>) {
    const missing = [
      ['species', typeof report.species === 'string' && report.species.trim().length > 0],
      ['animalCount', typeof report.animalCount === 'number' && Number.isInteger(report.animalCount) && report.animalCount > 0],
      ['village', typeof report.village === 'string' && report.village.trim().length > 0],
      ['symptoms', Array.isArray(report.symptoms) && report.symptoms.length > 0],
      ['reportTimestamp', typeof report.reportTimestamp === 'string' && !Number.isNaN(Date.parse(report.reportTimestamp))],
      ['location', report.location === undefined || this.isValidLocation(report.location)],
    ].filter(([, valid]) => !valid).map(([field]) => field);

    if (missing.length > 0) {
      throw new BadRequestException({ status: 'rejected', message: 'Invalid livestock health report', missing });
    }
    return this.reportsService.create(report as LivestockHealthReport);
  }

  private isValidLocation(location: unknown): boolean {
    if (!location || typeof location !== 'object') return false;
    const candidate = location as { latitude?: unknown; longitude?: unknown; address?: unknown; accuracyMeters?: unknown };
    return (
      typeof candidate.latitude === 'number' && Number.isFinite(candidate.latitude) && candidate.latitude >= -90 && candidate.latitude <= 90 &&
      typeof candidate.longitude === 'number' && Number.isFinite(candidate.longitude) && candidate.longitude >= -180 && candidate.longitude <= 180 &&
      (candidate.address === undefined || typeof candidate.address === 'string') &&
      (candidate.accuracyMeters === undefined || (typeof candidate.accuracyMeters === 'number' && Number.isFinite(candidate.accuracyMeters) && candidate.accuracyMeters >= 0))
    );
  }
}
