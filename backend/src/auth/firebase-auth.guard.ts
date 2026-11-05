import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { FirebaseAuthService } from './firebase-auth.service.js';
import { UserService } from '../database/user.service.js';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private readonly auth: FirebaseAuthService, private readonly users: UserService) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<{ headers: { authorization?: string }; user?: unknown }>();
    const header = request.headers.authorization;
    const token = header?.startsWith('Bearer ') ? header.slice(7) : '';
    const identity = await this.auth.verifyToken(token);
    const user = await this.users.findOrCreate(identity.uid, identity.email, identity.name);
    if (!user.isActive) throw new ForbiddenException('Account is disabled');
    request.user = user;
    return true;
  }
}
