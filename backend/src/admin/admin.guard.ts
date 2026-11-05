import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { User } from '../database/user.entity.js';
import { UserService } from '../database/user.service.js';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly users: UserService) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<{ user?: User }>();
    const user = request.user;
    if (!user || !(await this.users.hasRole(user.id, 'administrator'))) {
      throw new ForbiddenException('Administrator access is required');
    }
    return true;
  }
}
