import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';

const APPROVABLE_ROLES = ['veterinarian', 'surveillance_officer'] as const;
type ApprovableRole = (typeof APPROVABLE_ROLES)[number];

export interface AdminPageQuery {
  page: number;
  pageSize: number;
  search?: string;
  role?: string;
  status?: string;
  sort?: string;
  order?: 'asc' | 'desc';
  from?: string;
  to?: string;
  species?: string;
  region?: string;
}

function page(query: Partial<AdminPageQuery>): AdminPageQuery {
  const pageNumber = Number(query.page ?? 1);
  const pageSize = Number(query.pageSize ?? 20);
  if (!Number.isInteger(pageNumber) || pageNumber < 1 || !Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) {
    throw new BadRequestException('page must be positive and pageSize must be between 1 and 100');
  }
  return {
    page: pageNumber,
    pageSize,
    search: query.search?.trim() || undefined,
    role: query.role?.trim() || undefined,
    status: query.status?.trim() || undefined,
    sort: query.sort?.trim() || undefined,
    order: query.order === 'asc' ? 'asc' : 'desc',
    from: query.from,
    to: query.to,
    species: query.species?.trim() || undefined,
    region: query.region?.trim() || undefined,
  };
}

function paged<T>(rows: T[], total: number, query: AdminPageQuery) {
  return { items: rows, page: query.page, pageSize: query.pageSize, total, totalPages: Math.max(1, Math.ceil(total / query.pageSize)) };
}

function json(value: unknown) {
  return value === null || value === undefined ? null : JSON.stringify(value);
}

@Injectable()
export class AdminService {
  constructor(private readonly dataSource: DataSource) {}

  async overview() {
    return this.dataSource.query(`
      WITH role_counts AS (
        SELECT r.name AS role, COUNT(DISTINCT ur.user_id)::int AS count
        FROM roles r LEFT JOIN user_roles ur ON ur.role_id = r.id
        GROUP BY r.name
      ), user_days AS (
        SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day, COUNT(*)::int AS count
        FROM users WHERE created_at >= now() - interval '30 days'
        GROUP BY 1 ORDER BY 1
      ), report_days AS (
        SELECT to_char(date_trunc('day', report_timestamp), 'YYYY-MM-DD') AS day, COUNT(*)::int AS count
        FROM reports WHERE report_timestamp >= now() - interval '30 days'
        GROUP BY 1 ORDER BY 1
      ), species_counts AS (
        SELECT species, COUNT(*)::int AS count FROM reports GROUP BY species ORDER BY count DESC LIMIT 10
      ), region_counts AS (
        SELECT village AS region, COUNT(*)::int AS count FROM reports GROUP BY village ORDER BY count DESC LIMIT 10
      ), recent_activity AS (
        SELECT report_id AS id, 'report.submitted' AS action, report_timestamp AS created_at, village AS target FROM reports ORDER BY report_timestamp DESC LIMIT 8
      )
      SELECT
        (SELECT COUNT(*)::int FROM users) AS total_users,
        (SELECT COUNT(*)::int FROM users WHERE is_active) AS active_users,
        (SELECT COUNT(*)::int FROM users WHERE NOT is_active) AS inactive_users,
        (SELECT COUNT(*)::int FROM users u JOIN user_roles ur ON ur.user_id = u.id JOIN roles r ON r.id = ur.role_id WHERE r.name = 'farmer') AS total_farmers,
        (SELECT COUNT(*)::int FROM users u JOIN user_roles ur ON ur.user_id = u.id JOIN roles r ON r.id = ur.role_id WHERE r.name = 'veterinarian') AS total_veterinarians,
        (SELECT COUNT(*)::int FROM users u JOIN user_roles ur ON ur.user_id = u.id JOIN roles r ON r.id = ur.role_id WHERE r.name = 'surveillance_officer') AS total_surveillance_officers,
        (SELECT COUNT(*)::int FROM role_requests WHERE status = 'pending') AS pending_applications,
        (SELECT COUNT(*)::int FROM reports) AS total_reports,
        (SELECT COUNT(*)::int FROM reports WHERE report_timestamp >= now() - interval '7 days') AS recent_reports,
        (SELECT COALESCE(json_agg(role_counts ORDER BY role), '[]'::json) FROM role_counts) AS role_distribution,
        (SELECT COALESCE(json_agg(user_days ORDER BY day), '[]'::json) FROM user_days) AS user_registration_trend,
        (SELECT COALESCE(json_agg(report_days ORDER BY day), '[]'::json) FROM report_days) AS report_trend,
        (SELECT COALESCE(json_agg(species_counts), '[]'::json) FROM species_counts) AS reports_by_species,
        (SELECT COALESCE(json_agg(region_counts), '[]'::json) FROM region_counts) AS reports_by_region,
        (SELECT COALESCE(json_agg(recent_activity ORDER BY created_at DESC), '[]'::json) FROM recent_activity) AS recent_activity,
        (SELECT COALESCE(json_agg(pending_preview ORDER BY created_at DESC), '[]'::json) FROM (SELECT rr.id, u.display_name, u.email, r.name AS requested_role, rr.created_at FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE rr.status = 'pending' ORDER BY rr.created_at DESC LIMIT 5) pending_preview) AS pending_preview
    `).then((rows: Array<Record<string, unknown>>) => rows[0]);
  }

