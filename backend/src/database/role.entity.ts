import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('roles')
export class Role {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column({ type: 'varchar', length: 64, unique: true }) name!: 'farmer' | 'veterinarian' | 'surveillance_officer';
}
