import { BadRequestException, Body, Controller, Post } from '@nestjs/common';
import { LivestockHealthReport, ReportsService } from './reports.service.js';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  create(@Body() report: Partial<LivestockHealthReport>) {
    const missing = [
      ['species', typeof report.species === 'string' && report.species.trim().length > 0],
      ['animalCount', typeof report.animalCount === 'number' && Number.isInteger(report.animalCount) && report.animalCount > 0],
      ['village', typeof report.village === 'string' && report.village.trim().length > 0],
      ['symptoms', Array.isArray(report.symptoms) && report.symptoms.length > 0],
      ['reportTimestamp', typeof report.reportTimestamp === 'string' && !Number.isNaN(Date.parse(report.reportTimestamp))],
    ].filter(([, valid]) => !valid).map(([field]) => field);

    if (missing.length > 0) {
      throw new BadRequestException({ status: 'rejected', message: 'Invalid livestock health report', missing });
    }
    return this.reportsService.create(report as LivestockHealthReport);
  }
}
