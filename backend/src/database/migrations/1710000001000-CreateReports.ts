import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateReports1710000001000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`
      CREATE TABLE reports (
        report_id varchar(80) PRIMARY KEY,
        owner_firebase_uid varchar(255) NOT NULL REFERENCES users(firebase_uid) ON DELETE RESTRICT,
        client_report_id varchar(255),
        species varchar(100) NOT NULL,
        animal_count integer NOT NULL CHECK (animal_count > 0),
        village varchar(255) NOT NULL,
        symptoms jsonb NOT NULL,
        report_timestamp timestamptz NOT NULL,
        farmer_name varchar(255),
        farmer_phone varchar(64),
        clinical_signs jsonb NOT NULL DEFAULT '[]'::jsonb,
        notes text,
        latitude double precision,
        longitude double precision,
        location_address varchar(500),
        accuracy_meters double precision,
        created_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT reports_location_pair CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)),
        CONSTRAINT reports_accuracy_check CHECK (accuracy_meters IS NULL OR accuracy_meters >= 0)
      )`);
    await queryRunner.query(`CREATE UNIQUE INDEX reports_owner_client_id_uq ON reports (owner_firebase_uid, client_report_id) WHERE client_report_id IS NOT NULL`);
    await queryRunner.query(`CREATE INDEX reports_owner_created_idx ON reports (owner_firebase_uid, created_at DESC)`);
    await queryRunner.query(`CREATE INDEX reports_timestamp_idx ON reports (report_timestamp)`);
  }

  async down(queryRunner: QueryRunner) {
    await queryRunner.query('DROP INDEX reports_timestamp_idx');
    await queryRunner.query('DROP INDEX reports_owner_created_idx');
    await queryRunner.query('DROP INDEX reports_owner_client_id_uq');
    await queryRunner.query('DROP TABLE reports');
  }
}
