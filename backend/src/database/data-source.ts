import 'reflect-metadata';
import 'dotenv/config';
import { DataSource } from 'typeorm';
import { Role } from './role.entity.js';
import { User } from './user.entity.js';
import { CreateUsersAndRoles1710000000000 } from './migrations/1710000000000-CreateUsersAndRoles.js';
import { CreateReports1710000001000 } from './migrations/1710000001000-CreateReports.js';
import { CreateRoleRequests1710000002000 } from './migrations/1710000002000-CreateRoleRequests.js';
import { AddRegistrationProfile1710000003000 } from './migrations/1710000003000-AddRegistrationProfile.js';
import { CreateAdminAuditAndReviewMetadata1710000004000 } from './migrations/1710000004000-CreateAdminAuditAndReviewMetadata.js';

const migrationTarget = process.env.MIGRATION_TARGET;
const url = migrationTarget === 'production'
  ? process.env.DATABASE_URL_PRODUCTION
  : migrationTarget === 'local'
    ? process.env.DATABASE_URL_LOCAL
    : process.env.DATABASE_URL;

if (!url) {
  throw new Error(
    migrationTarget === 'production'
      ? 'DATABASE_URL_PRODUCTION is required for production migration commands'
      : migrationTarget === 'local'
        ? 'DATABASE_URL_LOCAL is required for local migration commands'
        : 'DATABASE_URL is required to load the TypeORM data source',
  );
}

export default new DataSource({
  type: 'postgres',
  url,
  ssl: { rejectUnauthorized: false },
  entities: [User, Role],
  migrations: [CreateUsersAndRoles1710000000000, CreateReports1710000001000, CreateRoleRequests1710000002000, AddRegistrationProfile1710000003000, CreateAdminAuditAndReviewMetadata1710000004000],
  migrationsTableName: 'typeorm_migrations',
  synchronize: false,
});