  async applications(input: Partial<AdminPageQuery>) {
    const query = page(input);
    const where: string[] = ["rr.status = 'pending'", "r.name IN ('veterinarian', 'surveillance_officer')"];
    const values: unknown[] = [];
    if (query.search) {
      values.push(`%${query.search}%`);
      where.push(`(COALESCE(u.display_name, '') ILIKE $${values.length} OR u.email ILIKE $${values.length})`);
    }
    if (query.role && APPROVABLE_ROLES.includes(query.role as ApprovableRole)) {
      values.push(query.role);
      where.push(`r.name = $${values.length}`);
    }
    const predicate = where.join(' AND ');
    const count = await this.dataSource.query(`SELECT COUNT(*)::int AS count FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE ${predicate}`, values);
    const sort = query.sort === 'applicant' ? 'u.display_name' : query.sort === 'role' ? 'r.name' : 'rr.created_at';
    const offset = (query.page - 1) * query.pageSize;
    const rows = await this.dataSource.query(`
      SELECT rr.id, rr.status, rr.created_at, rr.reviewed_at, rr.review_reason,
             u.id AS user_id, u.display_name, u.email, u.mobile_number, u.role_details,
             u.state, u.district, r.name AS requested_role
      FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id
      WHERE ${predicate} ORDER BY ${sort} ${query.order === 'asc' ? 'ASC' : 'DESC'}
      LIMIT $${values.length + 1} OFFSET $${values.length + 2}`, [...values, query.pageSize, offset]);
    return paged(rows.map((row: Record<string, unknown>) => this.formatApplication(row)), Number(count[0].count), query);
  }

  async application(id: string) {
    const rows = await this.dataSource.query(`
      SELECT rr.id, rr.status, rr.created_at, rr.reviewed_at, rr.review_reason,
             u.id AS user_id, u.firebase_uid, u.display_name, u.email, u.mobile_number,
             u.role_details, u.state, u.district, u.locality, u.postal_code, u.formatted_address,
             r.name AS requested_role
      FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE rr.id = $1`, [id]);
    if (!rows[0]) throw new NotFoundException('Role application not found');
    return this.formatApplication(rows[0]);
  }

