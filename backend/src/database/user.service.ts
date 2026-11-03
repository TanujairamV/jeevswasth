import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity.js';

export interface UserProfileUpdate {
  displayName: string;
  mobileNumber: string | null;
  latitude: number | null;
  longitude: number | null;
  state: string | null;
  district: string | null;
  locality: string | null;
  postalCode: string | null;
  formattedAddress: string | null;
  roleDetails: Record<string, unknown> | null;
}

@Injectable()
export class UserService {
  constructor(@InjectRepository(User) private readonly users: Repository<User>) {}

  async findOrCreate(firebaseUid: string, email?: string, displayName?: string) {
    let user = await this.users.findOne({ where: { firebaseUid } });
    if (!user) {
      user = this.users.create({
        firebaseUid,
        email: email ?? `${firebaseUid}@unknown.invalid`,
        displayName: displayName ?? null,
      });
    } else {
      if (email) user.email = email;
      if (displayName) user.displayName = displayName;
    }
    return this.users.save(user);
  }

  async updateProfile(userId: string, profile: UserProfileUpdate) {
    const user = await this.users.findOneByOrFail({ id: userId });
    Object.assign(user, {
      displayName: profile.displayName,
      mobileNumber: profile.mobileNumber,
      latitude: profile.latitude,
      longitude: profile.longitude,
      state: profile.state,
      district: profile.district,
      locality: profile.locality,
      postalCode: profile.postalCode,
      formattedAddress: profile.formattedAddress,
      roleDetails: profile.roleDetails,
    });
    return this.users.save(user);
  }

  async getRoleProfile(userId: string) {
    const roles = await this.users.query(
      `SELECT r.name FROM roles r JOIN user_roles ur ON ur.role_id = r.id WHERE ur.user_id = $1 ORDER BY r.name`,
      [userId],
    );
    const pending = await this.users.query(
      `SELECT r.name FROM role_requests rr JOIN roles r ON r.id = rr.role_id WHERE rr.user_id = $1 AND rr.status = 'pending' ORDER BY rr.created_at DESC`,
      [userId],
    );
    return {
      roles: roles.map((row: { name: string }) => row.name),
      pendingRoleRequests: pending.map((row: { name: string }) => row.name),
    };
  }

  async requestRole(userId: string, role: string) {
    if (!['farmer', 'veterinarian', 'surveillance_officer'].includes(role)) return null;
    const assigned = await this.users.query(
      `SELECT 1 FROM user_roles ur JOIN roles r ON r.id = ur.role_id WHERE ur.user_id = $1 AND r.name = $2`,
      [userId, role],
    );
    if (assigned.length > 0) return 'assigned';
    if (role === 'farmer') {
      await this.users.query(
        `INSERT INTO user_roles (user_id, role_id) SELECT $1, id FROM roles WHERE name = $2 ON CONFLICT DO NOTHING`,
        [userId, role],
      );
      return 'assigned';
    }
    await this.users.query(
      `INSERT INTO role_requests (user_id, role_id) SELECT $1, id FROM roles WHERE name = $2 ON CONFLICT (user_id, role_id, status) DO NOTHING`,
      [userId, role],
    );
    return 'pending';
  }
}
