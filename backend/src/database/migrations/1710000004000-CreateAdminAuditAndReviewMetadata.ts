import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAdminAuditAndReviewMetadata1710000004000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`INSERT INTO roles (name) VALUES ('administrator') ON CONFLICT (name) DO NOTHING`);
    await queryRunner.query(`ALTER TABLE role_requests ADD COLUMN reviewer_id uuid REFERENCES users(id) ON DELETE SET NULL`);
    await queryRunner.query(`ALTER TABLE role_requests ADD COLUMN review_reason text`);
    await queryRunner.query(`CREATE INDEX role_requests_status_created_idx ON role_requests (status, created_at DESC)`);
    await queryRunner.query(`
      CREATE TABLE admin_audit_logs (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        admin_user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        action varchar(80) NOT NULL,
        target_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
        target_role_request_id uuid REFERENCES role_requests(id) ON DELETE SET NULL,
        previous_state jsonb,
        new_state jsonb,
        reason text,
        created_at timestamptz NOT NULL DEFAULT now()
      )
    `);
    await queryRunner.query(`CREATE INDEX admin_audit_logs_created_idx ON admin_audit_logs (created_at DESC)`);
    await queryRunner.query(`CREATE INDEX admin_audit_logs_target_user_idx ON admin_audit_logs (target_user_id, created_at DESC)`);
  }

  async down(queryRunner: QueryRunner) {
    await queryRunner.query('DROP INDEX admin_audit_logs_target_user_idx');
    await queryRunner.query('DROP INDEX admin_audit_logs_created_idx');
    await queryRunner.query('DROP TABLE admin_audit_logs');
    await queryRunner.query('DROP INDEX role_requests_status_created_idx');
    await queryRunner.query('ALTER TABLE role_requests DROP COLUMN review_reason');
    await queryRunner.query('ALTER TABLE role_requests DROP COLUMN reviewer_id');
  }
}
