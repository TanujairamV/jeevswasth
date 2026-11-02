import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { Role } from './role.entity.js';
import { User } from './user.entity.js';
import { UserService } from './user.service.js';

@Global()
@Module({
  imports: [TypeOrmModule.forRootAsync({
    useFactory: () => {
      const url = process.env.DATABASE_URL;
      if (!url) throw new Error('DATABASE_URL is required to start the backend');
      return {
        type: 'postgres' as const,
        url,
        ssl: { rejectUnauthorized: false },
        entities: [User, Role],
        migrations: ['dist/database/migrations/*.js'],
        migrationsRun: process.env.RUN_MIGRATIONS === 'true',
        synchronize: false,
      };
    },
  }), TypeOrmModule.forFeature([User, Role])],
  providers: [UserService],
  exports: [TypeOrmModule, DataSource, UserService],
})
export class DatabaseModule {}
