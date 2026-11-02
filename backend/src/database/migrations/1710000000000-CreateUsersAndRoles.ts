import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateUsersAndRoles1710000000000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`);
    await queryRunner.query(`CREATE TABLE roles (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name varchar(64) NOT NULL UNIQUE)`);
    await queryRunner.query(`CREATE TABLE users (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), firebase_uid varchar(255) NOT NULL UNIQUE, email varchar(320) NOT NULL, display_name varchar(255), is_active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now())`);
    await queryRunner.query(`CREATE TABLE user_roles (user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE, role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE, PRIMARY KEY (user_id, role_id))`);
    await queryRunner.query(`INSERT INTO roles (name) VALUES ('farmer'), ('veterinarian'), ('surveillance_officer') ON CONFLICT (name) DO NOTHING`);
  }

  async down(queryRunner: QueryRunner) {
    await queryRunner.query('DROP TABLE user_roles');
    await queryRunner.query('DROP TABLE users');
    await queryRunner.query('DROP TABLE roles');
  }
}
