import { Module } from '@nestjs/common';
import { createObserveModule } from '@nestjs/observe';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { ReportsController } from './reports/reports.controller.js';
import { ReportsService } from './reports/reports.service.js';
import { FirebaseAuthService } from './auth/firebase-auth.service.js';
import { FirebaseAuthGuard } from './auth/firebase-auth.guard.js';
import { DatabaseModule } from './database/database.module.js';
import { ProfileController } from './profile.controller.js';
import { AdminController } from './admin/admin.controller.js';
import { AdminService } from './admin/admin.service.js';
import { AdminGuard } from './admin/admin.guard.js';

export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    DatabaseModule,
    // Distributed tracing, auto-correlated logs, request/job metrics, error
    // telemetry, alarms, and more — out of the box. Sign up at https://observe.nestjs.com
    ObserveModule.forRoot({
      appKey: 'YOUR_APP_KEY',
      appSecret: 'YOUR_APP_SECRET',
      serviceId: 'backend',
    }),
  ],
  controllers: [AppController, ReportsController, ProfileController, AdminController],
  providers: [AppService, ReportsService, FirebaseAuthService, FirebaseAuthGuard, AdminService, AdminGuard],
})
export class AppModule {}
