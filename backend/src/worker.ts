import {
  createRemoteJWKSet,
  jwtVerify,
  type JWTPayload,
} from 'jose';
import {
  JOSEError,
  JWTClaimValidationFailed,
  JWTExpired,
  JWTInvalid,
  JWSSignatureVerificationFailed,
} from 'jose/errors';
import { Client } from 'pg';

export interface WorkerEnv {
  HYPERDRIVE: { connectionString: string };
  FIREBASE_PROJECT_ID: string;
  FIREBASE_CLIENT_EMAIL?: string;
  FIREBASE_PRIVATE_KEY?: string;
}

interface Identity extends JWTPayload {
  user_id?: string;
  email?: string;
  name?: string;
}

interface Report {
  species: string;
  animalCount: number;
  village: string;
  symptoms: string[];
  reportTimestamp: string;
  clientReportId?: string;
  farmerName?: string;
  farmerPhone?: string;
  clinicalSigns?: string[];
  notes?: string;
  location?: { latitude: number; longitude: number; address?: string; accuracyMeters?: number };
  ownerUid?: string;
}

const ADMIN_ROLES = ['administrator'];
const APPROVABLE_ROLES = ['veterinarian', 'surveillance_officer'];

function json(body: unknown, status = 200) {
  return Response.json(body, { status, headers: corsHeaders() });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  };
}

async function withDatabase<T>(env: WorkerEnv, fn: (client: Client) => Promise<T>) {
  if (!env.HYPERDRIVE?.connectionString) throw new Error('HYPERDRIVE binding is required');
  const client = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  await client.connect();
  try { return await fn(client); } finally { await client.end(); }
}

async function authenticate(request: Request, env: WorkerEnv) {
  const value = request.headers.get('Authorization');
  if (!value?.startsWith('Bearer ')) throw new Response('Missing bearer token', { status: 401, headers: corsHeaders() });
  const token = value.slice(7);
  let verified;
  try {
    const keys = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
    verified = await jwtVerify<Identity>(token, keys, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
    });
  } catch (error) {
    // Log only the JOSE error category. Never log the token or Authorization header.
    if (error instanceof JWTExpired) {
      console.warn('Firebase token rejected: expired');
      throw new Response('Firebase session expired. Sign in again.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof JWSSignatureVerificationFailed) {
      console.warn('Firebase token rejected: invalid signature');
      throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof JWTClaimValidationFailed) {
      const claim = error.claim;
      const reason = claim === 'iss' ? 'invalid issuer' : claim === 'aud' ? 'invalid audience' : `invalid ${claim} claim`;
      console.warn(`Firebase token rejected: ${reason}`);
      throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof JOSEError && error.code.startsWith('ERR_JWKS')) {
      console.error('Firebase JWKS retrieval failed:', error instanceof Error ? error.name : 'unknown_error');
      throw new Response('Authentication service temporarily unavailable.', { status: 503, headers: corsHeaders() });
    }
    if (error instanceof JWTInvalid) {
      console.warn('Firebase token rejected: malformed token');
      throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
    }
    if (error instanceof TypeError || (error instanceof Error && /fetch|network|timeout/i.test(error.message))) {
      console.error('Firebase JWKS retrieval failed:', error instanceof Error ? error.name : 'unknown_error');
      throw new Response('Authentication service temporarily unavailable.', { status: 503, headers: corsHeaders() });
    }
    console.warn('Firebase token rejected: malformed token', error instanceof Error ? error.name : 'unknown_error');
    throw new Response('Invalid Firebase ID token.', { status: 401, headers: corsHeaders() });
  }
  const uid = verified.payload.sub;
  if (!uid) throw new Response('Invalid Firebase ID token: missing Firebase UID', { status: 401, headers: corsHeaders() });
  try {
    const user = await withDatabase(env, async (client) => {
      const result = await client.query(`
        INSERT INTO users (firebase_uid, email, display_name)
        VALUES ($1, $2, $3)
        ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email, display_name = EXCLUDED.display_name, updated_at = now()
        RETURNING id, firebase_uid, email, display_name, is_active`,
        [uid, verified.payload.email ?? `${uid}@unknown.invalid`, verified.payload.name ?? null]);
      const current = result.rows[0];
      if (!current.is_active) throw new Response('Account is disabled', { status: 403 });
      const roles = await client.query(`SELECT r.name FROM roles r JOIN user_roles ur ON ur.role_id = r.id WHERE ur.user_id = $1`, [current.id]);
      console.log('Authenticated profile loaded:', { roleCount: roles.rows.length, roles: roles.rows.map((row) => row.name) });
      return { ...current, roles: roles.rows.map((row) => row.name) };
    });
    return { uid, user };
  } catch (error) {
    if (error instanceof Response) throw error;
    console.error('Authenticated user lookup failed', error instanceof Error ? error.name : 'unknown_error');
    throw new Response('Authenticated user lookup failed. Check the Worker database configuration and migrations.', { status: 500, headers: corsHeaders() });
  }
}

