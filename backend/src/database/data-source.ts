import 'reflect-metadata';
import 'dotenv/config';
import { DataSource } from 'typeorm';
import { Role } from './role.entity.js';
import { User } from './user.entity.js';
import { CreateUsersAndRoles1710000000000 } from './migrations/1710000000000-CreateUsersAndRoles.js';
import { CreateReports1710000001000 } from './migrations/1710000001000-CreateReports.js';
import { CreateRoleRequests1710000002000 } from './migrations/1710000002000-CreateRoleRequests.js';

const url = process.env.DATABASE_URL;
if (!url) throw new Error('DATABASE_URL is required to run database migrations');

export default new DataSource({
  type: 'postgres',
  url,
  ssl: { rejectUnauthorized: false },
  entities: [User, Role],
  migrations: [CreateUsersAndRoles1710000000000, CreateReports1710000001000, CreateRoleRequests1710000002000],
  synchronize: false,
});
