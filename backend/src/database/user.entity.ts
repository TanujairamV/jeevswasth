import { Column, CreateDateColumn, Entity, JoinTable, ManyToMany, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { Role } from './role.entity.js';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column({ name: 'firebase_uid', type: 'varchar', length: 255, unique: true }) firebaseUid!: string;
  @Column({ type: 'varchar', length: 320 }) email!: string;
  @Column({ name: 'display_name', type: 'varchar', length: 255, nullable: true }) displayName!: string | null;
  @Column({ name: 'is_active', type: 'boolean', default: true }) isActive!: boolean;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' }) createdAt!: Date;
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' }) updatedAt!: Date;

  @ManyToMany(() => Role)
  @JoinTable({ name: 'user_roles', joinColumn: { name: 'user_id' }, inverseJoinColumn: { name: 'role_id' } })
  roles!: Role[];
}