function validLocation(location: unknown) {
  if (!location || typeof location !== 'object') return false;
  const candidate = location as Record<string, unknown>;
  return typeof candidate.latitude === 'number' && Number.isFinite(candidate.latitude) && candidate.latitude >= -90 && candidate.latitude <= 90
    && typeof candidate.longitude === 'number' && Number.isFinite(candidate.longitude) && candidate.longitude >= -180 && candidate.longitude <= 180;
}

function parseProfile(body: unknown) {
  if (!body || typeof body !== 'object') return 'Profile must be an object.';
  const value = body as Record<string, unknown>;
  if (typeof value.displayName !== 'string' || value.displayName.trim().length === 0 || value.displayName.length > 255) return 'Full name is required.';
  if (value.mobileNumber !== null && value.mobileNumber !== undefined && (typeof value.mobileNumber !== 'string' || !/^\+91[6-9][0-9]{9}$/.test(value.mobileNumber))) return 'Enter a valid Indian mobile number.';
  if (value.roleDetails !== null && value.roleDetails !== undefined && (!value.roleDetails || typeof value.roleDetails !== 'object' || Array.isArray(value.roleDetails))) return 'Role details must be an object.';
  const location = value.location;
  if (location === null || location === undefined) {
    return { displayName: value.displayName.trim(), mobileNumber: value.mobileNumber ?? null, location: null, roleDetails: value.roleDetails ?? null };
  }
  if (!validLocation(location)) return 'Location coordinates are invalid.';
  const address = location as Record<string, unknown>;
  for (const [key, max] of [['state', 255], ['district', 255], ['locality', 255], ['postalCode', 32], ['formattedAddress', 500]] as const) {
    if (address[key] !== undefined && address[key] !== null && (typeof address[key] !== 'string' || address[key].length > max)) return `Location field ${key} is invalid.`;
  }
  return { displayName: value.displayName.trim(), mobileNumber: value.mobileNumber ?? null, location: address, roleDetails: value.roleDetails ?? null };
}

function requireAdministrator(auth: { user: { roles: string[] } }) {
  if (!auth.user.roles.some((role) => ADMIN_ROLES.includes(role))) {
    throw new Response('Administrator access is required', { status: 403, headers: corsHeaders() });
  }
}

function pageParams(url: URL) {
  const page = Number(url.searchParams.get('page') ?? 1);
  const pageSize = Number(url.searchParams.get('pageSize') ?? 20);
  if (!Number.isInteger(page) || page < 1 || !Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) {
    throw new Response('Invalid pagination parameters', { status: 400, headers: corsHeaders() });
  }
  return { page, pageSize, offset: (page - 1) * pageSize };
}

function safeOrder(value: string | null) {
  return value === 'asc' ? 'ASC' : 'DESC';
}

