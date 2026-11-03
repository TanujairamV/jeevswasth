import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddRegistrationProfile1710000003000 implements MigrationInterface {
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`ALTER TABLE users ADD COLUMN mobile_number varchar(13)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN latitude double precision`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN longitude double precision`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN state varchar(255)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN district varchar(255)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN locality varchar(255)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN postal_code varchar(32)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN formatted_address varchar(500)`);
    await queryRunner.query(`ALTER TABLE users ADD COLUMN role_details jsonb`);
    await queryRunner.query(`ALTER TABLE users ADD CONSTRAINT users_mobile_number_check CHECK (mobile_number IS NULL OR mobile_number ~ '^\\+91[6-9][0-9]{9}$')`);
    await queryRunner.query(`ALTER TABLE users ADD CONSTRAINT users_location_pair_check CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180))`);
  }

  async down(queryRunner: QueryRunner) {
    await queryRunner.query(`ALTER TABLE users DROP CONSTRAINT users_location_pair_check`);
    await queryRunner.query(`ALTER TABLE users DROP CONSTRAINT users_mobile_number_check`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN role_details`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN formatted_address`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN postal_code`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN locality`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN district`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN state`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN longitude`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN latitude`);
    await queryRunner.query(`ALTER TABLE users DROP COLUMN mobile_number`);
  }
}
