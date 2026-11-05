import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { AdminGuard } from './admin.guard.js';
import { AdminService } from './admin.service.js';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard.js';
import { User } from '../database/user.entity.js';

@Controller('admin')
@UseGuards(FirebaseAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('overview') overview() { return this.admin.overview(); }
  @Get('applications') applications(@Query() query: Record<string, string>) { return this.admin.applications(query); }
  @Get('applications/:id') application(@Param('id') id: string) { return this.admin.application(id); }
  @Post('applications/:id/approve') approve(@Param('id') id: string, @Req() request: { user: User }) { return this.admin.approve(id, request.user.id); }
  @Post('applications/:id/reject') reject(@Param('id') id: string, @Body() body: { reason?: unknown }, @Req() request: { user: User }) { return this.admin.reject(id, typeof body?.reason === 'string' ? body.reason : '', request.user.id); }
  @Get('users') users(@Query() query: Record<string, string>) { return this.admin.users(query); }
  @Get('users/:id') user(@Param('id') id: string) { return this.admin.user(id); }
  @Patch('users/:id/status') status(@Param('id') id: string, @Body() body: { active?: unknown }, @Req() request: { user: User }) { return this.admin.setUserStatus(id, request.user.id, body?.active === true); }
  @Get('reports') reports(@Query() query: Record<string, string>) { return this.admin.reports(query); }
  @Get('reports/:id') report(@Param('id') id: string) { return this.admin.report(id); }
  @Get('audit-logs') auditLogs(@Query() query: Record<string, string>) { return this.admin.auditLogs(query); }
}