async function adminOverview(env: WorkerEnv) {
  return withDatabase(env, async (client) => {
    const result = await client.query(`
      WITH role_counts AS (SELECT r.name AS role, COUNT(DISTINCT ur.user_id)::int AS count FROM roles r LEFT JOIN user_roles ur ON ur.role_id = r.id GROUP BY r.name),
      user_days AS (SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day, COUNT(*)::int AS count FROM users WHERE created_at >= now() - interval '30 days' GROUP BY 1 ORDER BY 1),
      report_days AS (SELECT to_char(date_trunc('day', report_timestamp), 'YYYY-MM-DD') AS day, COUNT(*)::int AS count FROM reports WHERE report_timestamp >= now() - interval '30 days' GROUP BY 1 ORDER BY 1),
      species_counts AS (SELECT species, COUNT(*)::int AS count FROM reports GROUP BY species ORDER BY count DESC LIMIT 10),
      region_counts AS (SELECT village AS region, COUNT(*)::int AS count FROM reports GROUP BY village ORDER BY count DESC LIMIT 10),
      recent_activity AS (SELECT report_id AS id, 'report.submitted' AS action, report_timestamp AS created_at, village AS target FROM reports ORDER BY report_timestamp DESC LIMIT 8)
      SELECT (SELECT COUNT(*)::int FROM users) AS total_users,
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
        (SELECT COALESCE(json_agg(pending_preview ORDER BY created_at DESC), '[]'::json) FROM (SELECT rr.id, u.display_name, u.email, r.name AS requested_role, rr.created_at FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE rr.status = 'pending' ORDER BY rr.created_at DESC LIMIT 5) pending_preview) AS pending_preview`);
    return result.rows[0];
  });
}

async function adminApplications(env: WorkerEnv, url: URL) {
  const { page, pageSize, offset } = pageParams(url);
  const search = url.searchParams.get('search')?.trim() || null;
  const role = url.searchParams.get('role')?.trim() || null;
  const values: unknown[] = [];
  const where = ["rr.status = 'pending'", "r.name IN ('veterinarian', 'surveillance_officer')"];
  if (search) { values.push(`%${search}%`); where.push(`(COALESCE(u.display_name, '') ILIKE $${values.length} OR u.email ILIKE $${values.length})`); }
  if (role && APPROVABLE_ROLES.includes(role)) { values.push(role); where.push(`r.name = $${values.length}`); }
  const predicate = where.join(' AND ');
  return withDatabase(env, async (client) => {
    const count = await client.query(`SELECT COUNT(*)::int AS count FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE ${predicate}`, values);
    const rows = await client.query(`SELECT rr.id, rr.status, rr.created_at, rr.reviewed_at, rr.review_reason, u.id AS user_id, u.display_name, u.email, u.mobile_number, u.role_details, u.state, u.district, r.name AS requested_role FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE ${predicate} ORDER BY rr.created_at ${safeOrder(url.searchParams.get('order'))} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`, [...values, pageSize, offset]);
    return { items: rows.rows.map((row) => ({ id: row.id, status: row.status, submittedAt: row.created_at, reviewedAt: row.reviewed_at, rejectionReason: row.review_reason, requestedRole: row.requested_role, applicant: { id: row.user_id, displayName: row.display_name, email: row.email, mobileNumber: row.mobile_number, state: row.state, district: row.district, roleDetails: row.role_details } })), page, pageSize, total: count.rows[0].count, totalPages: Math.max(1, Math.ceil(Number(count.rows[0].count) / pageSize)) };
  });
}

async function adminApplication(env: WorkerEnv, id: string) {
  return withDatabase(env, async (client) => {
    const result = await client.query(`SELECT rr.id, rr.status, rr.created_at, rr.reviewed_at, rr.review_reason, u.id AS user_id, u.firebase_uid, u.display_name, u.email, u.mobile_number, u.role_details, u.state, u.district, u.locality, u.postal_code, u.formatted_address, r.name AS requested_role FROM role_requests rr JOIN users u ON u.id = rr.user_id JOIN roles r ON r.id = rr.role_id WHERE rr.id = $1`, [id]);
    if (!result.rowCount) throw new Response('Role application not found', { status: 404, headers: corsHeaders() });
    const row = result.rows[0];
    return { id: row.id, status: row.status, submittedAt: row.created_at, reviewedAt: row.reviewed_at, rejectionReason: row.review_reason, requestedRole: row.requested_role, applicant: { id: row.user_id, firebaseUid: row.firebase_uid, displayName: row.display_name, email: row.email, mobileNumber: row.mobile_number, state: row.state, district: row.district, locality: row.locality, postalCode: row.postal_code, formattedAddress: row.formatted_address, roleDetails: row.role_details } };
  });
}

