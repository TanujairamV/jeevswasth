import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { AdminGuard } from './admin.guard.js';

describe('AdminGuard', () => {
  const context = {
    switchToHttp: () => ({ getRequest: () => ({ user: { id: 'user-1' } }) }),
  } as unknown as ExecutionContext;

  it('allows a database-backed administrator role', async () => {
    const guard = new AdminGuard({ hasRole: async () => true } as never);
    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('rejects a non-administrator even when authenticated', async () => {
    const guard = new AdminGuard({ hasRole: async () => false } as never);
    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(ForbiddenException);
  });
});