  async approve(id: string, adminUserId: string) {
    return this.dataSource.transaction(async (manager) => {
      const request = await this.lockRequest(manager, id);
      if (request.user_id === adminUserId) throw new ConflictException('An administrator cannot approve their own application');
      if (!APPROVABLE_ROLES.includes(request.requested_role as ApprovableRole)) throw new BadRequestException('This role cannot be approved through the application workflow');
      await manager.query(`INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [request.user_id, request.role_id]);
      await manager.query(`UPDATE role_requests SET status = 'approved', reviewer_id = $1, reviewed_at = now(), review_reason = NULL WHERE id = $2`, [adminUserId, id]);
      await this.audit(manager, adminUserId, 'application.approved', request.user_id, id, { status: 'pending' }, { status: 'approved', role: request.requested_role });
      return { status: 'approved', applicationId: id, role: request.requested_role };
    });
  }

  async reject(id: string, adminUserId: string, reason: string) {
    const trimmed = reason.trim();
    if (trimmed.length < 3 || trimmed.length > 2000) throw new BadRequestException('A rejection reason between 3 and 2000 characters is required');
    return this.dataSource.transaction(async (manager) => {
      const request = await this.lockRequest(manager, id);
      if (request.user_id === adminUserId) throw new ConflictException('An administrator cannot reject their own application');
      if (!APPROVABLE_ROLES.includes(request.requested_role as ApprovableRole)) throw new BadRequestException('This role cannot be rejected through the application workflow');
      await manager.query(`UPDATE role_requests SET status = 'rejected', reviewer_id = $1, reviewed_at = now(), review_reason = $2 WHERE id = $3`, [adminUserId, trimmed, id]);
      await this.audit(manager, adminUserId, 'application.rejected', request.user_id, id, { status: 'pending' }, { status: 'rejected', role: request.requested_role }, trimmed);
      return { status: 'rejected', applicationId: id };
    });
  }

  async users(input: Partial<AdminPageQuery>) {
    const query = page(input);
    const where: string[] = [];
    const values: unknown[] = [];
    if (query.search) { values.push(`%${query.search}%`); where.push(`(COALESCE(u.display_name, '') ILIKE $${values.length} OR u.email ILIKE $${values.length})`); }
    if (query.role) { values.push(query.role); where.push(`EXISTS (SELECT 1 FROM user_roles fur JOIN roles fr ON fr.id = fur.role_id WHERE fur.user_id = u.id AND fr.name = $${values.length})`); }
    if (query.status === 'active' || query.status === 'inactive') { values.push(query.status === 'active'); where.push(`u.is_active = $${values.length}`); }
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await this.dataSource.query(`SELECT COUNT(*)::int AS count FROM users u ${predicate}`, values);
    const offset = (query.page - 1) * query.pageSize;
    const rows = await this.dataSource.query(`
      SELECT u.id, u.display_name, u.email, u.is_active, u.created_at, u.updated_at,
             COALESCE(json_agg(DISTINCT r.name) FILTER (WHERE r.name IS NOT NULL), '[]') AS roles
      FROM users u LEFT JOIN user_roles ur ON ur.user_id = u.id LEFT JOIN roles r ON r.id = ur.role_id
      ${predicate} GROUP BY u.id ORDER BY u.created_at ${query.order === 'asc' ? 'ASC' : 'DESC'} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, query.pageSize, offset]);
    return paged(rows, Number(count[0].count), query);
  }

  async user(id: string) {
    const rows = await this.dataSource.query(`SELECT u.*, COALESCE(json_agg(DISTINCT r.name) FILTER (WHERE r.name IS NOT NULL), '[]') AS roles FROM users u LEFT JOIN user_roles ur ON ur.user_id = u.id LEFT JOIN roles r ON r.id = ur.role_id WHERE u.id = $1 GROUP BY u.id`, [id]);
    if (!rows[0]) throw new NotFoundException('User not found');
    const reports = await this.dataSource.query(`SELECT report_id, species, animal_count, village, report_timestamp, latitude, longitude FROM reports WHERE owner_firebase_uid = $1 ORDER BY report_timestamp DESC LIMIT 100`, [rows[0].firebase_uid]);
    return { ...rows[0], reports };
  }

  async setUserStatus(id: string, adminUserId: string, active: boolean) {
    if (id === adminUserId && !active) throw new ConflictException('An administrator cannot deactivate their own account');
    return this.dataSource.transaction(async (manager) => {
      const rows = await manager.query(`SELECT id, is_active, firebase_uid FROM users WHERE id = $1 FOR UPDATE`, [id]);
      if (!rows[0]) throw new NotFoundException('User not found');
      if (rows[0].is_active === active) return { status: 'ok', isActive: active };
      await manager.query(`UPDATE users SET is_active = $1, updated_at = now() WHERE id = $2`, [active, id]);
      await this.audit(manager, adminUserId, active ? 'user.activated' : 'user.deactivated', id, null, { isActive: rows[0].is_active }, { isActive: active });
      return { status: 'ok', isActive: active };
    });
  }

  async reports(input: Partial<AdminPageQuery>) {
    const query = page(input);
    const where: string[] = [];
    const values: unknown[] = [];
    if (query.search) { values.push(`%${query.search}%`); where.push(`(r.report_id ILIKE $${values.length} OR r.village ILIKE $${values.length} OR COALESCE(r.farmer_name, '') ILIKE $${values.length})`); }
    if (query.species) { values.push(query.species); where.push(`r.species = $${values.length}`); }
    if (query.region) { values.push(`%${query.region}%`); where.push(`r.village ILIKE $${values.length}`); }
    if (query.from) { values.push(query.from); where.push(`r.report_timestamp >= $${values.length}`); }
    if (query.to) { values.push(query.to); where.push(`r.report_timestamp < $${values.length}`); }
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await this.dataSource.query(`SELECT COUNT(*)::int AS count FROM reports r ${predicate}`, values);
    const offset = (query.page - 1) * query.pageSize;
    const rows = await this.dataSource.query(`
      SELECT r.report_id, r.species, r.animal_count, r.village, r.symptoms, r.clinical_signs,
             r.notes, r.report_timestamp, r.farmer_name, r.farmer_phone, r.latitude, r.longitude,
             r.location_address, r.owner_firebase_uid, u.display_name AS owner_display_name, u.email AS owner_email
      FROM reports r LEFT JOIN users u ON u.firebase_uid = r.owner_firebase_uid ${predicate}
      ORDER BY r.report_timestamp ${query.order === 'asc' ? 'ASC' : 'DESC'} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, query.pageSize, offset]);
    return paged(rows, Number(count[0].count), query);
  }

  async report(id: string) {
    const rows = await this.dataSource.query(`SELECT r.*, u.display_name AS owner_display_name, u.email AS owner_email FROM reports r LEFT JOIN users u ON u.firebase_uid = r.owner_firebase_uid WHERE r.report_id = $1`, [id]);
    if (!rows[0]) throw new NotFoundException('Report not found');
    return rows[0];
  }

  async auditLogs(input: Partial<AdminPageQuery>) {
    const query = page(input);
    const values: unknown[] = [];
    const where: string[] = [];
    if (query.search) { values.push(`%${query.search}%`); where.push(`(a.action ILIKE $${values.length} OR COALESCE(admin.display_name, '') ILIKE $${values.length} OR COALESCE(target.display_name, '') ILIKE $${values.length})`); }
    const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const count = await this.dataSource.query(`SELECT COUNT(*)::int AS count FROM admin_audit_logs a LEFT JOIN users admin ON admin.id = a.admin_user_id LEFT JOIN users target ON target.id = a.target_user_id ${predicate}`, values);
    const offset = (query.page - 1) * query.pageSize;
    const rows = await this.dataSource.query(`SELECT a.id, a.action, a.previous_state, a.new_state, a.reason, a.created_at, admin.display_name AS admin_name, admin.email AS admin_email, target.display_name AS target_name, target.email AS target_email, a.target_role_request_id FROM admin_audit_logs a LEFT JOIN users admin ON admin.id = a.admin_user_id LEFT JOIN users target ON target.id = a.target_user_id ${predicate} ORDER BY a.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`, [...values, query.pageSize, offset]);
    return paged(rows, Number(count[0].count), query);
  }

  private async lockRequest(manager: EntityManager, id: string) {
    const rows = await manager.query(`SELECT rr.id, rr.user_id, rr.role_id, rr.status, r.name AS requested_role FROM role_requests rr JOIN roles r ON r.id = rr.role_id WHERE rr.id = $1 FOR UPDATE`, [id]);
    if (!rows[0]) throw new NotFoundException('Role application not found');
    if (rows[0].status !== 'pending') throw new ConflictException('This application has already been reviewed');
    return rows[0] as { id: string; user_id: string; role_id: string; status: string; requested_role: string };
  }

  private async audit(manager: EntityManager, adminUserId: string, action: string, targetUserId: string | null, requestId: string | null, previous: unknown, next: unknown, reason?: string) {
    await manager.query(`INSERT INTO admin_audit_logs (admin_user_id, action, target_user_id, target_role_request_id, previous_state, new_state, reason) VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, $7)`, [adminUserId, action, targetUserId, requestId, json(previous), json(next), reason ?? null]);
  }

  private formatApplication(row: Record<string, unknown>) {
    return {
      id: row.id,
      status: row.status,
      submittedAt: row.created_at,
      reviewedAt: row.reviewed_at,
      rejectionReason: row.review_reason,
      applicant: { id: row.user_id, displayName: row.display_name, email: row.email, mobileNumber: row.mobile_number, state: row.state, district: row.district, roleDetails: row.role_details },
      requestedRole: row.requested_role,
    };
  }
}