async function reviewApplication(env: WorkerEnv, id: string, adminUserId: string, action: 'approve' | 'reject', reason?: string) {
  if (action === 'reject' && (!reason || reason.trim().length < 3 || reason.trim().length > 2000)) throw new Response('A rejection reason between 3 and 2000 characters is required', { status: 400, headers: corsHeaders() });
  return withDatabase(env, async (client) => {
    await client.query('BEGIN');
    try {
      const result = await client.query(`SELECT rr.id, rr.user_id, rr.role_id, rr.status, r.name AS requested_role FROM role_requests rr JOIN roles r ON r.id = rr.role_id WHERE rr.id = $1 FOR UPDATE`, [id]);
      if (!result.rowCount) throw new Response('Role application not found', { status: 404, headers: corsHeaders() });
      const row = result.rows[0];
      if (row.user_id === adminUserId) throw new Response('An administrator cannot review their own application', { status: 409, headers: corsHeaders() });
      if (row.status !== 'pending') throw new Response('This application has already been reviewed', { status: 409, headers: corsHeaders() });
      if (!APPROVABLE_ROLES.includes(row.requested_role)) throw new Response('This role cannot be reviewed through the application workflow', { status: 400, headers: corsHeaders() });
      const status = action === 'approve' ? 'approved' : 'rejected';
      if (action === 'approve') await client.query(`INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [row.user_id, row.role_id]);
      await client.query(`UPDATE role_requests SET status = $1, reviewer_id = $2, reviewed_at = now(), review_reason = $3 WHERE id = $4`, [status, adminUserId, action === 'reject' ? reason!.trim() : null, id]);
      await client.query(`INSERT INTO admin_audit_logs (admin_user_id, action, target_user_id, target_role_request_id, previous_state, new_state, reason) VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, $7)`, [adminUserId, `application.${action === 'approve' ? 'approved' : 'rejected'}`, row.user_id, id, JSON.stringify({ status: 'pending' }), JSON.stringify({ status, role: row.requested_role }), action === 'reject' ? reason!.trim() : null]);
      await client.query('COMMIT');
      return { status, applicationId: id, ...(action === 'approve' ? { role: row.requested_role } : {}) };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  });
}

async function adminUsers(env: WorkerEnv, url: URL) {
  const { page, pageSize, offset } = pageParams(url);
  const search = url.searchParams.get('search')?.trim() || null;
  const role = url.searchParams.get('role')?.trim() || null;
  const status = url.searchParams.get('status');
  const values: unknown[] = [];
  const where: string[] = [];
  if (search) { values.push(`%${search}%`); where.push(`(COALESCE(u.display_name, '') ILIKE $${values.length} OR u.email ILIKE $${values.length})`); }
  if (role) { values.push(role); where.push(`EXISTS (SELECT 1 FROM user_roles fur JOIN roles fr ON fr.id = fur.role_id WHERE fur.user_id = u.id AND fr.name = $${values.length})`); }
  if (status === 'active' || status === 'inactive') { values.push(status === 'active'); where.push(`u.is_active = $${values.length}`); }
  const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
  return withDatabase(env, async (client) => {
    const count = await client.query(`SELECT COUNT(*)::int AS count FROM users u ${predicate}`, values);
    const rows = await client.query(`SELECT u.id, u.display_name, u.email, u.is_active, u.created_at, u.updated_at, COALESCE(json_agg(DISTINCT r.name) FILTER (WHERE r.name IS NOT NULL), '[]') AS roles FROM users u LEFT JOIN user_roles ur ON ur.user_id = u.id LEFT JOIN roles r ON r.id = ur.role_id ${predicate} GROUP BY u.id ORDER BY u.created_at ${safeOrder(url.searchParams.get('order'))} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`, [...values, pageSize, offset]);
    return { items: rows.rows, page, pageSize, total: count.rows[0].count, totalPages: Math.max(1, Math.ceil(Number(count.rows[0].count) / pageSize)) };
  });
}

async function adminUser(env: WorkerEnv, id: string) {
  return withDatabase(env, async (client) => {
    const result = await client.query(`SELECT u.id, u.firebase_uid, u.email, u.display_name, u.mobile_number, u.state, u.district, u.locality, u.postal_code, u.formatted_address, u.role_details, u.is_active, u.created_at, u.updated_at, COALESCE(json_agg(DISTINCT r.name) FILTER (WHERE r.name IS NOT NULL), '[]') AS roles FROM users u LEFT JOIN user_roles ur ON ur.user_id = u.id LEFT JOIN roles r ON r.id = ur.role_id WHERE u.id = $1 GROUP BY u.id`, [id]);
    if (!result.rowCount) throw new Response('User not found', { status: 404, headers: corsHeaders() });
    const reports = await client.query(`SELECT report_id, species, animal_count, village, report_timestamp, latitude, longitude FROM reports WHERE owner_firebase_uid = $1 ORDER BY report_timestamp DESC LIMIT 100`, [result.rows[0].firebase_uid]);
    return { ...result.rows[0], reports: reports.rows };
  });
}

async function adminSetUserStatus(env: WorkerEnv, id: string, adminUserId: string, active: boolean) {
  if (id === adminUserId && !active) throw new Response('An administrator cannot deactivate their own account', { status: 409, headers: corsHeaders() });
  return withDatabase(env, async (client) => {
    await client.query('BEGIN');
    try {
      const result = await client.query(`SELECT id, is_active FROM users WHERE id = $1 FOR UPDATE`, [id]);
      if (!result.rowCount) throw new Response('User not found', { status: 404, headers: corsHeaders() });
      if (result.rows[0].is_active !== active) {
        await client.query(`UPDATE users SET is_active = $1, updated_at = now() WHERE id = $2`, [active, id]);
        await client.query(`INSERT INTO admin_audit_logs (admin_user_id, action, target_user_id, previous_state, new_state) VALUES ($1, $2, $3, $4::jsonb, $5::jsonb)`, [adminUserId, active ? 'user.activated' : 'user.deactivated', id, JSON.stringify({ isActive: result.rows[0].is_active }), JSON.stringify({ isActive: active })]);
      }
      await client.query('COMMIT');
      return { status: 'ok', isActive: active };
    } catch (error) { await client.query('ROLLBACK'); throw error; }
  });
}

async function adminReports(env: WorkerEnv, url: URL) {
  const { page, pageSize, offset } = pageParams(url);
  const values: unknown[] = [];
  const where: string[] = [];
  const search = url.searchParams.get('search')?.trim();
  if (search) { values.push(`%${search}%`); where.push(`(r.report_id ILIKE $${values.length} OR r.village ILIKE $${values.length} OR COALESCE(r.farmer_name, '') ILIKE $${values.length})`); }
  const species = url.searchParams.get('species')?.trim();
  if (species) { values.push(species); where.push(`r.species = $${values.length}`); }
  const region = url.searchParams.get('region')?.trim();
  if (region) { values.push(`%${region}%`); where.push(`r.village ILIKE $${values.length}`); }
  const from = url.searchParams.get('from');
  if (from) { values.push(from); where.push(`r.report_timestamp >= $${values.length}`); }
  const to = url.searchParams.get('to');
  if (to) { values.push(to); where.push(`r.report_timestamp < $${values.length}`); }
  const predicate = where.length ? `WHERE ${where.join(' AND ')}` : '';
  return withDatabase(env, async (client) => {
    const count = await client.query(`SELECT COUNT(*)::int AS count FROM reports r ${predicate}`, values);
    const rows = await client.query(`SELECT r.report_id, r.species, r.animal_count, r.village, r.symptoms, r.clinical_signs, r.notes, r.report_timestamp, r.farmer_name, r.farmer_phone, r.latitude, r.longitude, r.location_address, r.owner_firebase_uid, u.display_name AS owner_display_name, u.email AS owner_email FROM reports r LEFT JOIN users u ON u.firebase_uid = r.owner_firebase_uid ${predicate} ORDER BY r.report_timestamp ${safeOrder(url.searchParams.get('order'))} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`, [...values, pageSize, offset]);
    return { items: rows.rows, page, pageSize, total: count.rows[0].count, totalPages: Math.max(1, Math.ceil(Number(count.rows[0].count) / pageSize)) };
  });
}

async function adminAuditLogs(env: WorkerEnv, url: URL) {
  const { page, pageSize, offset } = pageParams(url);
  const values: unknown[] = [];
  const search = url.searchParams.get('search')?.trim();
  const where = search ? (() => { values.push(`%${search}%`); return `WHERE (a.action ILIKE $1 OR COALESCE(admin.display_name, '') ILIKE $1 OR COALESCE(target.display_name, '') ILIKE $1)`; })() : '';
  return withDatabase(env, async (client) => {
    const count = await client.query(`SELECT COUNT(*)::int AS count FROM admin_audit_logs a LEFT JOIN users admin ON admin.id = a.admin_user_id LEFT JOIN users target ON target.id = a.target_user_id ${where}`, values);
    const rows = await client.query(`SELECT a.id, a.action, a.previous_state, a.new_state, a.reason, a.created_at, admin.display_name AS admin_name, admin.email AS admin_email, target.display_name AS target_name, target.email AS target_email, a.target_role_request_id FROM admin_audit_logs a LEFT JOIN users admin ON admin.id = a.admin_user_id LEFT JOIN users target ON target.id = a.target_user_id ${where} ORDER BY a.created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`, [...values, pageSize, offset]);
    return { items: rows.rows, page, pageSize, total: count.rows[0].count, totalPages: Math.max(1, Math.ceil(Number(count.rows[0].count) / pageSize)) };
  });
}

export default {
  async fetch(request: Request, env: WorkerEnv): Promise<Response> {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders() });
    const url = new URL(request.url);
      if (url.pathname === '/api/v1/' || url.pathname === '/api/v1') return json('Hello World!');
    try {
      if (url.pathname === '/api/v1/admin/overview' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', ...(await adminOverview(env)) });
      }
      if (url.pathname === '/api/v1/admin/applications' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', ...(await adminApplications(env, url)) });
      }
      const applicationMatch = url.pathname.match(/^\/api\/v1\/admin\/applications\/([^/]+)$/);
      if (applicationMatch && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', application: await adminApplication(env, applicationMatch[1]) });
      }
      const approveMatch = url.pathname.match(/^\/api\/v1\/admin\/applications\/([^/]+)\/approve$/);
      if (approveMatch && request.method === 'POST') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', result: await reviewApplication(env, approveMatch[1], auth.user.id, 'approve') });
      }
      const rejectMatch = url.pathname.match(/^\/api\/v1\/admin\/applications\/([^/]+)\/reject$/);
      if (rejectMatch && request.method === 'POST') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        let body: { reason?: unknown };
        try { body = await request.json() as { reason?: unknown }; } catch { return json({ status: 'rejected', message: 'Request body must be valid JSON' }, 400); }
        return json({ status: 'ok', result: await reviewApplication(env, rejectMatch[1], auth.user.id, 'reject', typeof body.reason === 'string' ? body.reason : undefined) });
      }
      if (url.pathname === '/api/v1/admin/users' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', ...(await adminUsers(env, url)) });
      }
      const userMatch = url.pathname.match(/^\/api\/v1\/admin\/users\/([^/]+)$/);
      if (userMatch && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', user: await adminUser(env, userMatch[1]) });
      }
      const userStatusMatch = url.pathname.match(/^\/api\/v1\/admin\/users\/([^/]+)\/status$/);
      if (userStatusMatch && request.method === 'PATCH') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        let body: { active?: unknown };
        try { body = await request.json() as { active?: unknown }; } catch { return json({ status: 'rejected', message: 'Request body must be valid JSON' }, 400); }
        if (typeof body.active !== 'boolean') return json({ status: 'rejected', message: 'active must be a boolean' }, 400);
        return json({ status: 'ok', result: await adminSetUserStatus(env, userStatusMatch[1], auth.user.id, body.active) });
      }
      if (url.pathname === '/api/v1/admin/reports' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', ...(await adminReports(env, url)) });
      }
      const reportMatch = url.pathname.match(/^\/api\/v1\/admin\/reports\/([^/]+)$/);
      if (reportMatch && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        const report = await withDatabase(env, async (client) => {
          const result = await client.query(`SELECT r.*, u.display_name AS owner_display_name, u.email AS owner_email FROM reports r LEFT JOIN users u ON u.firebase_uid = r.owner_firebase_uid WHERE r.report_id = $1`, [reportMatch[1]]);
          if (!result.rowCount) throw new Response('Report not found', { status: 404, headers: corsHeaders() });
          return result.rows[0];
        });
        return json({ status: 'ok', report });
      }
      if (url.pathname === '/api/v1/admin/audit-logs' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        requireAdministrator(auth);
        return json({ status: 'ok', ...(await adminAuditLogs(env, url)) });
      }
      if (url.pathname === '/api/v1/reports' && request.method === 'POST') {
        const auth = await authenticate(request, env);
        let report: Partial<Report>;
        try {
          report = await request.json() as Partial<Report>;
        } catch {
          return json({ status: 'rejected', message: 'Request body must be valid JSON' }, 400);
        }
        const missing = [
          ['species', typeof report.species === 'string' && report.species.trim().length > 0],
          ['animalCount', typeof report.animalCount === 'number' && Number.isInteger(report.animalCount) && report.animalCount > 0],
          ['village', typeof report.village === 'string' && report.village.trim().length > 0],
          ['symptoms', Array.isArray(report.symptoms) && report.symptoms.length > 0],
          ['reportTimestamp', typeof report.reportTimestamp === 'string' && !Number.isNaN(Date.parse(report.reportTimestamp))],
          ['location', report.location === undefined || validLocation(report.location)],
        ].filter(([, valid]) => !valid).map(([field]) => field);
        if (missing.length) return json({ status: 'rejected', message: 'Invalid livestock health report', missing }, 400);
        const complete = { ...report, ownerUid: auth.uid } as Report;
        const persisted = await withDatabase(env, async (client) => {
          const result = await client.query(`
            INSERT INTO reports (
              report_id, owner_firebase_uid, client_report_id, species, animal_count,
              village, symptoms, report_timestamp, farmer_name, farmer_phone,
              clinical_signs, notes, latitude, longitude, location_address, accuracy_meters
            ) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10, $11::jsonb, $12, $13, $14, $15, $16)
            ON CONFLICT (owner_firebase_uid, client_report_id) DO NOTHING
            RETURNING report_id`,
            [
              `report_${crypto.randomUUID()}`, auth.uid, complete.clientReportId ?? null,
              complete.species, complete.animalCount, complete.village, JSON.stringify(complete.symptoms),
              complete.reportTimestamp, complete.farmerName ?? null, complete.farmerPhone ?? null,
              JSON.stringify(complete.clinicalSigns ?? []), complete.notes ?? null,
              complete.location?.latitude ?? null, complete.location?.longitude ?? null,
              complete.location?.address ?? null, complete.location?.accuracyMeters ?? null,
            ],
          );
          if (result.rowCount) return { reportId: result.rows[0].report_id, idempotent: false };
          const existing = await client.query(`SELECT report_id FROM reports WHERE owner_firebase_uid = $1 AND client_report_id = $2`, [auth.uid, complete.clientReportId]);
          return { reportId: existing.rows[0].report_id, idempotent: true };
        });
        return json({ reportId: persisted.reportId, status: 'submitted', ...(persisted.idempotent ? { idempotent: true } : {}) }, persisted.idempotent ? 200 : 201);
      }
      if (url.pathname === '/api/v1/me' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        const pending = await withDatabase(env, (client) => client.query(`SELECT r.name AS role, rr.status FROM role_requests rr JOIN roles r ON r.id = rr.role_id WHERE rr.user_id = $1 AND rr.status = 'pending' ORDER BY rr.created_at DESC`, [auth.user.id]));
        return json({ status: 'ok', user: { firebaseUid: auth.uid, email: auth.user.email, displayName: auth.user.display_name, roles: auth.user.roles, pendingRoleRequests: pending.rows.map((row) => row.role) } });
      }
      if (url.pathname === '/api/v1/me/profile' && request.method === 'PATCH') {
        const auth = await authenticate(request, env);
        let body: unknown;
        try {
          body = await request.json();
        } catch {
          return json({ status: 'rejected', message: 'Request body must be valid JSON' }, 400);
        }
        const profile = parseProfile(body);
        if (typeof profile === 'string') return json({ status: 'rejected', message: profile }, 400);
        await withDatabase(env, (client) => client.query(`
          UPDATE users
          SET display_name = $1, mobile_number = $2, latitude = $3, longitude = $4,
              state = $5, district = $6, locality = $7, postal_code = $8,
              formatted_address = $9, role_details = $10::jsonb, updated_at = now()
          WHERE id = $11`, [
            profile.displayName,
            profile.mobileNumber,
            profile.location?.latitude ?? null,
            profile.location?.longitude ?? null,
            profile.location?.state ?? null,
            profile.location?.district ?? null,
            profile.location?.locality ?? null,
            profile.location?.postalCode ?? null,
            profile.location?.formattedAddress ?? null,
            JSON.stringify(profile.roleDetails),
            auth.user.id,
          ]));
        return json({ status: 'ok' });
      }
      if (url.pathname === '/api/v1/me/role-requests' && request.method === 'POST') {
        const auth = await authenticate(request, env);
        const body = await request.json() as { role?: unknown };
        if (!['farmer', 'veterinarian', 'surveillance_officer'].includes(body.role as string)) return json({ status: 'rejected', message: 'Invalid role selection.' }, 400);
        const role = body.role as string;
        const result = await withDatabase(env, async (client) => {
          const existing = await client.query(`SELECT 1 FROM user_roles ur JOIN roles r ON r.id = ur.role_id WHERE ur.user_id = $1 AND r.name = $2`, [auth.user.id, role]);
          if (existing.rowCount) return 'assigned';
          if (role === 'farmer') {
            await client.query(`INSERT INTO user_roles (user_id, role_id) SELECT $1, id FROM roles WHERE name = $2 ON CONFLICT DO NOTHING`, [auth.user.id, role]);
            return 'assigned';
          }
          await client.query(`INSERT INTO role_requests (user_id, role_id) SELECT $1, id FROM roles WHERE name = $2 ON CONFLICT (user_id, role_id, status) DO NOTHING`, [auth.user.id, role]);
          return 'pending';
        });
        return json({ status: 'ok', role, assignment: result });
      }
      if (url.pathname === '/api/v1/reports/mine' && request.method === 'GET') {
        const auth = await authenticate(request, env);
        const result = await withDatabase(env, (client) => client.query(`
          SELECT report_id, species, animal_count, village, symptoms, report_timestamp,
                 client_report_id, farmer_name, farmer_phone, clinical_signs, notes,
                 latitude, longitude, location_address, accuracy_meters
          FROM reports WHERE owner_firebase_uid = $1 ORDER BY created_at DESC`, [auth.uid]));
        return json({ status: 'ok', reports: result.rows.map((row) => ({
          reportId: row.report_id,
          species: row.species,
          animalCount: row.animal_count,
          village: row.village,
          symptoms: row.symptoms,
          reportTimestamp: new Date(row.report_timestamp).toISOString(),
          clientReportId: row.client_report_id ?? undefined,
          farmerName: row.farmer_name ?? undefined,
          farmerPhone: row.farmer_phone ?? undefined,
          clinicalSigns: row.clinical_signs,
          notes: row.notes ?? undefined,
          ...(row.latitude === null ? {} : { location: { latitude: row.latitude, longitude: row.longitude, ...(row.location_address === null ? {} : { address: row.location_address }), ...(row.accuracy_meters === null ? {} : { accuracyMeters: row.accuracy_meters }) } }),
          ownerUid: auth.uid,
        })) });
      }
      return json({ status: 'not_found' }, 404);
    } catch (error) {
      if (error instanceof Response) return error;
      console.error('Worker request failed', error);
      return json({ status: 'error', message: 'Internal server error' }, 500);
    }
  },
};
