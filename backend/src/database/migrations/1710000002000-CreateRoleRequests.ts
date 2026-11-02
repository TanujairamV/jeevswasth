import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateRoleRequests1710000002000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`CREATE TABLE role_requests (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE, role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT, status varchar(20) NOT NULL DEFAULT 'pending', created_at timestamptz NOT NULL DEFAULT now(), reviewed_at timestamptz, UNIQUE (user_id, role_id, status), CONSTRAINT role_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected')))`);
    await queryRunner.query(`CREATE INDEX role_requests_user_status_idx ON role_requests (user_id, status, created_at DESC)`);
  }
  async down(queryRunner: QueryRunner) {
    await queryRunner.query('DROP INDEX role_requests_user_status_idx');
    await queryRunner.query('DROP TABLE role_requests');
  }
}
