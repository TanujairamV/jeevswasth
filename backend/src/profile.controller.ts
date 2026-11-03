import { BadRequestException, Body, Controller, Get, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from './auth/firebase-auth.guard.js';
import { User } from './database/user.entity.js';
import { UserProfileUpdate, UserService } from './database/user.service.js';

@Controller('me')
export class ProfileController {
  constructor(private readonly users: UserService) {}

  @Get()
  @UseGuards(FirebaseAuthGuard)
  async profile(@Req() request: { user: User }) {
    const profile = await this.users.getRoleProfile(request.user.id);
    return {
      status: 'ok',
      user: {
        firebaseUid: request.user.firebaseUid,
        email: request.user.email,
        displayName: request.user.displayName,
        roles: profile.roles,
        pendingRoleRequests: profile.pendingRoleRequests,
      },
    };
  }

  @Post('role-requests')
  @UseGuards(FirebaseAuthGuard)
  async requestRole(@Body() body: unknown, @Req() request: { user: User }) {
    const role = body && typeof body === 'object' ? (body as Record<string, unknown>).role : null;
    if (typeof role !== 'string' || !['farmer', 'veterinarian', 'surveillance_officer'].includes(role)) {
      throw new BadRequestException('Invalid role selection.');
    }
    return { status: 'ok', role, assignment: await this.users.requestRole(request.user.id, role) };
  }

  @Patch('profile')
  @UseGuards(FirebaseAuthGuard)
  async update(@Body() body: unknown, @Req() request: { user: User }) {
    const profile = this.parseProfile(body);
    const user = await this.users.updateProfile(request.user.id, profile);
    return {
      status: 'ok',
      user: {
        firebaseUid: user.firebaseUid,
        email: user.email,
        displayName: user.displayName,
        mobileNumber: user.mobileNumber,
        location: this.locationFromUser(user),
        roleDetails: user.roleDetails,
      },
    };
  }

  private parseProfile(body: unknown): UserProfileUpdate {
    if (!body || typeof body !== 'object') throw new BadRequestException('Profile must be an object.');
    const value = body as Record<string, unknown>;
    const displayName = value.displayName;
    const mobileNumber = value.mobileNumber;
    const location = value.location;
    const roleDetails = value.roleDetails;

    if (typeof displayName !== 'string' || displayName.trim().length === 0 || displayName.length > 255) {
      throw new BadRequestException('Full name is required.');
    }
    if (mobileNumber !== null && mobileNumber !== undefined && (typeof mobileNumber !== 'string' || !/^\+91[6-9][0-9]{9}$/.test(mobileNumber))) {
      throw new BadRequestException('Enter a valid Indian mobile number.');
    }
    if (roleDetails !== null && roleDetails !== undefined && (!roleDetails || typeof roleDetails !== 'object' || Array.isArray(roleDetails))) {
      throw new BadRequestException('Role details must be an object.');
    }

    const parsedLocation = this.parseLocation(location);
    return {
      displayName: displayName.trim(),
      mobileNumber: mobileNumber === undefined ? null : mobileNumber,
      latitude: parsedLocation.latitude,
      longitude: parsedLocation.longitude,
      state: parsedLocation.state,
      district: parsedLocation.district,
      locality: parsedLocation.locality,
      postalCode: parsedLocation.postalCode,
      formattedAddress: parsedLocation.formattedAddress,
      roleDetails: roleDetails === undefined ? null : roleDetails as Record<string, unknown>,
    };
  }

  private parseLocation(value: unknown) {
    if (value === null || value === undefined) {
      return { latitude: null, longitude: null, state: null, district: null, locality: null, postalCode: null, formattedAddress: null };
    }
    if (typeof value !== 'object' || Array.isArray(value)) throw new BadRequestException('Location must be an object.');
    const location = value as Record<string, unknown>;
    const latitude = location.latitude;
    const longitude = location.longitude;
    if (typeof latitude !== 'number' || !Number.isFinite(latitude) || latitude < -90 || latitude > 90 || typeof longitude !== 'number' || !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      throw new BadRequestException('Location coordinates are invalid.');
    }
    const text = (key: string, max: number) => {
      const field = location[key];
      if (field === undefined || field === null || field === '') return null;
      if (typeof field !== 'string' || field.length > max) throw new BadRequestException(`Location field ${key} is invalid.`);
      return field.trim() || null;
    };
    return {
      latitude,
      longitude,
      state: text('state', 255),
      district: text('district', 255),
      locality: text('locality', 255),
      postalCode: text('postalCode', 32),
      formattedAddress: text('formattedAddress', 500),
    };
  }

  private locationFromUser(user: User) {
    if (user.latitude === null || user.longitude === null) return null;
    return {
      latitude: user.latitude,
      longitude: user.longitude,
      state: user.state,
      district: user.district,
      locality: user.locality,
      postalCode: user.postalCode,
      formattedAddress: user.formattedAddress,
    };
  }
}
